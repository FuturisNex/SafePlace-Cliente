import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class IapService {
  // Permitir compatibilidade com chamadas antigas: IapService()
  factory IapService() => instance;

  IapService._internal();

  static final IapService instance = IapService._internal();

  static const String DEFAULT_BACKEND_URL = 'http://10.0.2.2:3000';

  // Constantes compatíveis com chamadas legadas no app (IDs reais devem ser preenchidos)
  static const String productBusinessBasicId = '';
  static const String productBusinessIntermediateId = '';
  static const String productBusinessPremiumId = '';

  // Boost / consumable example (preencha com o seu productId real)
  static const String productBoost50Id = '';

  // Expor getters estáticos com os nomes usados pelo app (IapService.productBusinessBasic)
  static String get productBusinessBasic => productBusinessBasicId;
  static String get productBusinessIntermediate => productBusinessIntermediateId;
  static String get productBusinessPremium => productBusinessPremiumId;
  static String get productBoost50 => productBoost50Id;

  // Se quiser acessar via instância, use IapService().productBusinessBasicId (ou a constante Id).
  // Mantemos as constantes Id públicas para referência de instância se necessário.

  final InAppPurchase _iap = InAppPurchase.instance;
  final Dio _dio = Dio();
  StreamSubscription<List<PurchaseDetails>>? _sub;

  List<ProductDetails> productDetails = [];
  bool available = false;

  String backendBaseUrl = DEFAULT_BACKEND_URL;

  // Mantemos uma fila de requisições pendentes por productId.
  final Map<String, List<_PendingPurchaseMeta>> _pendingByProduct = {};

  /// Método compatível com código antigo que chamava IapService().initialize()
  Future<void> initialize({List<String>? productIds, String? backendBaseUrl}) {
    return init(productIds: productIds ?? [], backendBaseUrl: backendBaseUrl);
  }

  Future<void> init({
    required List<String> productIds,
    String? backendBaseUrl,
  }) async {
    if (backendBaseUrl != null) {
      this.backendBaseUrl = backendBaseUrl;
    }

    available = await _iap.isAvailable();
    if (!available) return;

    final ProductDetailsResponse response = await _iap.queryProductDetails(productIds.toSet());
    if (response.error != null) {
      productDetails = [];
    } else {
      productDetails = response.productDetails;
    }

    _sub?.cancel();
    _sub = _iap.purchaseStream.listen(_onPurchaseUpdate, onDone: () {
      _sub?.cancel();
    }, onError: (err) {
      // tratar erro se necessário
    });
  }

  ProductDetails? findProduct(String productId) {
    try {
      return productDetails.firstWhere((p) => p.id == productId);
    } catch (_) {
      return null;
    }
  }

  /// Compatibilidade: método usado por código legado
  /// establishmentId será enviado ao backend como extraData durante a validação.
  Future<bool> purchaseProduct(
    String productId, {
    String? establishmentId,
    String? authToken,
    String? userId,
    String? packageName,
  }) {
    final extraData = <String, dynamic>{};
    if (establishmentId != null) extraData['establishmentId'] = establishmentId;
    return buyProduct(
      productId,
      authToken: authToken,
      userId: userId,
      packageName: packageName,
      extraData: extraData.isNotEmpty ? extraData : null,
    );
  }

  /// Inicia uma compra e retorna true se a validação no backend retornar sucesso.
  /// authToken deve ser o token JWT (pode vir com ou sem o prefixo 'Bearer ').
  /// extraData é um mapa opcional que será mesclado no body enviado ao backend (/api/payments/validate).
  Future<bool> buyProduct(
    String productId, {
    String? authToken,
    String? userId,
    String? packageName,
    Map<String, dynamic>? extraData,
  }) async {
    if (!available) throw Exception('Store not available');

    final product = findProduct(productId);
    if (product == null) {
      throw Exception('Produto não encontrado: $productId');
    }

    final completer = Completer<bool>();
    final meta = _PendingPurchaseMeta(
      completer: completer,
      authToken: authToken,
      userId: userId,
      packageName: packageName,
      extraData: extraData,
      createdAt: DateTime.now(),
    );

    // Insere na fila do productId
    _pendingByProduct.putIfAbsent(productId, () => []).add(meta);

    final purchaseParam = PurchaseParam(productDetails: product);

    try {
      final isConsumable = product.id.toLowerCase().contains('boost') ||
          product.id.toLowerCase().contains('consumable');

      if (isConsumable) {
        await _iap.buyConsumable(purchaseParam: purchaseParam, autoConsume: true);
      } else {
        await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      }
    } catch (err) {
      // remoção do pending em caso de falha imediata
      _removePendingMeta(productId, meta);
      if (!completer.isCompleted) completer.completeError(err);
      rethrow;
    }

    try {
      final result = await completer.future.timeout(const Duration(seconds: 60));
      return result;
    } catch (err) {
      // Timeout ou erro: limpar pending
      _removePendingMeta(productId, meta);
      return false;
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      try {
        final platform = Platform.isAndroid ? 'android' : 'ios';
        final serverVerificationData = purchase.verificationData.serverVerificationData;

        // Tenta encontrar a fila para esse productId
        final queue = _pendingByProduct[purchase.productID];
        _PendingPurchaseMeta? meta;
        if (queue != null && queue.isNotEmpty) {
          meta = queue.removeAt(0);
          if (queue.isEmpty) {
            _pendingByProduct.remove(purchase.productID);
          }
        }

        final authToken = meta?.authToken;
        final userId = meta?.userId;
        final packageName = meta?.packageName;
        final extraData = meta?.extraData;

        bool validationOk = false;
        try {
          validationOk = await _validateWithBackend(
            platform: platform,
            productId: purchase.productID,
            purchaseTokenOrReceipt: serverVerificationData,
            authToken: authToken,
            userId: userId,
            packageName: packageName,
            extraData: extraData,
          );
        } catch (e) {
          validationOk = false;
        }

        if (purchase.status == PurchaseStatus.pending) {
          // notificar UI se desejar
        } else if (purchase.status == PurchaseStatus.error) {
          if (meta != null && !meta.completer.isCompleted) {
            meta.completer.complete(false);
          }
        } else if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
          if (validationOk) {
            if (purchase.pendingCompletePurchase) {
              await _iap.completePurchase(purchase);
            }
            if (meta != null && !meta.completer.isCompleted) {
              meta.completer.complete(true);
            }
          } else {
            if (meta != null && !meta.completer.isCompleted) {
              meta.completer.complete(false);
            }
          }
        }
      } catch (e) {
        // Não propagar exceções do listener
      }
    }
  }

  Future<bool> _validateWithBackend({
    required String platform,
    required String productId,
    required String purchaseTokenOrReceipt,
    String? authToken,
    String? userId,
    String? packageName,
    Map<String, dynamic>? extraData,
  }) async {
    final url = '$backendBaseUrl/api/payments/validate';
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (authToken != null && authToken.isNotEmpty) {
      final tokenClean = authToken.replaceAll('Bearer ', '');
      headers['Authorization'] = 'Bearer $tokenClean';
    }

    final body = <String, dynamic>{
      'platform': platform,
      'productId': productId,
      'userId': userId,
    };

    if (platform == 'android') {
      body['purchaseToken'] = purchaseTokenOrReceipt;
      if (packageName != null) body['packageName'] = packageName;
    } else {
      body['receipt'] = purchaseTokenOrReceipt;
    }

    if (extraData != null && extraData.isNotEmpty) {
      body.addAll(extraData);
    }

    try {
      final resp = await _dio.post(
        url,
        data: body,
        options: Options(
          headers: headers,
          sendTimeout: const Duration(milliseconds: 15000),
          receiveTimeout: const Duration(milliseconds: 15000),
        ),
      );
      if (resp.statusCode == 200 && resp.data != null && resp.data['success'] == true) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> validatePurchaseWithBackend({
    required String platform,
    required String productId,
    required String purchaseTokenOrReceipt,
    String? authToken,
    String? userId,
    String? packageName,
    Map<String, dynamic>? extraData,
  }) {
    return _validateWithBackend(
      platform: platform,
      productId: productId,
      purchaseTokenOrReceipt: purchaseTokenOrReceipt,
      authToken: authToken,
      userId: userId,
      packageName: packageName,
      extraData: extraData,
    );
  }

  void _removePendingMeta(String productId, _PendingPurchaseMeta meta) {
    final queue = _pendingByProduct[productId];
    if (queue == null) return;
    queue.removeWhere((m) => identical(m, meta));
    if (queue.isEmpty) _pendingByProduct.remove(productId);
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _pendingByProduct.clear();
  }
}

class _PendingPurchaseMeta {
  final Completer<bool> completer;
  final String? authToken;
  final String? userId;
  final String? packageName;
  final Map<String, dynamic>? extraData;
  final DateTime createdAt;

  _PendingPurchaseMeta({
    required this.completer,
    this.authToken,
    this.userId,
    this.packageName,
    this.extraData,
    required this.createdAt,
  });
}