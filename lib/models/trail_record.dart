import '../models/establishment.dart';

class TrailRecord {
  final String id;
  final String userId;
  final String establishmentId;
  final String name;
  final double latitude;
  final double longitude;
  final String? address;
  final String? phone;
  final List<DietaryFilter> dietaryOptions;
  final String? comment;
  final List<String> photoUrls;
  final bool isNewLocation;
  final DateTime createdAt;

  TrailRecord({
    required this.id,
    required this.userId,
    required this.establishmentId,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
    this.phone,
    required this.dietaryOptions,
    this.comment,
    required this.photoUrls,
    required this.isNewLocation,
    required this.createdAt,
  });

  factory TrailRecord.fromJson(Map<String, dynamic> json) {
    return TrailRecord(
      id: json['id'] as String,
      userId: json['userId'] as String,
      establishmentId: json['establishmentId'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      dietaryOptions: (json['dietaryOptions'] as List<dynamic>? ?? [])
          .map((e) => DietaryFilter.fromString(e as String))
          .toList(),
      comment: json['comment'] as String?,
      photoUrls: (json['photoUrls'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      isNewLocation: json['isNewLocation'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'establishmentId': establishmentId,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'phone': phone,
      'dietaryOptions': dietaryOptions.map((e) => e.toString().split('.').last).toList(),
      'comment': comment,
      'photoUrls': photoUrls,
      'isNewLocation': isNewLocation,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
