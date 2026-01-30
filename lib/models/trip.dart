import 'package:flutter/material.dart';
import 'establishment.dart';

/// Status de uma viagem
enum TripStatus {
  planning,   // Em planejamento
  upcoming,   // Próxima viagem
  ongoing,    // Em andamento
  completed,  // Concluída
  cancelled;  // Cancelada

  String get label {
    switch (this) {
      case TripStatus.planning:
        return 'Planejando';
      case TripStatus.upcoming:
        return 'Próxima';
      case TripStatus.ongoing:
        return 'Em andamento';
      case TripStatus.completed:
        return 'Concluída';
      case TripStatus.cancelled:
        return 'Cancelada';
    }
  }

  Color get color {
    switch (this) {
      case TripStatus.planning:
        return Colors.orange;
      case TripStatus.upcoming:
        return Colors.blue;
      case TripStatus.ongoing:
        return Colors.green;
      case TripStatus.completed:
        return Colors.grey;
      case TripStatus.cancelled:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case TripStatus.planning:
        return Icons.edit_calendar;
      case TripStatus.upcoming:
        return Icons.event;
      case TripStatus.ongoing:
        return Icons.flight_takeoff;
      case TripStatus.completed:
        return Icons.check_circle;
      case TripStatus.cancelled:
        return Icons.cancel;
    }
  }
}

/// Tipo de parada no itinerário
enum StopType {
  meal,        // Refeição
  snack,       // Lanche
  coffee,      // Café
  attraction,  // Atração turística
  hotel,       // Hospedagem
  transport,   // Transporte
  shopping,    // Compras
  other;       // Outro

  String get label {
    switch (this) {
      case StopType.meal:
        return 'Refeição';
      case StopType.snack:
        return 'Lanche';
      case StopType.coffee:
        return 'Café';
      case StopType.attraction:
        return 'Atração';
      case StopType.hotel:
        return 'Hospedagem';
      case StopType.transport:
        return 'Transporte';
      case StopType.shopping:
        return 'Compras';
      case StopType.other:
        return 'Outro';
    }
  }

  IconData get icon {
    switch (this) {
      case StopType.meal:
        return Icons.restaurant;
      case StopType.snack:
        return Icons.fastfood;
      case StopType.coffee:
        return Icons.local_cafe;
      case StopType.attraction:
        return Icons.attractions;
      case StopType.hotel:
        return Icons.hotel;
      case StopType.transport:
        return Icons.directions_car;
      case StopType.shopping:
        return Icons.shopping_bag;
      case StopType.other:
        return Icons.place;
    }
  }

  Color get color {
    switch (this) {
      case StopType.meal:
        return Colors.orange;
      case StopType.snack:
        return Colors.amber;
      case StopType.coffee:
        return Colors.brown;
      case StopType.attraction:
        return Colors.purple;
      case StopType.hotel:
        return Colors.indigo;
      case StopType.transport:
        return Colors.blue;
      case StopType.shopping:
        return Colors.pink;
      case StopType.other:
        return Colors.grey;
    }
  }
}

/// Uma parada no itinerário (pode ser um estabelecimento ou local customizado)
class TripStop {
  final String id;
  final String name;
  final String? description;
  final String? address;
  final double? latitude;
  final double? longitude;
  final StopType type;
  final String? establishmentId; // Se for um estabelecimento do app
  final String? imageUrl;
  final String? notes; // Notas pessoais do usuário
  final TimeOfDay? scheduledTime; // Horário planejado
  final int? estimatedDurationMinutes; // Duração estimada em minutos
  final bool isCompleted; // Se já foi visitado
  final List<String>? menuHighlights; // Destaques do cardápio (para restaurantes)
  final List<DietaryFilter>? dietaryOptions; // Opções dietéticas disponíveis
  final double? estimatedCost; // Custo estimado
  final String? phone;
  final String? website;
  final int order; // Ordem na lista do dia

  const TripStop({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.latitude,
    this.longitude,
    required this.type,
    this.establishmentId,
    this.imageUrl,
    this.notes,
    this.scheduledTime,
    this.estimatedDurationMinutes,
    this.isCompleted = false,
    this.menuHighlights,
    this.dietaryOptions,
    this.estimatedCost,
    this.phone,
    this.website,
    required this.order,
  });

  /// Cria uma parada a partir de um estabelecimento do app
  factory TripStop.fromEstablishment(Establishment establishment, {
    required int order,
    StopType? type,
    String? notes,
    TimeOfDay? scheduledTime,
    int? estimatedDurationMinutes,
  }) {
    // Determinar tipo baseado na categoria
    StopType stopType = type ?? _inferStopType(establishment.category);
    
    return TripStop(
      id: 'stop_${DateTime.now().millisecondsSinceEpoch}',
      name: establishment.name,
      description: establishment.category, // Usar categoria como descrição
      address: establishment.address,
      latitude: establishment.latitude,
      longitude: establishment.longitude,
      type: stopType,
      establishmentId: establishment.id,
      imageUrl: establishment.avatarUrl,
      notes: notes,
      scheduledTime: scheduledTime,
      estimatedDurationMinutes: estimatedDurationMinutes ?? 60,
      dietaryOptions: establishment.dietaryOptions,
      phone: establishment.phone,
      order: order,
    );
  }

  static StopType _inferStopType(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('restaurante') || cat.contains('restaurant')) return StopType.meal;
    if (cat.contains('café') || cat.contains('cafeteria') || cat.contains('coffee')) return StopType.coffee;
    if (cat.contains('lanche') || cat.contains('fast') || cat.contains('snack')) return StopType.snack;
    if (cat.contains('hotel') || cat.contains('pousada') || cat.contains('hostel')) return StopType.hotel;
    if (cat.contains('loja') || cat.contains('mercado') || cat.contains('shop')) return StopType.shopping;
    return StopType.meal;
  }

  TripStop copyWith({
    String? id,
    String? name,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    StopType? type,
    String? establishmentId,
    String? imageUrl,
    String? notes,
    TimeOfDay? scheduledTime,
    int? estimatedDurationMinutes,
    bool? isCompleted,
    List<String>? menuHighlights,
    List<DietaryFilter>? dietaryOptions,
    double? estimatedCost,
    String? phone,
    String? website,
    int? order,
  }) {
    return TripStop(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      type: type ?? this.type,
      establishmentId: establishmentId ?? this.establishmentId,
      imageUrl: imageUrl ?? this.imageUrl,
      notes: notes ?? this.notes,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      estimatedDurationMinutes: estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      menuHighlights: menuHighlights ?? this.menuHighlights,
      dietaryOptions: dietaryOptions ?? this.dietaryOptions,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'type': type.name,
      'establishmentId': establishmentId,
      'imageUrl': imageUrl,
      'notes': notes,
      'scheduledTime': scheduledTime != null 
          ? '${scheduledTime!.hour.toString().padLeft(2, '0')}:${scheduledTime!.minute.toString().padLeft(2, '0')}'
          : null,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'isCompleted': isCompleted,
      'menuHighlights': menuHighlights,
      'dietaryOptions': dietaryOptions?.map((d) => d.name).toList(),
      'estimatedCost': estimatedCost,
      'phone': phone,
      'website': website,
      'order': order,
    };
  }

  factory TripStop.fromJson(Map<String, dynamic> json) {
    TimeOfDay? time;
    if (json['scheduledTime'] != null) {
      final parts = (json['scheduledTime'] as String).split(':');
      if (parts.length == 2) {
        time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    }

    return TripStop(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      address: json['address'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      type: StopType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => StopType.other,
      ),
      establishmentId: json['establishmentId'],
      imageUrl: json['imageUrl'],
      notes: json['notes'],
      scheduledTime: time,
      estimatedDurationMinutes: json['estimatedDurationMinutes'],
      isCompleted: json['isCompleted'] ?? false,
      menuHighlights: (json['menuHighlights'] as List?)?.cast<String>(),
      dietaryOptions: (json['dietaryOptions'] as List?)?.map((d) {
        return DietaryFilter.values.firstWhere(
          (f) => f.name == d,
          orElse: () => DietaryFilter.celiac,
        );
      }).toList(),
      estimatedCost: (json['estimatedCost'] as num?)?.toDouble(),
      phone: json['phone'],
      website: json['website'],
      order: json['order'] ?? 0,
    );
  }
}

/// Um dia do itinerário
class TripDay {
  final String id;
  final DateTime date;
  final String? title; // Ex: "Dia 1 - Chegada em Curitiba"
  final String? description;
  final List<TripStop> stops;
  final String? accommodation; // Onde vai dormir
  final String? notes;
  final double? totalEstimatedCost;

  const TripDay({
    required this.id,
    required this.date,
    this.title,
    this.description,
    this.stops = const [],
    this.accommodation,
    this.notes,
    this.totalEstimatedCost,
  });

  /// Número do dia na viagem (1-indexed)
  int dayNumber(DateTime tripStartDate) {
    return date.difference(tripStartDate).inDays + 1;
  }

  /// Verifica se todos os stops foram completados
  bool get isCompleted => stops.isNotEmpty && stops.every((s) => s.isCompleted);

  /// Progresso do dia (0.0 a 1.0)
  double get progress {
    if (stops.isEmpty) return 0.0;
    return stops.where((s) => s.isCompleted).length / stops.length;
  }

  /// Custo total estimado do dia
  double get estimatedCost {
    if (totalEstimatedCost != null) return totalEstimatedCost!;
    return stops.fold(0.0, (sum, stop) => sum + (stop.estimatedCost ?? 0));
  }

  TripDay copyWith({
    String? id,
    DateTime? date,
    String? title,
    String? description,
    List<TripStop>? stops,
    String? accommodation,
    String? notes,
    double? totalEstimatedCost,
  }) {
    return TripDay(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      description: description ?? this.description,
      stops: stops ?? this.stops,
      accommodation: accommodation ?? this.accommodation,
      notes: notes ?? this.notes,
      totalEstimatedCost: totalEstimatedCost ?? this.totalEstimatedCost,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'title': title,
      'description': description,
      'stops': stops.map((s) => s.toJson()).toList(),
      'accommodation': accommodation,
      'notes': notes,
      'totalEstimatedCost': totalEstimatedCost,
    };
  }

  factory TripDay.fromJson(Map<String, dynamic> json) {
    return TripDay(
      id: json['id'] ?? '',
      date: _parseDateTime(json['date']),
      title: json['title'],
      description: json['description'],
      stops: (json['stops'] as List?)?.map((s) => TripStop.fromJson(s)).toList() ?? [],
      accommodation: json['accommodation'],
      notes: json['notes'],
      totalEstimatedCost: (json['totalEstimatedCost'] as num?)?.toDouble(),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    if (value.toString().contains('Timestamp')) {
      // Se for Timestamp do Firestore (mesmo que venha como objeto dinâmico)
      try {
        return (value as dynamic).toDate();
      } catch (_) {}
    }
    // Tentar reflexão ou acesso dinâmico se for Timestamp
    try {
      return value.toDate();
    } catch (_) {
      return DateTime.now();
    }
  }
}

/// Uma viagem/itinerário completo
class Trip {
  final String id;
  final String userId;
  final String name; // Ex: "Viagem a Curitiba"
  final String? description;
  final String? coverImageUrl;
  final DateTime startDate;
  final DateTime endDate;
  final TripStatus status;
  final List<TripDay> days;
  final List<String> destinations; // Cidades/destinos
  final List<String> companions; // IDs de companheiros de viagem
  final String? notes;
  final double? totalBudget;
  final bool isPublic; // Se outros usuários podem ver
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? preferences; // Preferências alimentares para a viagem

  const Trip({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.coverImageUrl,
    required this.startDate,
    required this.endDate,
    this.status = TripStatus.planning,
    this.days = const [],
    this.destinations = const [],
    this.companions = const [],
    this.notes,
    this.totalBudget,
    this.isPublic = false,
    required this.createdAt,
    this.updatedAt,
    this.preferences,
  });

  /// Duração em dias
  int get durationDays => endDate.difference(startDate).inDays + 1;

  /// Total de paradas
  int get totalStops => days.fold(0, (sum, day) => sum + day.stops.length);

  /// Progresso geral da viagem (0.0 a 1.0)
  double get progress {
    if (days.isEmpty) return 0.0;
    final totalStopsCount = totalStops;
    if (totalStopsCount == 0) return 0.0;
    final completedStops = days.fold(0, (sum, day) => sum + day.stops.where((s) => s.isCompleted).length);
    return completedStops / totalStopsCount;
  }

  /// Custo total estimado
  double get estimatedTotalCost {
    if (totalBudget != null) return totalBudget!;
    return days.fold(0.0, (sum, day) => sum + day.estimatedCost);
  }

  /// Verifica se a viagem está em andamento
  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate.add(const Duration(days: 1)));
  }

  /// Dia atual da viagem (se estiver em andamento)
  TripDay? get currentDay {
    if (!isOngoing) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return days.firstWhere(
      (day) => DateTime(day.date.year, day.date.month, day.date.day) == today,
      orElse: () => days.first,
    );
  }

  Trip copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? coverImageUrl,
    DateTime? startDate,
    DateTime? endDate,
    TripStatus? status,
    List<TripDay>? days,
    List<String>? destinations,
    List<String>? companions,
    String? notes,
    double? totalBudget,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? preferences,
  }) {
    return Trip(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      days: days ?? this.days,
      destinations: destinations ?? this.destinations,
      companions: companions ?? this.companions,
      notes: notes ?? this.notes,
      totalBudget: totalBudget ?? this.totalBudget,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      preferences: preferences ?? this.preferences,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'coverImageUrl': coverImageUrl,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status.name,
      'days': days.map((d) => d.toJson()).toList(),
      'destinations': destinations,
      'companions': companions,
      'notes': notes,
      'totalBudget': totalBudget,
      'isPublic': isPublic,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'preferences': preferences,
    };
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      coverImageUrl: json['coverImageUrl'],
      startDate: _parseDateTime(json['startDate']),
      endDate: _parseDateTime(json['endDate']),
      status: TripStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => TripStatus.planning,
      ),
      days: (json['days'] as List?)?.map((d) => TripDay.fromJson(d)).toList() ?? [],
      destinations: (json['destinations'] as List?)?.cast<String>() ?? [],
      companions: (json['companions'] as List?)?.cast<String>() ?? [],
      notes: json['notes'],
      totalBudget: (json['totalBudget'] as num?)?.toDouble(),
      isPublic: json['isPublic'] ?? false,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: json['updatedAt'] != null 
          ? _parseDateTime(json['updatedAt']) 
          : null,
      preferences: json['preferences'],
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    // Tentar converter Timestamp do Firestore
    try {
      return value.toDate();
    } catch (_) {
      return DateTime.now();
    }
  }
}
