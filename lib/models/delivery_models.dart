import 'package:cloud_firestore/cloud_firestore.dart';

/// Configuração de delivery de um estabelecimento
class DeliveryConfig {
  final String id;
  final String establishmentId;
  final bool isActive;
  final double? deliveryFee;
  final double? freeDeliveryMinOrder; // Pedido mínimo para frete grátis
  final int deliveryTimeMin;
  final int deliveryTimeMax;
  final double deliveryRadius; // km
  final double minOrderValue;
  final String? deliveryNotes; // Observações sobre entrega
  final List<String> paymentMethods; // pix, cartao, dinheiro
  final Map<int, DeliverySchedule>? schedule; // Horários por dia da semana
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DeliveryConfig({
    required this.id,
    required this.establishmentId,
    this.isActive = false,
    this.deliveryFee,
    this.freeDeliveryMinOrder,
    this.deliveryTimeMin = 30,
    this.deliveryTimeMax = 60,
    this.deliveryRadius = 5.0,
    this.minOrderValue = 0,
    this.deliveryNotes,
    this.paymentMethods = const ['pix', 'cartao', 'dinheiro'],
    this.schedule,
    this.createdAt,
    this.updatedAt,
  });

  factory DeliveryConfig.fromJson(Map<String, dynamic> json, String id) {
    Map<int, DeliverySchedule>? schedule;
    if (json['schedule'] != null) {
      schedule = {};
      (json['schedule'] as Map<String, dynamic>).forEach((key, value) {
        schedule![int.parse(key)] = DeliverySchedule.fromJson(value);
      });
    }

    return DeliveryConfig(
      id: id,
      establishmentId: json['establishmentId'] as String,
      isActive: json['isActive'] as bool? ?? false,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble(),
      freeDeliveryMinOrder: (json['freeDeliveryMinOrder'] as num?)?.toDouble(),
      deliveryTimeMin: json['deliveryTimeMin'] as int? ?? 30,
      deliveryTimeMax: json['deliveryTimeMax'] as int? ?? 60,
      deliveryRadius: (json['deliveryRadius'] as num?)?.toDouble() ?? 5.0,
      minOrderValue: (json['minOrderValue'] as num?)?.toDouble() ?? 0,
      deliveryNotes: json['deliveryNotes'] as String?,
      paymentMethods: (json['paymentMethods'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['pix', 'cartao', 'dinheiro'],
      schedule: schedule,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic>? scheduleJson;
    if (schedule != null) {
      scheduleJson = {};
      schedule!.forEach((key, value) {
        scheduleJson![key.toString()] = value.toJson();
      });
    }

    return {
      'establishmentId': establishmentId,
      'isActive': isActive,
      'deliveryFee': deliveryFee,
      'freeDeliveryMinOrder': freeDeliveryMinOrder,
      'deliveryTimeMin': deliveryTimeMin,
      'deliveryTimeMax': deliveryTimeMax,
      'deliveryRadius': deliveryRadius,
      'minOrderValue': minOrderValue,
      'deliveryNotes': deliveryNotes,
      'paymentMethods': paymentMethods,
      'schedule': scheduleJson,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  DeliveryConfig copyWith({
    bool? isActive,
    double? deliveryFee,
    double? freeDeliveryMinOrder,
    int? deliveryTimeMin,
    int? deliveryTimeMax,
    double? deliveryRadius,
    double? minOrderValue,
    String? deliveryNotes,
    List<String>? paymentMethods,
    Map<int, DeliverySchedule>? schedule,
  }) {
    return DeliveryConfig(
      id: id,
      establishmentId: establishmentId,
      isActive: isActive ?? this.isActive,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      freeDeliveryMinOrder: freeDeliveryMinOrder ?? this.freeDeliveryMinOrder,
      deliveryTimeMin: deliveryTimeMin ?? this.deliveryTimeMin,
      deliveryTimeMax: deliveryTimeMax ?? this.deliveryTimeMax,
      deliveryRadius: deliveryRadius ?? this.deliveryRadius,
      minOrderValue: minOrderValue ?? this.minOrderValue,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      schedule: schedule ?? this.schedule,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Horário de funcionamento do delivery por dia
class DeliverySchedule {
  final bool isOpen;
  final String? openTime; // HH:mm
  final String? closeTime; // HH:mm

  DeliverySchedule({
    this.isOpen = true,
    this.openTime,
    this.closeTime,
  });

  factory DeliverySchedule.fromJson(Map<String, dynamic> json) {
    return DeliverySchedule(
      isOpen: json['isOpen'] as bool? ?? true,
      openTime: json['openTime'] as String?,
      closeTime: json['closeTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isOpen': isOpen,
      'openTime': openTime,
      'closeTime': closeTime,
    };
  }
}

/// Categoria do cardápio
class MenuCategory {
  final String id;
  final String establishmentId;
  final String name;
  final String? description;
  final int order;
  final bool isActive;
  final DateTime? createdAt;

  MenuCategory({
    required this.id,
    required this.establishmentId,
    required this.name,
    this.description,
    this.order = 0,
    this.isActive = true,
    this.createdAt,
  });

  factory MenuCategory.fromJson(Map<String, dynamic> json, String id) {
    return MenuCategory(
      id: id,
      establishmentId: json['establishmentId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      order: json['order'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'establishmentId': establishmentId,
      'name': name,
      'description': description,
      'order': order,
      'isActive': isActive,
      'createdAt': createdAt != null 
          ? Timestamp.fromDate(createdAt!) 
          : FieldValue.serverTimestamp(),
    };
  }
}

/// Item do cardápio
class DeliveryMenuItem {
  final String id;
  final String establishmentId;
  final String categoryId;
  final String name;
  final String? description;
  final double price;
  final double? originalPrice; // Para promoções
  final String? imageUrl;
  final bool isAvailable;
  final bool isPromoted; // Destaque
  final List<String> dietaryTags; // celiac, vegan, etc
  final List<MenuItemOption>? options; // Opcionais/adicionais
  final int? preparationTime; // minutos
  final int order;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<int>? availableDays; // Dias da semana disponíveis (0=dom, 1=seg, ..., 6=sab)

  DeliveryMenuItem({
    required this.id,
    required this.establishmentId,
    required this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.originalPrice,
    this.imageUrl,
    this.isAvailable = true,
    this.isPromoted = false,
    this.dietaryTags = const [],
    this.options,
    this.preparationTime,
    this.order = 0,
    this.createdAt,
    this.updatedAt,
    this.availableDays,
  });
  
  /// Verifica se o item está disponível hoje
  bool get isAvailableToday {
    if (!isAvailable) return false;
    if (availableDays == null || availableDays!.isEmpty) return true;
    
    final now = DateTime.now();
    // DateTime.weekday: 1=segunda, ..., 7=domingo
    // availableDays: 0=domingo, 1=segunda, ..., 6=sábado
    final todayIndex = now.weekday == 7 ? 0 : now.weekday;
    return availableDays!.contains(todayIndex);
  }
  
  /// Retorna os dias disponíveis formatados
  String get availableDaysText {
    if (availableDays == null || availableDays!.isEmpty) return 'Todos os dias';
    
    const dayNames = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    return availableDays!.map((d) => dayNames[d]).join(', ');
  }

  bool get hasDiscount => originalPrice != null && originalPrice! > price;
  
  double get discountPercent {
    if (!hasDiscount) return 0;
    return ((originalPrice! - price) / originalPrice! * 100);
  }

  factory DeliveryMenuItem.fromJson(Map<String, dynamic> json, String id) {
    List<MenuItemOption>? options;
    if (json['options'] != null) {
      options = (json['options'] as List<dynamic>)
          .map((e) => MenuItemOption.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return DeliveryMenuItem(
      id: id,
      establishmentId: json['establishmentId'] as String,
      categoryId: json['categoryId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      originalPrice: (json['originalPrice'] as num?)?.toDouble(),
      imageUrl: json['imageUrl'] as String?,
      isAvailable: json['isAvailable'] as bool? ?? true,
      isPromoted: json['isPromoted'] as bool? ?? false,
      dietaryTags: (json['dietaryTags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      options: options,
      preparationTime: json['preparationTime'] as int?,
      order: json['order'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
      availableDays: json['availableDays'] != null
          ? (json['availableDays'] as List<dynamic>).map((e) => e as int).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'establishmentId': establishmentId,
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'isPromoted': isPromoted,
      'dietaryTags': dietaryTags,
      'options': options?.map((e) => e.toJson()).toList(),
      'preparationTime': preparationTime,
      'order': order,
      'updatedAt': FieldValue.serverTimestamp(),
      if (availableDays != null) 'availableDays': availableDays,
    };
  }
}

/// Opção/adicional de um item do cardápio
class MenuItemOption {
  final String name;
  final double price;
  final bool isRequired;
  final int maxQuantity;

  MenuItemOption({
    required this.name,
    required this.price,
    this.isRequired = false,
    this.maxQuantity = 1,
  });

  factory MenuItemOption.fromJson(Map<String, dynamic> json) {
    return MenuItemOption(
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      isRequired: json['isRequired'] as bool? ?? false,
      maxQuantity: json['maxQuantity'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'isRequired': isRequired,
      'maxQuantity': maxQuantity,
    };
  }
}

/// Cupom de desconto
class DeliveryCoupon {
  final String id;
  final String establishmentId;
  final String code;
  final String? description;
  final CouponType type;
  final double value; // Valor do desconto (% ou R$)
  final double? minOrderValue; // Pedido mínimo para usar
  final double? maxDiscount; // Desconto máximo (para %)
  final int? maxUses; // Limite de usos total
  final int? maxUsesPerUser; // Limite por usuário
  final int usedCount;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final bool isActive;
  final List<String>? applicableCategories; // null = todas
  final DateTime? createdAt;

  DeliveryCoupon({
    required this.id,
    required this.establishmentId,
    required this.code,
    this.description,
    required this.type,
    required this.value,
    this.minOrderValue,
    this.maxDiscount,
    this.maxUses,
    this.maxUsesPerUser,
    this.usedCount = 0,
    this.validFrom,
    this.validUntil,
    this.isActive = true,
    this.applicableCategories,
    this.createdAt,
  });

  bool get isValid {
    if (!isActive) return false;
    final now = DateTime.now();
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validUntil != null && now.isAfter(validUntil!)) return false;
    if (maxUses != null && usedCount >= maxUses!) return false;
    return true;
  }

  String get formattedValue {
    if (type == CouponType.percentage) {
      return '${value.toStringAsFixed(0)}% OFF';
    } else if (type == CouponType.freeDelivery) {
      return 'Frete Grátis';
    } else {
      return 'R\$ ${value.toStringAsFixed(2)} OFF';
    }
  }

  factory DeliveryCoupon.fromJson(Map<String, dynamic> json, String id) {
    return DeliveryCoupon(
      id: id,
      establishmentId: json['establishmentId'] as String,
      code: json['code'] as String,
      description: json['description'] as String?,
      type: CouponType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CouponType.fixed,
      ),
      value: (json['value'] as num).toDouble(),
      minOrderValue: (json['minOrderValue'] as num?)?.toDouble(),
      maxDiscount: (json['maxDiscount'] as num?)?.toDouble(),
      maxUses: json['maxUses'] as int?,
      maxUsesPerUser: json['maxUsesPerUser'] as int?,
      usedCount: json['usedCount'] as int? ?? 0,
      validFrom: json['validFrom'] != null
          ? (json['validFrom'] as Timestamp).toDate()
          : null,
      validUntil: json['validUntil'] != null
          ? (json['validUntil'] as Timestamp).toDate()
          : null,
      isActive: json['isActive'] as bool? ?? true,
      applicableCategories: (json['applicableCategories'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'establishmentId': establishmentId,
      'code': code.toUpperCase(),
      'description': description,
      'type': type.name,
      'value': value,
      'minOrderValue': minOrderValue,
      'maxDiscount': maxDiscount,
      'maxUses': maxUses,
      'maxUsesPerUser': maxUsesPerUser,
      'usedCount': usedCount,
      'validFrom': validFrom != null ? Timestamp.fromDate(validFrom!) : null,
      'validUntil': validUntil != null ? Timestamp.fromDate(validUntil!) : null,
      'isActive': isActive,
      'applicableCategories': applicableCategories,
      'createdAt': createdAt != null 
          ? Timestamp.fromDate(createdAt!) 
          : FieldValue.serverTimestamp(),
    };
  }
}

enum CouponType {
  percentage, // Desconto em %
  fixed, // Desconto em R$
  freeDelivery, // Frete grátis
}

/// Pedido de delivery
class DeliveryOrder {
  final String id;
  final String establishmentId;
  final String? userId;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final double? latitude;
  final double? longitude;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final String? couponCode;
  final String paymentMethod;
  final String? paymentNotes;
  final OrderStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? preparingAt;
  final DateTime? readyAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final String? cancelReason;

  DeliveryOrder({
    required this.id,
    required this.establishmentId,
    this.userId,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    this.latitude,
    this.longitude,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    this.discount = 0,
    required this.total,
    this.couponCode,
    required this.paymentMethod,
    this.paymentNotes,
    this.status = OrderStatus.pending,
    this.notes,
    required this.createdAt,
    this.acceptedAt,
    this.preparingAt,
    this.readyAt,
    this.deliveredAt,
    this.cancelledAt,
    this.cancelReason,
  });

  factory DeliveryOrder.fromJson(Map<String, dynamic> json, String id) {
    return DeliveryOrder(
      id: id,
      establishmentId: json['establishmentId'] as String,
      userId: json['userId'] as String?,
      customerName: json['customerName'] as String,
      customerPhone: json['customerPhone'] as String,
      deliveryAddress: json['deliveryAddress'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      items: (json['items'] as List<dynamic>)
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryFee: (json['deliveryFee'] as num).toDouble(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num).toDouble(),
      couponCode: json['couponCode'] as String?,
      paymentMethod: json['paymentMethod'] as String,
      paymentNotes: json['paymentNotes'] as String?,
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      notes: json['notes'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      acceptedAt: json['acceptedAt'] != null
          ? (json['acceptedAt'] as Timestamp).toDate()
          : null,
      preparingAt: json['preparingAt'] != null
          ? (json['preparingAt'] as Timestamp).toDate()
          : null,
      readyAt: json['readyAt'] != null
          ? (json['readyAt'] as Timestamp).toDate()
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? (json['deliveredAt'] as Timestamp).toDate()
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? (json['cancelledAt'] as Timestamp).toDate()
          : null,
      cancelReason: json['cancelReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'establishmentId': establishmentId,
      'userId': userId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'deliveryAddress': deliveryAddress,
      'latitude': latitude,
      'longitude': longitude,
      'items': items.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'discount': discount,
      'total': total,
      'couponCode': couponCode,
      'paymentMethod': paymentMethod,
      'paymentNotes': paymentNotes,
      'status': status.name,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'preparingAt': preparingAt != null ? Timestamp.fromDate(preparingAt!) : null,
      'readyAt': readyAt != null ? Timestamp.fromDate(readyAt!) : null,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'cancelReason': cancelReason,
    };
  }
}

/// Item de um pedido
class OrderItem {
  final String menuItemId;
  final String name;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final List<String>? selectedOptions;
  final String? notes;

  OrderItem({
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.selectedOptions,
    this.notes,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      menuItemId: json['menuItemId'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      selectedOptions: (json['selectedOptions'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'selectedOptions': selectedOptions,
      'notes': notes,
    };
  }
}

enum OrderStatus {
  pending, // Aguardando confirmação
  accepted, // Aceito
  preparing, // Em preparo
  ready, // Pronto para entrega
  delivering, // Saiu para entrega
  delivered, // Entregue
  cancelled, // Cancelado
}

extension OrderStatusExtension on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Aguardando';
      case OrderStatus.accepted:
        return 'Aceito';
      case OrderStatus.preparing:
        return 'Preparando';
      case OrderStatus.ready:
        return 'Pronto';
      case OrderStatus.delivering:
        return 'Em entrega';
      case OrderStatus.delivered:
        return 'Entregue';
      case OrderStatus.cancelled:
        return 'Cancelado';
    }
  }

  String get icon {
    switch (this) {
      case OrderStatus.pending:
        return '⏳';
      case OrderStatus.accepted:
        return '✅';
      case OrderStatus.preparing:
        return '👨‍🍳';
      case OrderStatus.ready:
        return '📦';
      case OrderStatus.delivering:
        return '🛵';
      case OrderStatus.delivered:
        return '🎉';
      case OrderStatus.cancelled:
        return '❌';
    }
  }
}
