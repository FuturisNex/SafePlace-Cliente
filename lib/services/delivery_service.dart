import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/delivery_models.dart';

/// Serviço para gerenciar delivery de estabelecimentos
class DeliveryService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============ CONFIGURAÇÃO DE DELIVERY ============

  /// Obter configuração de delivery de um estabelecimento
  static Future<DeliveryConfig?> getDeliveryConfig(String establishmentId) async {
    try {
      final doc = await _db
          .collection('deliveryConfigs')
          .doc(establishmentId)
          .get();

      if (!doc.exists) return null;
      return DeliveryConfig.fromJson(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('❌ Erro ao buscar config de delivery: $e');
      return null;
    }
  }

  /// Salvar/atualizar configuração de delivery
  static Future<void> saveDeliveryConfig(DeliveryConfig config) async {
    try {
      await _db
          .collection('deliveryConfigs')
          .doc(config.establishmentId)
          .set(config.toJson(), SetOptions(merge: true));

      // Atualizar campo hasDelivery no estabelecimento
      await _db.collection('establishments').doc(config.establishmentId).update({
        'hasDelivery': config.isActive,
        'deliveryFee': config.deliveryFee,
        'deliveryTimeMin': config.deliveryTimeMin,
        'deliveryTimeMax': config.deliveryTimeMax,
        'minOrderValue': config.minOrderValue,
        'deliveryRadius': config.deliveryRadius,
      });

      debugPrint('✅ Config de delivery salva: ${config.establishmentId}');
    } catch (e) {
      debugPrint('❌ Erro ao salvar config de delivery: $e');
      rethrow;
    }
  }

  // ============ CATEGORIAS DO CARDÁPIO ============

  /// Listar categorias do cardápio
  static Stream<List<MenuCategory>> getCategoriesStream(String establishmentId) {
    return _db
        .collection('menuCategories')
        .where('establishmentId', isEqualTo: establishmentId)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MenuCategory.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Criar categoria
  static Future<String> createCategory(MenuCategory category) async {
    try {
      final doc = await _db.collection('menuCategories').add(category.toJson());
      debugPrint('✅ Categoria criada: ${doc.id}');
      return doc.id;
    } catch (e) {
      debugPrint('❌ Erro ao criar categoria: $e');
      rethrow;
    }
  }

  /// Atualizar categoria
  static Future<void> updateCategory(MenuCategory category) async {
    try {
      await _db.collection('menuCategories').doc(category.id).update({
        'name': category.name,
        'description': category.description,
        'order': category.order,
        'isActive': category.isActive,
      });
      debugPrint('✅ Categoria atualizada: ${category.id}');
    } catch (e) {
      debugPrint('❌ Erro ao atualizar categoria: $e');
      rethrow;
    }
  }

  /// Deletar categoria
  static Future<void> deleteCategory(String categoryId) async {
    try {
      // Deletar itens da categoria primeiro
      final items = await _db
          .collection('menuItems')
          .where('categoryId', isEqualTo: categoryId)
          .get();

      final batch = _db.batch();
      for (final doc in items.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_db.collection('menuCategories').doc(categoryId));
      await batch.commit();

      debugPrint('✅ Categoria deletada: $categoryId');
    } catch (e) {
      debugPrint('❌ Erro ao deletar categoria: $e');
      rethrow;
    }
  }

  // ============ ITENS DO CARDÁPIO ============

  /// Listar itens do cardápio
  static Stream<List<DeliveryMenuItem>> getMenuItemsStream(String establishmentId) {
    return _db
        .collection('menuItems')
        .where('establishmentId', isEqualTo: establishmentId)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DeliveryMenuItem.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Listar itens de uma categoria
  static Stream<List<DeliveryMenuItem>> getMenuItemsByCategoryStream(
      String categoryId) {
    return _db
        .collection('menuItems')
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DeliveryMenuItem.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Criar item do cardápio
  static Future<String> createMenuItem(DeliveryMenuItem item) async {
    try {
      final data = item.toJson();
      data['createdAt'] = FieldValue.serverTimestamp();
      final doc = await _db.collection('menuItems').add(data);
      debugPrint('✅ Item criado: ${doc.id}');
      return doc.id;
    } catch (e) {
      debugPrint('❌ Erro ao criar item: $e');
      rethrow;
    }
  }

  /// Atualizar item do cardápio
  static Future<void> updateMenuItem(DeliveryMenuItem item) async {
    try {
      await _db.collection('menuItems').doc(item.id).update(item.toJson());
      debugPrint('✅ Item atualizado: ${item.id}');
    } catch (e) {
      debugPrint('❌ Erro ao atualizar item: $e');
      rethrow;
    }
  }

  /// Deletar item do cardápio
  static Future<void> deleteMenuItem(String itemId) async {
    try {
      await _db.collection('menuItems').doc(itemId).delete();
      debugPrint('✅ Item deletado: $itemId');
    } catch (e) {
      debugPrint('❌ Erro ao deletar item: $e');
      rethrow;
    }
  }

  /// Toggle disponibilidade do item
  static Future<void> toggleItemAvailability(String itemId, bool isAvailable) async {
    try {
      await _db.collection('menuItems').doc(itemId).update({
        'isAvailable': isAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ Erro ao alterar disponibilidade: $e');
      rethrow;
    }
  }

  // ============ CUPONS ============

  /// Listar cupons do estabelecimento
  static Stream<List<DeliveryCoupon>> getCouponsStream(String establishmentId) {
    return _db
        .collection('deliveryCoupons')
        .where('establishmentId', isEqualTo: establishmentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DeliveryCoupon.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Criar cupom
  static Future<String> createCoupon(DeliveryCoupon coupon) async {
    try {
      // Verificar se código já existe
      final existing = await _db
          .collection('deliveryCoupons')
          .where('establishmentId', isEqualTo: coupon.establishmentId)
          .where('code', isEqualTo: coupon.code.toUpperCase())
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception('Já existe um cupom com este código');
      }

      final doc = await _db.collection('deliveryCoupons').add(coupon.toJson());
      debugPrint('✅ Cupom criado: ${doc.id}');
      return doc.id;
    } catch (e) {
      debugPrint('❌ Erro ao criar cupom: $e');
      rethrow;
    }
  }

  /// Atualizar cupom
  static Future<void> updateCoupon(DeliveryCoupon coupon) async {
    try {
      await _db.collection('deliveryCoupons').doc(coupon.id).update({
        'description': coupon.description,
        'type': coupon.type.name,
        'value': coupon.value,
        'minOrderValue': coupon.minOrderValue,
        'maxDiscount': coupon.maxDiscount,
        'maxUses': coupon.maxUses,
        'maxUsesPerUser': coupon.maxUsesPerUser,
        'validFrom': coupon.validFrom != null 
            ? Timestamp.fromDate(coupon.validFrom!) 
            : null,
        'validUntil': coupon.validUntil != null 
            ? Timestamp.fromDate(coupon.validUntil!) 
            : null,
        'isActive': coupon.isActive,
        'applicableCategories': coupon.applicableCategories,
      });
      debugPrint('✅ Cupom atualizado: ${coupon.id}');
    } catch (e) {
      debugPrint('❌ Erro ao atualizar cupom: $e');
      rethrow;
    }
  }

  /// Deletar cupom
  static Future<void> deleteCoupon(String couponId) async {
    try {
      await _db.collection('deliveryCoupons').doc(couponId).delete();
      debugPrint('✅ Cupom deletado: $couponId');
    } catch (e) {
      debugPrint('❌ Erro ao deletar cupom: $e');
      rethrow;
    }
  }

  /// Toggle ativo/inativo do cupom
  static Future<void> toggleCouponActive(String couponId, bool isActive) async {
    try {
      await _db.collection('deliveryCoupons').doc(couponId).update({
        'isActive': isActive,
      });
    } catch (e) {
      debugPrint('❌ Erro ao alterar status do cupom: $e');
      rethrow;
    }
  }

  // ============ PEDIDOS ============

  /// Stream de pedidos do estabelecimento
  static Stream<List<DeliveryOrder>> getOrdersStream(
    String establishmentId, {
    List<OrderStatus>? statusFilter,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection('deliveryOrders')
        .where('establishmentId', isEqualTo: establishmentId)
        .orderBy('createdAt', descending: true);

    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.where('status', whereIn: statusFilter.map((e) => e.name).toList());
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => DeliveryOrder.fromJson(doc.data(), doc.id))
        .toList());
  }

  /// Atualizar status do pedido
  static Future<void> updateOrderStatus(
    String orderId,
    OrderStatus newStatus, {
    String? cancelReason,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': newStatus.name,
      };

      switch (newStatus) {
        case OrderStatus.accepted:
          updates['acceptedAt'] = FieldValue.serverTimestamp();
          break;
        case OrderStatus.preparing:
          updates['preparingAt'] = FieldValue.serverTimestamp();
          break;
        case OrderStatus.ready:
          updates['readyAt'] = FieldValue.serverTimestamp();
          break;
        case OrderStatus.delivered:
          updates['deliveredAt'] = FieldValue.serverTimestamp();
          break;
        case OrderStatus.cancelled:
          updates['cancelledAt'] = FieldValue.serverTimestamp();
          updates['cancelReason'] = cancelReason;
          break;
        default:
          break;
      }

      await _db.collection('deliveryOrders').doc(orderId).update(updates);
      debugPrint('✅ Status do pedido atualizado: $orderId -> ${newStatus.name}');
    } catch (e) {
      debugPrint('❌ Erro ao atualizar status do pedido: $e');
      rethrow;
    }
  }

  // ============ ESTATÍSTICAS ============

  /// Obter estatísticas de delivery
  static Future<Map<String, dynamic>> getDeliveryStats(
    String establishmentId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _db
          .collection('deliveryOrders')
          .where('establishmentId', isEqualTo: establishmentId);

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      final orders = snapshot.docs
          .map((doc) => DeliveryOrder.fromJson(doc.data(), doc.id))
          .toList();

      final delivered = orders.where((o) => o.status == OrderStatus.delivered).toList();
      final cancelled = orders.where((o) => o.status == OrderStatus.cancelled).toList();

      return {
        'totalOrders': orders.length,
        'deliveredOrders': delivered.length,
        'cancelledOrders': cancelled.length,
        'totalRevenue': delivered.fold<double>(0, (sum, o) => sum + o.total),
        'averageTicket': delivered.isNotEmpty
            ? delivered.fold<double>(0, (sum, o) => sum + o.total) / delivered.length
            : 0,
      };
    } catch (e) {
      debugPrint('❌ Erro ao buscar estatísticas: $e');
      return {};
    }
  }
}
