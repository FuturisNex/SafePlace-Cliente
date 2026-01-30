class CheckIn {
  final String id;
  final String userId;
  final String establishmentId;
  final String? establishmentName;
  final DateTime createdAt;
  final double? rating; // Avaliação opcional no check-in
  final String? reviewId; // ID da avaliação associada, se houver

  CheckIn({
    required this.id,
    required this.userId,
    required this.establishmentId,
    this.establishmentName,
    required this.createdAt,
    this.rating,
    this.reviewId,
  });

  factory CheckIn.fromJson(Map<String, dynamic> json) {
    return CheckIn(
      id: json['id'] as String,
      userId: json['userId'] as String,
      establishmentId: json['establishmentId'] as String,
      establishmentName: json['establishmentName'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      reviewId: json['reviewId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'establishmentId': establishmentId,
      'establishmentName': establishmentName,
      'createdAt': createdAt.toIso8601String(),
      'rating': rating,
      'reviewId': reviewId,
    };
  }
}


