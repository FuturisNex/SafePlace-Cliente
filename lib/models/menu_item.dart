import 'package:flutter/material.dart';

import 'establishment.dart'; // Para usar DietaryFilter

/// Dias da semana para disponibilidade
enum WeekDay {
  sunday,    // 0
  monday,    // 1
  tuesday,   // 2
  wednesday, // 3
  thursday,  // 4
  friday,    // 5
  saturday,  // 6
}

extension WeekDayExtension on WeekDay {
  int get value => index;
  
  String get label {
    switch (this) {
      case WeekDay.sunday: return 'Domingo';
      case WeekDay.monday: return 'Segunda';
      case WeekDay.tuesday: return 'Terça';
      case WeekDay.wednesday: return 'Quarta';
      case WeekDay.thursday: return 'Quinta';
      case WeekDay.friday: return 'Sexta';
      case WeekDay.saturday: return 'Sábado';
    }
  }
  
  String get shortLabel {
    switch (this) {
      case WeekDay.sunday: return 'Dom';
      case WeekDay.monday: return 'Seg';
      case WeekDay.tuesday: return 'Ter';
      case WeekDay.wednesday: return 'Qua';
      case WeekDay.thursday: return 'Qui';
      case WeekDay.friday: return 'Sex';
      case WeekDay.saturday: return 'Sáb';
    }
  }
  
  static WeekDay fromInt(int value) {
    return WeekDay.values[value.clamp(0, 6)];
  }
  
  static WeekDay today() {
    final now = DateTime.now();
    // DateTime.weekday: 1=segunda, ..., 7=domingo
    // WeekDay: 0=domingo, 1=segunda, ..., 6=sábado
    return WeekDay.values[now.weekday == 7 ? 0 : now.weekday];
  }
}

class MenuItem {
  final String id;
  final String establishmentId;
  final String name;
  final String? description;
  final double price;
  final List<DietaryFilter> dietaryOptions;
  final bool isAvailable;
  final String imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  /// Dias da semana em que o item está disponível (null = todos os dias)
  /// Lista de inteiros: 0=domingo, 1=segunda, ..., 6=sábado
  final List<int>? availableDays;
  
  /// Verifica se o item está disponível hoje
  bool get isAvailableToday {
    if (!isAvailable) return false;
    if (availableDays == null || availableDays!.isEmpty) return true;
    
    final today = WeekDayExtension.today();
    return availableDays!.contains(today.value);
  }
  
  /// Retorna os dias disponíveis como lista de WeekDay
  List<WeekDay> get availableWeekDays {
    if (availableDays == null || availableDays!.isEmpty) {
      return WeekDay.values; // Todos os dias
    }
    return availableDays!.map((d) => WeekDayExtension.fromInt(d)).toList();
  }

  MenuItem({
    required this.id,
    required this.establishmentId,
    required this.name,
    this.description,
    required this.price,
    List<DietaryFilter>? dietaryOptions,
    this.isAvailable = true,
    this.imageUrl = '',
    this.createdAt,
    this.updatedAt,
    this.availableDays,
  }) : dietaryOptions = dietaryOptions ?? const [];

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    final rawDietary = json['dietaryOptions'] as List<dynamic>?;
    final dietaryOptions = rawDietary
            ?.map((e) => DietaryFilter.fromString(e as String))
            .toList() ??
        const <DietaryFilter>[];

    DateTime? createdAt;
    if (json['createdAt'] != null) {
      try {
        createdAt = DateTime.parse(json['createdAt'] as String);
      } catch (_) {}
    }

    DateTime? updatedAt;
    if (json['updatedAt'] != null) {
      try {
        updatedAt = DateTime.parse(json['updatedAt'] as String);
      } catch (_) {}
    }

    // Parse availableDays
    List<int>? availableDays;
    if (json['availableDays'] != null) {
      availableDays = (json['availableDays'] as List<dynamic>)
          .map((e) => e as int)
          .toList();
    }

    return MenuItem(
      id: json['id'] as String,
      establishmentId: json['establishmentId'] as String? ?? '',
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      dietaryOptions: dietaryOptions,
      isAvailable: json['isAvailable'] as bool? ?? true,
      imageUrl: json['imageUrl'] as String? ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
      availableDays: availableDays,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'establishmentId': establishmentId,
      'name': name,
      'description': description,
      'price': price,
      'dietaryOptions': dietaryOptions.map((e) => e.toString()).toList(),
      'isAvailable': isAvailable,
      'imageUrl': imageUrl,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      if (availableDays != null) 'availableDays': availableDays,
    };
  }
  
  /// Cria uma cópia do item com os campos alterados
  MenuItem copyWith({
    String? id,
    String? establishmentId,
    String? name,
    String? description,
    double? price,
    List<DietaryFilter>? dietaryOptions,
    bool? isAvailable,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<int>? availableDays,
  }) {
    return MenuItem(
      id: id ?? this.id,
      establishmentId: establishmentId ?? this.establishmentId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      dietaryOptions: dietaryOptions ?? this.dietaryOptions,
      isAvailable: isAvailable ?? this.isAvailable,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      availableDays: availableDays ?? this.availableDays,
    );
  }
}
