class Coupon {
  final String id;
  final String userId;
  final String establishmentId;
  final String? establishmentName;
  final String title;
  final String description;
  final double discount; // Percentual de desconto (ex: 15.0 = 15%)
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isActive;
  final bool isUsed;
  final DateTime? usedAt;
  final int pointsCost; // Pontos necessários para resgatar

  Coupon({
    required this.id,
    required this.userId,
    required this.establishmentId,
    this.establishmentName,
    required this.title,
    required this.description,
    required this.discount,
    required this.createdAt,
    required this.expiresAt,
    this.isActive = true,
    this.isUsed = false,
    this.usedAt,
    this.pointsCost = 0,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'] as String,
      userId: json['userId'] as String,
      establishmentId: json['establishmentId'] as String,
      establishmentName: json['establishmentName'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      discount: (json['discount'] as num).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : DateTime.now().add(const Duration(days: 30)),
      isActive: json['isActive'] as bool? ?? true,
      isUsed: json['isUsed'] as bool? ?? false,
      usedAt: json['usedAt'] != null
          ? DateTime.parse(json['usedAt'] as String)
          : null,
      pointsCost: json['pointsCost'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'establishmentId': establishmentId,
      'establishmentName': establishmentName,
      'title': title,
      'description': description,
      'discount': discount,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'isActive': isActive,
      'isUsed': isUsed,
      'usedAt': usedAt?.toIso8601String(),
      'pointsCost': pointsCost,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get canUse => isActive && !isUsed && !isExpired;
}


