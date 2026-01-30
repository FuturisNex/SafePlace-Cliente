import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class IAPService {
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;

  // Expor o stream para que PaymentService possa assinar
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  Future<bool> isAvailable() async {
    return await _iap.isAvailable();
  }

  Future<ProductDetailsResponse> queryProducts(Set<String> productIds) async {
    debugPrint('🔍 IAPService.queryProducts: $productIds');
    
    try {
      final available = await isAvailable();
      if (!available) {
        debugPrint('❌ IAPService.queryProducts: Loja não disponível');
        throw Exception('Loja de apps não disponível');
      }
      
      final response = await _iap.queryProductDetails(productIds);
      
      debugPrint('📦 IAPService.queryProducts: Encontrados ${response.productDetails.length} produtos');
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('⚠️  IAPService.queryProducts: Produtos não encontrados: ${response.notFoundIDs}');
        debugPrint('   Verifique se estão configurados na loja (Google Play ou App Store)');
      }
      for (final product in response.productDetails) {
        debugPrint('   - ${product.id}: ${product.title} (${product.currencyCode} ${product.price})');
      }
      
      return response;
    } catch (e) {
      debugPrint('❌ IAPService.queryProducts erro: $e');
      rethrow;
    }
  }

  Future<void> buyProduct(ProductDetails product, {bool consumable = false}) async {
    debugPrint('🛒 IAPService.buyProduct: ${product.id} | consumable: $consumable');
    
    try {
      final available = await isAvailable();
      if (!available) {
        throw Exception('Loja de apps não está disponível no seu dispositivo. Verifique sua conexão e se a conta está vinculada corretamente.');
      }
      
      final purchaseParam = PurchaseParam(productDetails: product);
      if (Platform.isAndroid) {
        debugPrint('🤖 IAPService: Usando GooglePlayBilling para compra de ${product.id}');
        if (consumable) {
          await _iap.buyConsumable(purchaseParam: purchaseParam, autoConsume: true);
        } else {
          await _iap.buyNonConsumable(purchaseParam: purchaseParam);
        }
      } else {
        debugPrint('🍎 IAPService: Usando App Store (StoreKit) para compra de ${product.id}');
        if (consumable) {
          await _iap.buyConsumable(purchaseParam: purchaseParam, autoConsume: true);
        } else {
          await _iap.buyNonConsumable(purchaseParam: purchaseParam);
        }
      }
      debugPrint('✅ IAPService.buyProduct: Compra iniciada com sucesso para ${product.id}');
    } catch (e) {
      debugPrint('❌ IAPService.buyProduct erro: $e');
      rethrow;
    }
  }

  Future<void> restorePurchases() async {
    debugPrint('🔄 IAPService.restorePurchases: Iniciando restauração de compras anteriores');
    
    try {
      final available = await isAvailable();
      if (!available) {
        throw Exception('Loja de apps não está disponível');
      }
      
      await _iap.restorePurchases();
      debugPrint('✅ IAPService.restorePurchases: Restauração iniciada');
    } catch (e) {
      debugPrint('❌ IAPService.restorePurchases erro: $e');
      rethrow;
    }
  }

  // acknowledgment/complete is handled by InAppPurchase.instance.completePurchase when appropriate
}