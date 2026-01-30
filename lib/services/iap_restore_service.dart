import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Serviço simples para restaurar compras consumidas/assinaturas.
/// Fornece o método estático restorePurchases() usado pela UI.
class IAPRestoreService {
  /// Solicita restauração de compras e retorna `true` se a chamada foi iniciada com sucesso.
  /// Observação: as compras restauradas chegarão pelo InAppPurchase.instance.purchaseStream.
  static Future<bool> restorePurchases() async {
    debugPrint('🔄 IAPRestoreService.restorePurchases: Iniciando restauração de compras');
    
    try {
      final available = await InAppPurchase.instance.isAvailable();
      if (!available) {
        debugPrint('❌ IAPRestoreService: Loja de apps não disponível');
        return false;
      }
      
      await InAppPurchase.instance.restorePurchases();
      debugPrint('✅ IAPRestoreService: Restauração iniciada com sucesso');
      debugPrint('   Aguarde as compras restauradas no purchaseStream');
      return true;
    } catch (e) {
      debugPrint('❌ IAPRestoreService erro: $e');
      return false;
    }
  }
}