import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';

import 'iap_payment_service.dart';

// Ajuste a URL do backend via --dart-define API_BASE_URL=...
const String backendBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://your-backend.example');

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal() {
    // Inicializa automaticamente ao criar a instância singleton
    init();
  }

  final IAPService _iap = IAPService();
  StreamSubscription<List<PurchaseDetails>>? _sub;

  // Product IDs (SKUs) — ajuste conforme seus SKUs reais
  final Map<String, Map<String, String>> productIds = {
    'enterprise_trimestral': {
      'android': 'com.safeplate.enterprise.trimestral',
      'ios': 'br.com.pratoseguro.enterprise.trimestral',
    },
    'enterprise_anual': {
      'android': 'com.safeplate.enterprise.anual',
      'ios': 'br.com.pratoseguro.enterprise.anual',
    },
    'boost': {
      'android': 'com.safeplate.boost',
      'ios': 'br.com.pratoseguro.boost',
    },
  };

  // Você pode definir explicitamente o userId que será enviado ao backend.
  String? _currentUserId;

  /// Defina manualmente o userId (por ex., uid do Firestore).
  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  void clearCurrentUserId() {
    _currentUserId = null;
  }

  /// Inicializa o listener do purchaseStream (idempotente).
  void init() {
    if (_sub == null) {
      _sub = _iap.purchaseStream.listen((purchases) {
        for (final p in purchases) {
          _handlePurchase(p);
        }
      }, onError: (err) {
        debugPrint('IAP purchase stream error: $err');
      });
    }
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  // Retorna ProductDetails para um key lógico
  Future<List<ProductDetails>> getProductsFor(String logicalKey) async {
    final platformKey = Platform.isAndroid ? 'android' : 'ios';
    final sku = productIds[logicalKey]?[platformKey];
    if (sku == null) {
      debugPrint('❌ getProductsFor: SKU não encontrado para $logicalKey');
      return [];
    }
    try {
      final response = await _iap.queryProducts({sku});
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('❌ getProductsFor: Produtos não encontrados: ${response.notFoundIDs}');
        debugPrint('   Verifique se o SKU "$sku" está configurado na loja (Google Play/App Store)');
      }
      if (response.productDetails.isEmpty) {
        debugPrint('⚠️ getProductsFor: productDetails vazio para $sku');
      }
      return response.productDetails.toList();
    } catch (e) {
      debugPrint('❌ getProductsFor erro: $e');
      return [];
    }
  }

  // Inicia compra (busca produto e realiza purchase)
  Future<void> buyLogicalProduct(String logicalKey) async {
    final products = await getProductsFor(logicalKey);
    if (products.isEmpty) {
      debugPrint('❌ buyLogicalProduct: Nenhum produto disponível para $logicalKey');
      throw Exception('Produto não disponível na loja');
    }
    final product = products.first;
    final isConsumable = logicalKey == 'boost';
    debugPrint('🛒 Iniciando compra de $logicalKey (consumable: $isConsumable)');
    await _iap.buyProduct(product, consumable: isConsumable);
  }

  /// Compra diretamente por productId (SKU). Retorna true se disparou a compra com sucesso.
  /// Compatível com chamadas existentes que usam productId (ex.: premium_screen).
  Future<bool> buyProductByLogicalKey(String productId, {String? userId}) async {
    try {
      if (userId != null && userId.isNotEmpty) {
        setCurrentUserId(userId);
        debugPrint('🔐 PaymentService: userId definido para compra');
      }
      
      // Validar disponibilidade da loja
      final available = await _iap.isAvailable();
      if (!available) {
        debugPrint('❌ buyProductByLogicalKey: Loja de apps não está disponível');
        return false;
      }
      
      final response = await _iap.queryProducts({productId});
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('❌ buyProductByLogicalKey: produto não encontrado: ${response.notFoundIDs}');
        debugPrint('   Verifique se "$productId" está configurado na loja (Google Play/App Store)');
        return false;
      }
      if (response.productDetails.isEmpty) {
        debugPrint('❌ buyProductByLogicalKey: productDetails vazio para $productId');
        return false;
      }
      
      final product = response.productDetails.first;
      final isConsumable = productId == (productIds['boost']?[(Platform.isAndroid ? 'android' : 'ios')] ?? '');
      
      debugPrint('🛒 Iniciando compra: $productId (consumable: $isConsumable)');
      await _iap.buyProduct(product, consumable: isConsumable);
      return true;
    } catch (e) {
      debugPrint('❌ buyProductByLogicalKey erro: $e');
      return false;
    }
  }

  // Valida com o backend e inclui Authorization: Bearer <FirebaseIdToken> se disponível.
  Future<http.Response> validateWithBackend({
    required String platform,
    required String productId,
    String? purchaseToken,
    String? receipt,
    required String userId,
    String? packageName,
  }) async {
    final url = Uri.parse('$backendBaseUrl/api/payments/validate');
    
    if (backendBaseUrl.contains('example') || backendBaseUrl.contains('your-backend')) {
      debugPrint('⚠️  validateWithBackend: Backend URL é placeholder: $backendBaseUrl');
      debugPrint('   Defina via: flutter run --dart-define=API_BASE_URL=https://seu-backend');
      return http.Response('Backend URL not configured', 400);
    }
    
    final body = {
      'platform': platform,
      'productId': productId,
      'purchaseToken': purchaseToken,
      'receipt': receipt,
      'userId': userId,
      'packageName': packageName,
    };

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    String? idToken;
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        idToken = await firebaseUser.getIdToken();
        if ((idToken ?? '').isNotEmpty) {
          headers['Authorization'] = 'Bearer $idToken';
          debugPrint('🔐 validateWithBackend: Firebase ID token adicionado ao header');
        } else {
          debugPrint('⚠️  validateWithBackend: Firebase ID token vazio');
        }
      } else {
        debugPrint('⚠️  validateWithBackend: Usuário Firebase não autenticado');
      }
    } catch (e) {
      debugPrint('⚠️  validateWithBackend: Falha ao obter Firebase ID token: $e');
      // Continua sem Authorization header se não puder obter token
    }

    debugPrint('📤 validateWithBackend: POST $url');
    debugPrint('   platform: $platform | productId: $productId | userId: $userId');
    
    try {
      final response = await http.post(url, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));
      
      debugPrint('📥 validateWithBackend: Response ${response.statusCode}');
      if (response.statusCode != 200) {
        debugPrint('❌ Backend retornou erro: ${response.body}');
      }
      return response;
    } catch (e) {
      debugPrint('❌ validateWithBackend erro na requisição: $e');
      return http.Response('Network error: $e', 503);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    debugPrint('🔔 Handling purchase: ${purchase.productID} | status: ${purchase.status}');
    
    if (purchase.status == PurchaseStatus.pending) {
      debugPrint('⏳ Purchase pending: ${purchase.productID}');
      return;
    }
    
    if (purchase.status == PurchaseStatus.error) {
      debugPrint('❌ Purchase error: ${purchase.error}');
      return;
    }

    final verificationData = purchase.verificationData;
    final serverData = verificationData.serverVerificationData;
    final platform = Platform.isAndroid ? 'android' : 'ios';
    final productId = purchase.productID;

    String? purchaseToken;
    String? receipt;
    if (platform == 'android') {
      purchaseToken = serverData;
    } else {
      receipt = serverData;
    }

    try {
      final userId = await _getCurrentUserId();
      if (userId == null || userId.isEmpty) {
        debugPrint('❌ _handlePurchase: No user id. Defina via PaymentService.setCurrentUserId() ou FirebaseAuth');
        return;
      }

      debugPrint('🔍 Validando compra com backend: userId=$userId, productId=$productId');
      
      final resp = await validateWithBackend(
        platform: platform,
        productId: productId,
        purchaseToken: purchaseToken,
        receipt: receipt,
        userId: userId,
        packageName: Platform.isAndroid ? (const String.fromEnvironment('GOOGLE_PACKAGE_NAME', defaultValue: 'com.safeplate.cliente')) : null,
      );

      if (resp.statusCode == 200) {
        debugPrint('✅ Backend validou compra com sucesso: ${purchase.productID}');
        debugPrint('   Response: ${resp.body}');
        // Complete the purchase so the store considers it finished
        await InAppPurchase.instance.completePurchase(purchase);
        debugPrint('✅ Compra completada: ${purchase.productID}');
      } else {
        debugPrint('❌ Backend rejeitou validação: ${resp.statusCode}');
        debugPrint('   Response: ${resp.body}');
      }
    } catch (e) {
      debugPrint('❌ Erro ao processar compra: $e');
    }
  }

  // Obtém o userId: usa valor setado manualmente (se houver) ou FirebaseAuth.currentUser.uid
  Future<String?> _getCurrentUserId() async {
    if (_currentUserId != null && _currentUserId!.isNotEmpty) return _currentUserId;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) return user.uid;
    } catch (e) {
      debugPrint('FirebaseAuth currentUser check failed: $e');
    }
    return null;
  }
}