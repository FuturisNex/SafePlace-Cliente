import 'package:flutter/foundation.dart';
import '../models/delivery_models.dart';
import '../models/establishment.dart';

/// Item no carrinho de compras
class CartItem {
  final DeliveryMenuItem menuItem;
  int quantity;
  final List<String>? selectedOptions;
  final String? notes;

  CartItem({
    required this.menuItem,
    this.quantity = 1,
    this.selectedOptions,
    this.notes,
  });

  double get totalPrice => menuItem.price * quantity;

  CartItem copyWith({
    int? quantity,
    List<String>? selectedOptions,
    String? notes,
  }) {
    return CartItem(
      menuItem: menuItem,
      quantity: quantity ?? this.quantity,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      notes: notes ?? this.notes,
    );
  }
}

/// Provider para gerenciar o carrinho de compras
class CartProvider extends ChangeNotifier {
  // Estabelecimento atual do carrinho
  Establishment? _establishment;
  
  // Itens no carrinho
  final List<CartItem> _items = [];
  
  // Cupom aplicado
  DeliveryCoupon? _appliedCoupon;
  
  // Taxa de entrega
  double _deliveryFee = 0;
  
  // Pedido mínimo para frete grátis
  double? _freeDeliveryMinOrder;

  // Getters
  Establishment? get establishment => _establishment;
  List<CartItem> get items => List.unmodifiable(_items);
  DeliveryCoupon? get appliedCoupon => _appliedCoupon;
  double get deliveryFee => _deliveryFee;
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  /// Quantidade total de itens
  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  /// Subtotal (sem taxa e desconto)
  double get subtotal => _items.fold(0, (sum, item) => sum + item.totalPrice);

  /// Valor do desconto
  double get discount {
    if (_appliedCoupon == null || !_appliedCoupon!.isValid) return 0;

    // Verificar pedido mínimo do cupom
    if (_appliedCoupon!.minOrderValue != null &&
        subtotal < _appliedCoupon!.minOrderValue!) {
      return 0;
    }

    switch (_appliedCoupon!.type) {
      case CouponType.percentage:
        double discountValue = subtotal * (_appliedCoupon!.value / 100);
        // Aplicar limite máximo de desconto
        if (_appliedCoupon!.maxDiscount != null &&
            discountValue > _appliedCoupon!.maxDiscount!) {
          discountValue = _appliedCoupon!.maxDiscount!;
        }
        return discountValue;
      case CouponType.fixed:
        return _appliedCoupon!.value;
      case CouponType.freeDelivery:
        return _deliveryFee;
    }
  }

  /// Taxa de entrega final (considerando frete grátis)
  double get finalDeliveryFee {
    // Cupom de frete grátis
    if (_appliedCoupon?.type == CouponType.freeDelivery &&
        _appliedCoupon!.isValid) {
      return 0;
    }
    // Frete grátis por valor mínimo
    if (_freeDeliveryMinOrder != null && subtotal >= _freeDeliveryMinOrder!) {
      return 0;
    }
    return _deliveryFee;
  }

  /// Total final
  double get total {
    double totalValue = subtotal + finalDeliveryFee;
    
    // Aplicar desconto (exceto frete grátis que já foi aplicado)
    if (_appliedCoupon?.type != CouponType.freeDelivery) {
      totalValue -= discount;
    }
    
    return totalValue > 0 ? totalValue : 0;
  }

  /// Verificar se atinge pedido mínimo
  bool get meetsMinimumOrder {
    if (_establishment == null) return true;
    return subtotal >= (_establishment!.minOrderValue ?? 0);
  }

  /// Valor faltante para pedido mínimo
  double get remainingForMinimum {
    if (_establishment == null) return 0;
    final min = _establishment!.minOrderValue ?? 0;
    return min > subtotal ? min - subtotal : 0;
  }

  /// Valor faltante para frete grátis
  double get remainingForFreeDelivery {
    if (_freeDeliveryMinOrder == null) return 0;
    return _freeDeliveryMinOrder! > subtotal
        ? _freeDeliveryMinOrder! - subtotal
        : 0;
  }

  /// Inicializar carrinho com estabelecimento
  void setEstablishment(
    Establishment establishment, {
    double deliveryFee = 0,
    double? freeDeliveryMinOrder,
  }) {
    // Se mudar de estabelecimento, limpar carrinho
    if (_establishment != null && _establishment!.id != establishment.id) {
      clear();
    }
    _establishment = establishment;
    _deliveryFee = deliveryFee;
    _freeDeliveryMinOrder = freeDeliveryMinOrder;
    notifyListeners();
  }

  /// Adicionar item ao carrinho
  void addItem(DeliveryMenuItem menuItem, {int quantity = 1, String? notes}) {
    // Verificar se item já existe
    final existingIndex = _items.indexWhere((i) => i.menuItem.id == menuItem.id);

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(
        menuItem: menuItem,
        quantity: quantity,
        notes: notes,
      ));
    }
    notifyListeners();
  }

  /// Remover item do carrinho
  void removeItem(String menuItemId) {
    _items.removeWhere((i) => i.menuItem.id == menuItemId);
    notifyListeners();
  }

  /// Atualizar quantidade de um item
  void updateQuantity(String menuItemId, int quantity) {
    if (quantity <= 0) {
      removeItem(menuItemId);
      return;
    }

    final index = _items.indexWhere((i) => i.menuItem.id == menuItemId);
    if (index >= 0) {
      _items[index].quantity = quantity;
      notifyListeners();
    }
  }

  /// Incrementar quantidade
  void incrementItem(String menuItemId) {
    final index = _items.indexWhere((i) => i.menuItem.id == menuItemId);
    if (index >= 0) {
      _items[index].quantity++;
      notifyListeners();
    }
  }

  /// Decrementar quantidade
  void decrementItem(String menuItemId) {
    final index = _items.indexWhere((i) => i.menuItem.id == menuItemId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  /// Obter quantidade de um item específico
  int getItemQuantity(String menuItemId) {
    final item = _items.where((i) => i.menuItem.id == menuItemId).firstOrNull;
    return item?.quantity ?? 0;
  }

  /// Aplicar cupom
  void applyCoupon(DeliveryCoupon coupon) {
    _appliedCoupon = coupon;
    notifyListeners();
  }

  /// Remover cupom
  void removeCoupon() {
    _appliedCoupon = null;
    notifyListeners();
  }

  /// Limpar carrinho
  void clear() {
    _items.clear();
    _appliedCoupon = null;
    notifyListeners();
  }

  /// Limpar tudo (incluindo estabelecimento)
  void clearAll() {
    _items.clear();
    _appliedCoupon = null;
    _establishment = null;
    _deliveryFee = 0;
    _freeDeliveryMinOrder = null;
    notifyListeners();
  }

  /// Converter itens para OrderItem (para criar pedido)
  List<OrderItem> toOrderItems() {
    return _items.map((cartItem) => OrderItem(
      menuItemId: cartItem.menuItem.id,
      name: cartItem.menuItem.name,
      quantity: cartItem.quantity,
      unitPrice: cartItem.menuItem.price,
      totalPrice: cartItem.totalPrice,
      selectedOptions: cartItem.selectedOptions,
      notes: cartItem.notes,
    )).toList();
  }
}
