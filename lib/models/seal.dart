import 'package:flutter/material.dart';

class Seal {
  final String id;
  final String name;
  final String description;
  final SealLevel level;
  final String? imageUrl;

  Seal({
    required this.id,
    required this.name,
    required this.description,
    required this.level,
    this.imageUrl,
  });

  factory Seal.fromJson(Map<String, dynamic> json) {
    return Seal(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      level: SealLevel.fromString(json['level'] as String),
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'level': level.toString().split('.').last,
      'imageUrl': imageUrl,
    };
  }
}

enum SealLevel {
  bronze,
  silver,
  gold,
  platinum;

  String get label {
    switch (this) {
      case SealLevel.bronze:
        return 'Bronze';
      case SealLevel.silver:
        return 'Prata';
      case SealLevel.gold:
        return 'Ouro';
      case SealLevel.platinum:
        return 'Platina';
    }
  }

  Color get color {
    switch (this) {
      case SealLevel.bronze:
        return const Color(0xFFCD7F32);
      case SealLevel.silver:
        return Colors.grey;
      case SealLevel.gold:
        return Colors.amber;
      case SealLevel.platinum:
        return const Color(0xFFE5E4E2);
    }
  }

  static SealLevel fromString(String value) {
    return SealLevel.values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => SealLevel.bronze,
    );
  }
}

