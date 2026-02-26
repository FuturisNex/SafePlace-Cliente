import 'package:flutter/material.dart';
import '../utils/translations.dart';

/// Horário de funcionamento para um dia específico
class DaySchedule {
  final String? openingTime;  // HH:mm ou null se fechado
  final String? closingTime;  // HH:mm ou null se fechado
  final bool isClosed;        // Se está fechado neste dia
  
  const DaySchedule({
    this.openingTime,
    this.closingTime,
    this.isClosed = false,
  });
  
  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    return DaySchedule(
      openingTime: json['openingTime'] as String?,
      closingTime: json['closingTime'] as String?,
      isClosed: json['isClosed'] as bool? ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'openingTime': openingTime,
      'closingTime': closingTime,
      'isClosed': isClosed,
    };
  }
  
  /// Verifica se está aberto no horário atual
  bool isOpenNow() {
    if (isClosed || openingTime == null || closingTime == null) return false;
    
    final now = DateTime.now();
    final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);
    
    final opening = _parseTime(openingTime!);
    final closing = _parseTime(closingTime!);
    
    if (opening == null || closing == null) return true;
    
    // Se o horário de fechamento é menor que o de abertura, significa que fecha no dia seguinte
    if (closing.hour < opening.hour || 
        (closing.hour == opening.hour && closing.minute < opening.minute)) {
      return _isAfter(currentTime, opening) || _isBefore(currentTime, closing);
    } else {
      return _isAfter(currentTime, opening) && _isBefore(currentTime, closing);
    }
  }
  
  static TimeOfDay? _parseTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length == 2) {
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    } catch (_) {}
    return null;
  }
  
  static bool _isAfter(TimeOfDay time, TimeOfDay other) {
    if (time.hour > other.hour) return true;
    if (time.hour < other.hour) return false;
    return time.minute >= other.minute;
  }
  
  static bool _isBefore(TimeOfDay time, TimeOfDay other) {
    if (time.hour < other.hour) return true;
    if (time.hour > other.hour) return false;
    return time.minute <= other.minute;
  }
  
  String get displayText {
    if (isClosed) return 'Fechado';
    if (openingTime == null || closingTime == null) return 'Não definido';
    return '$openingTime - $closingTime';
  }
  
  DaySchedule copyWith({
    String? openingTime,
    String? closingTime,
    bool? isClosed,
  }) {
    return DaySchedule(
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      isClosed: isClosed ?? this.isClosed,
    );
  }
}

/// Horários de funcionamento por dia da semana
/// Chaves: 0=domingo, 1=segunda, ..., 6=sábado
class WeeklySchedule {
  final Map<int, DaySchedule> schedule;
  
  const WeeklySchedule({this.schedule = const {}});
  
  factory WeeklySchedule.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const WeeklySchedule();
    
    final schedule = <int, DaySchedule>{};
    json.forEach((key, value) {
      final dayIndex = int.tryParse(key);
      if (dayIndex != null && value is Map<String, dynamic>) {
        schedule[dayIndex] = DaySchedule.fromJson(value);
      }
    });
    return WeeklySchedule(schedule: schedule);
  }
  
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    schedule.forEach((key, value) {
      json[key.toString()] = value.toJson();
    });
    return json;
  }
  
  /// Retorna o horário para um dia específico
  DaySchedule? getSchedule(int dayOfWeek) => schedule[dayOfWeek];
  
  /// Verifica se tem horário personalizado para algum dia
  bool get hasCustomSchedule => schedule.isNotEmpty;
  
  /// Retorna o horário de hoje
  DaySchedule? get todaySchedule {
    final now = DateTime.now();
    final dayOfWeek = now.weekday == 7 ? 0 : now.weekday;
    return schedule[dayOfWeek];
  }
  
  /// Verifica se está aberto agora baseado no horário do dia
  bool isOpenNow() {
    final today = todaySchedule;
    if (today == null) return true; // Se não tem horário definido, assume aberto
    return today.isOpenNow();
  }
  
  WeeklySchedule copyWith({Map<int, DaySchedule>? schedule}) {
    return WeeklySchedule(schedule: schedule ?? this.schedule);
  }
  
  /// Nomes dos dias da semana
  static const List<String> dayNames = [
    'Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'
  ];
  
  static const List<String> shortDayNames = [
    'Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'
  ];
}


class Establishment {
  final String id;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final double distance; // em km
  final String avatarUrl;
  final List<String> photoUrls;
  final DifficultyLevel difficultyLevel;
  final List<DietaryFilter> dietaryOptions;
  bool get isOpen {
    // Prioridade 1: Horário personalizado por dia da semana
    if (weeklySchedule != null && weeklySchedule!.hasCustomSchedule) {
      final todaySchedule = weeklySchedule!.todaySchedule;
      if (todaySchedule != null) {
        return todaySchedule.isOpenNow();
      }
    }
    
    // Prioridade 2: Horário padrão + dias de funcionamento
    if (openingTime != null && closingTime != null && openingDays != null && openingDays!.isNotEmpty) {
      return calculateIsOpen(openingTime!, closingTime!, openingDays!, weekendOpeningTime, weekendClosingTime);
    }
    
    // Prioridade 3: Apenas horário padrão
    if (openingTime != null && closingTime != null) {
      return calculateIsOpen(openingTime!, closingTime!, null, weekendOpeningTime, weekendClosingTime);
    }
    
    // Fallback: usar o valor salvo
    return _isOpen;
  }
  
  /// Retorna o horário de funcionamento de hoje formatado
  String get todayScheduleText {
    // Prioridade 1: Horário personalizado
    if (weeklySchedule != null && weeklySchedule!.hasCustomSchedule) {
      final todaySchedule = weeklySchedule!.todaySchedule;
      if (todaySchedule != null) {
        return todaySchedule.displayText;
      }
    }
    
    // Prioridade 2: Horário de fim de semana
    final now = DateTime.now();
    final dayOfWeek = now.weekday == 7 ? 0 : now.weekday;
    final isWeekend = dayOfWeek == 0 || dayOfWeek == 6;
    
    if (isWeekend && weekendOpeningTime != null && weekendClosingTime != null) {
      return '$weekendOpeningTime - $weekendClosingTime';
    }
    
    // Prioridade 3: Horário padrão
    if (openingTime != null && closingTime != null) {
      return '$openingTime - $closingTime';
    }
    
    return 'Não definido';
  }
  
  final bool _isOpen; // Valor salvo (usado como fallback)
  final String? ownerId; // ID do dono da empresa (se for empresa)
  final String? address; // Endereço completo
  final String? phone; // Telefone de contato do estabelecimento (com DDD)
  final String? openingTime; // Horário de abertura dias de semana (HH:mm) - padrão
  final String? closingTime; // Horário de fechamento dias de semana (HH:mm) - padrão
  final String? weekendOpeningTime; // Horário de abertura fim de semana (HH:mm) - opcional
  final String? weekendClosingTime; // Horário de fechamento fim de semana (HH:mm) - opcional
  final List<int>? openingDays; // Dias da semana que está aberto (0=domingo, 1=segunda, ..., 6=sábado)
  final WeeklySchedule? weeklySchedule; // Horários personalizados por dia da semana (opcional)
  final TechnicalCertificationStatus certificationStatus;
  final DateTime? lastInspectionDate;
  final String? lastInspectionStatus;
  final bool isBoosted;
  final DateTime? boostExpiresAt;
  final double? boostScore; // Score efetivo do boost (para ordenação no leilão)
  final String? boostCampaignId; // ID da campanha de boost ativa

  // Localização hierárquica
  final String? state;        // "São Paulo", "Paraná"  
  final String? city;         // "São Paulo", "Curitiba"
  final String? neighborhood; // "Vila Mariana", "Batel"

  // Delivery
  final bool hasDelivery;           // Se oferece delivery
  final double? deliveryFee;        // Taxa de entrega (null = grátis)
  final int? deliveryTimeMin;       // Tempo mínimo de entrega em minutos
  final int? deliveryTimeMax;       // Tempo máximo de entrega em minutos
  final double? minOrderValue;      // Valor mínimo do pedido
  final double? deliveryRadius;     // Raio de entrega em km
  final double? rating;             // Avaliação média (0-5)
  final int? ratingCount;           // Quantidade de avaliações

    Establishment({
      required this.id,
      required this.name,
      required this.category,
      required this.latitude,
      required this.longitude,
      required this.distance,
      required this.avatarUrl,
      List<String>? photoUrls,
      required this.difficultyLevel,
      required this.dietaryOptions,
      required bool isOpen,
      this.ownerId,
      this.address,
      this.phone,
      this.openingTime,
      this.closingTime,
      this.weekendOpeningTime,
      this.weekendClosingTime,
      this.openingDays,
      this.weeklySchedule,
      this.certificationStatus = TechnicalCertificationStatus.none,
      this.lastInspectionDate,
      this.lastInspectionStatus,
      this.isBoosted = false,
      this.boostExpiresAt,
      this.boostScore,
      this.boostCampaignId,
      this.state,
      this.city,
      this.neighborhood,
      this.hasDelivery = false,
      this.deliveryFee,
      this.deliveryTimeMin,
      this.deliveryTimeMax,
      this.minOrderValue,
      this.deliveryRadius,
      this.rating,
      this.ratingCount,
    })  : photoUrls = photoUrls ?? const [],
      _isOpen = isOpen;

  factory Establishment.fromJson(Map<String, dynamic> json) {
    // Calcular isOpen baseado no horário e dias se disponível
    bool calculatedIsOpen = json['isOpen'] as bool? ?? true;
    final openingDays = json['openingDays'] != null 
        ? (json['openingDays'] as List<dynamic>).map((e) => e as int).toList()
        : null;
    final weekendOpeningTime = json['weekendOpeningTime'] as String?;
    final weekendClosingTime = json['weekendClosingTime'] as String?;
    
    // Parse weeklySchedule se existir
    final weeklySchedule = json['weeklySchedule'] != null
        ? WeeklySchedule.fromJson(json['weeklySchedule'] as Map<String, dynamic>)
        : null;
    
    if (json['openingTime'] != null && json['closingTime'] != null) {
      calculatedIsOpen = calculateIsOpen(
        json['openingTime'] as String,
        json['closingTime'] as String,
        openingDays,
        weekendOpeningTime,
        weekendClosingTime,
      );
    }
    final lastInspectionDate = json['lastInspectionDate'] != null
        ? DateTime.parse(json['lastInspectionDate'] as String)
        : null;
    final lastInspectionStatus = json['lastInspectionStatus'] as String?;
    final isBoosted = json['isBoosted'] as bool? ?? false;
    final boostExpiresAt = json['boostExpiresAt'] != null
        ? (json['boostExpiresAt'] is int 
            ? DateTime.fromMillisecondsSinceEpoch(json['boostExpiresAt'] as int)
            : DateTime.parse(json['boostExpiresAt'] as String)) // Assuming string if not int
        : null;
    final boostScore = (json['boostScore'] as num?)?.toDouble();
    final boostCampaignId = json['boostCampaignId'] as String?;

    final List<String> photoUrls = (json['photoUrls'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];
    String avatarUrl = json['avatarUrl'] as String? ?? '';
    if (avatarUrl.isEmpty && photoUrls.isNotEmpty) {
      avatarUrl = photoUrls.first;
    }
    
    return Establishment(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      avatarUrl: avatarUrl,
      photoUrls: photoUrls,
      difficultyLevel: DifficultyLevel.fromString(json['difficultyLevel'] as String? ?? 'popular'),
      dietaryOptions: (json['dietaryOptions'] as List<dynamic>?)
              ?.map((e) => DietaryFilter.fromString(e as String))
              .toList() ??
          [],
      isOpen: calculatedIsOpen,
      ownerId: json['ownerId'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      openingTime: json['openingTime'] as String?,
      closingTime: json['closingTime'] as String?,
      weekendOpeningTime: weekendOpeningTime,
      certificationStatus: TechnicalCertificationStatus.fromString(
        json['certificationStatus'] as String? ?? 'none',
      ),
      lastInspectionDate: lastInspectionDate,
      lastInspectionStatus: lastInspectionStatus,
      isBoosted: isBoosted,
      boostScore: boostScore,
      boostCampaignId: boostCampaignId,
      state: json['state'] as String?,
      city: json['city'] as String?,
      neighborhood: json['neighborhood'] as String?,
      hasDelivery: json['hasDelivery'] as bool? ?? false,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble(),
      deliveryTimeMin: json['deliveryTimeMin'] as int?,
      deliveryTimeMax: json['deliveryTimeMax'] as int?,
      minOrderValue: (json['minOrderValue'] as num?)?.toDouble(),
      deliveryRadius: (json['deliveryRadius'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble(),
      ratingCount: json['ratingCount'] as int?,
    );
  }
  
  /// Calcula se o estabelecimento está aberto baseado no horário atual
  static bool calculateIsOpen(
    String openingTime, 
    String closingTime, [
    List<int>? openingDays,
    String? weekendOpeningTime,
    String? weekendClosingTime,
  ]) {
    try {
      final now = DateTime.now();
      final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);
      // DateTime.weekday: 1=segunda, 2=terça, ..., 7=domingo
      // Converter para: 0=domingo, 1=segunda, ..., 6=sábado
      final currentDayOfWeek = now.weekday == 7 ? 0 : now.weekday;
      
      // Verificar se está aberto no dia da semana
      if (openingDays != null && openingDays.isNotEmpty) {
        if (!openingDays.contains(currentDayOfWeek)) {
          return false; // Não está aberto neste dia da semana
        }
      }
      // Determinar se é fim de semana (sábado=6, domingo=0)
      final isWeekend = currentDayOfWeek == 0 || currentDayOfWeek == 6;
      
      // Usar horário de fim de semana se disponível e for fim de semana
      String effectiveOpeningTime = openingTime;
      String effectiveClosingTime = closingTime;
      
      if (isWeekend && weekendOpeningTime != null && weekendClosingTime != null) {
        effectiveOpeningTime = weekendOpeningTime;
        effectiveClosingTime = weekendClosingTime;
      }
      
      final opening = _parseTime(effectiveOpeningTime);
      final closing = _parseTime(effectiveClosingTime);
      
      if (opening == null || closing == null) return true;
      
      // Se o horário de fechamento é menor que o de abertura, significa que fecha no dia seguinte
      if (closing.hour < opening.hour || 
          (closing.hour == opening.hour && closing.minute < opening.minute)) {
        // Está aberto se está depois da abertura OU antes do fechamento
        return _isAfter(currentTime, opening) || _isBefore(currentTime, closing);
      } else {
        // Está aberto se está entre abertura e fechamento
        return _isAfter(currentTime, opening) && _isBefore(currentTime, closing);
      }
    } catch (e) {
      return true; // Em caso de erro, assume que está aberto
    }
    return true; // Garantir retorno booleano
  }
  
  static TimeOfDay? _parseTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length == 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (e) {
      return null;
    }
    return null;
  }
  
  static bool _isAfter(TimeOfDay time, TimeOfDay other) {
    if (time.hour > other.hour) return true;
    if (time.hour < other.hour) return false;
    return time.minute >= other.minute;
  }
  
  static bool _isBefore(TimeOfDay time, TimeOfDay other) {
    if (time.hour < other.hour) return true;
    if (time.hour > other.hour) return false;
    return time.minute <= other.minute;
  }

  Map<String, dynamic> toJson() {
    // isOpen já é calculado dinamicamente pelo getter
    return {
      'id': id,
      'name': name,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'avatarUrl': avatarUrl,
      'photoUrls': photoUrls,
      'difficultyLevel': difficultyLevel.toString(),
      'dietaryOptions': dietaryOptions.map((e) => e.toString()).toList(),
      'isOpen': isOpen, // Já calculado dinamicamente pelo getter
      'ownerId': ownerId,
      'address': address,
      'phone': phone,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'weekendOpeningTime': weekendOpeningTime,
      'weekendClosingTime': weekendClosingTime,
      'openingDays': openingDays,
      if (weeklySchedule != null) 'weeklySchedule': weeklySchedule!.toJson(),
      'certificationStatus': certificationStatus.toString().split('.').last,
      'lastInspectionDate': lastInspectionDate?.toIso8601String(),
      'lastInspectionStatus': lastInspectionStatus,
      'isBoosted': isBoosted,
      'boostExpiresAt': boostExpiresAt?.toIso8601String(),
      'state': state,
      'city': city,
      'neighborhood': neighborhood,
      'hasDelivery': hasDelivery,
      'deliveryFee': deliveryFee,
      'deliveryTimeMin': deliveryTimeMin,
      'deliveryTimeMax': deliveryTimeMax,
      'minOrderValue': minOrderValue,
      'deliveryRadius': deliveryRadius,
      'rating': rating,
      'ratingCount': ratingCount,
    };
  }

  /// Retorna o tempo de entrega formatado (ex: "30-45 min")
  String get deliveryTimeFormatted {
    if (deliveryTimeMin == null && deliveryTimeMax == null) return '';
    if (deliveryTimeMin != null && deliveryTimeMax != null) {
      return '$deliveryTimeMin-$deliveryTimeMax min';
    }
    return '${deliveryTimeMin ?? deliveryTimeMax} min';
  }

  /// Retorna se a entrega é grátis
  bool get isFreeDelivery => deliveryFee == null || deliveryFee == 0;

  /// Retorna a taxa de entrega formatada
  String get deliveryFeeFormatted {
    if (isFreeDelivery) return 'Grátis';
    return 'R\$ ${deliveryFee!.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}

enum DifficultyLevel {
  popular,
  intermediate,
  technical;

  String getLabel(BuildContext? context) {
    if (context == null) {
      // Fallback sem contexto
      switch (this) {
        case DifficultyLevel.popular:
          return 'Popular';
        case DifficultyLevel.intermediate:
          return 'Intermediário';
        case DifficultyLevel.technical:
          return 'Técnico';
      }
    }
    
    // Usar o sistema de traduções
    switch (this) {
      case DifficultyLevel.popular:
        return Translations.getText(context, 'difficultyPopular');
      case DifficultyLevel.intermediate:
        return Translations.getText(context, 'difficultyIntermediate');
      case DifficultyLevel.technical:
        return Translations.getText(context, 'difficultyTechnical');
    }
  }

  @Deprecated('Use getLabel(context) instead')
  String get label {
    switch (this) {
      case DifficultyLevel.popular:
        return 'Popular';
      case DifficultyLevel.intermediate:
        return 'Intermediário';
      case DifficultyLevel.technical:
        return 'Técnico';
    }
  }

  Color get color {
    switch (this) {
      case DifficultyLevel.popular:
        return Colors.green;
      case DifficultyLevel.intermediate:
        return Colors.blue;
      case DifficultyLevel.technical:
        return Colors.orange;
    }
  }

  static DifficultyLevel fromString(String value) {
    return DifficultyLevel.values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => DifficultyLevel.popular,
    );
  }
}

enum TechnicalCertificationStatus {
  none,
  pending,
  scheduled,
  certified;

  String getLabel(BuildContext? context) {
    if (context == null) {
      switch (this) {
        case TechnicalCertificationStatus.none:
          return 'Sem certificação';
        case TechnicalCertificationStatus.pending:
          return 'Solicitada (pendente)';
        case TechnicalCertificationStatus.scheduled:
          return 'Agendada';
        case TechnicalCertificationStatus.certified:
          return 'Certificado';
      }
    }

    switch (this) {
      case TechnicalCertificationStatus.none:
        return Translations.getText(context!, 'certificationStatusNone');
      case TechnicalCertificationStatus.pending:
        return Translations.getText(context!, 'certificationStatusPending');
      case TechnicalCertificationStatus.scheduled:
        return Translations.getText(context!, 'certificationStatusScheduled');
      case TechnicalCertificationStatus.certified:
        return Translations.getText(context!, 'certificationStatusCertified');
    }
  }

  static TechnicalCertificationStatus fromString(String value) {
    return TechnicalCertificationStatus.values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => TechnicalCertificationStatus.none,
    );
  }
}

/// Helper para traduzir categorias de estabelecimentos
class CategoryTranslator {
  static String translate(BuildContext? context, String category) {
    if (context == null) {
      return category; // Fallback sem contexto
    }
    
    final categoryLower = category.toLowerCase().trim();
    
    // Mapear todas as variações possíveis de categorias
    // Restaurant / Restaurante
    if (categoryLower == 'restaurant' || 
        categoryLower == 'restaurante' || 
        categoryLower.contains('restaurant') || 
        categoryLower.contains('restaurante')) {
      return Translations.getText(context, 'categoryRestaurant');
    } 
    // Bakery / Padaria / Panadería
    else if (categoryLower == 'bakery' || 
             categoryLower == 'padaria' || 
             categoryLower == 'panadería' ||
             categoryLower == 'panaderia' ||
             categoryLower == 'confeitaria' ||
             categoryLower.contains('bakery') || 
             categoryLower.contains('padaria') || 
             categoryLower.contains('panadería') ||
             categoryLower.contains('panaderia') ||
             categoryLower.contains('confeitaria')) {
      return Translations.getText(context, 'categoryBakery');
    } 
    // Hotel / Pousada
    else if (categoryLower == 'hotel' || 
             categoryLower == 'pousada' || 
             categoryLower.contains('hotel') || 
             categoryLower.contains('pousada')) {
      return Translations.getText(context, 'categoryHotel');
    } 
    // Cafe / Café
    else if (categoryLower == 'cafe' || 
             categoryLower == 'café' || 
             categoryLower == 'cafe' ||
             categoryLower.contains('cafe') || 
             categoryLower.contains('café')) {
      return Translations.getText(context, 'categoryCafe');
    } 
    // Market / Mercado
    else if (categoryLower == 'market' || 
             categoryLower == 'mercado' || 
             categoryLower.contains('market') || 
             categoryLower.contains('mercado')) {
      return Translations.getText(context, 'categoryMarket');
    } 
    // Outro / Other
    else {
      // Se não encontrar correspondência, retornar a categoria original
      // ou tentar traduzir se já estiver em um idioma conhecido
      return category;
    }
  }
}

enum DietaryFilter {
  celiac,
  lactoseFree,
  aplv,
  eggFree,
  nutFree,
  oilseedFree,
  soyFree,
  sugarFree,
  diabetic,
  vegan,
  vegetarian,
  halal;

  String getLabel(BuildContext? context) {
    if (context == null) {
      // Fallback sem contexto
      switch (this) {
        case DietaryFilter.celiac:
          return 'Celíaco';
        case DietaryFilter.lactoseFree:
          return 'Sem Lactose';
        case DietaryFilter.aplv:
          return 'APLV';
        case DietaryFilter.eggFree:
          return 'Sem Ovo';
        case DietaryFilter.nutFree:
          return 'Sem Amendoim';
        case DietaryFilter.oilseedFree:
          return 'Sem Oleaginosas';
        case DietaryFilter.soyFree:
          return 'Sem Soja';
        case DietaryFilter.sugarFree:
          return 'Sem Açúcar';
        case DietaryFilter.diabetic:
          return 'Adequado para diabéticos';
        case DietaryFilter.vegan:
          return 'Vegano';
        case DietaryFilter.vegetarian:
          return 'Vegetariano';
        case DietaryFilter.halal:
          return 'Halal';
      }
    }
    
    // Usar o sistema de traduções
    switch (this) {
      case DietaryFilter.celiac:
        return Translations.getText(context, 'dietaryCeliac');
      case DietaryFilter.lactoseFree:
        return Translations.getText(context, 'dietaryLactoseFree');
      case DietaryFilter.aplv:
        return Translations.getText(context, 'dietaryAPLV');
      case DietaryFilter.eggFree:
        return Translations.getText(context, 'dietaryEggFree');
      case DietaryFilter.nutFree:
        return Translations.getText(context, 'dietaryNutFree');
      case DietaryFilter.oilseedFree:
        return Translations.getText(context, 'dietaryOilseedFree');
      case DietaryFilter.soyFree:
        return Translations.getText(context, 'dietarySoyFree');
      case DietaryFilter.sugarFree:
        return Translations.getText(context, 'dietarySugarFree');
      case DietaryFilter.diabetic:
        return Translations.getText(context, 'dietaryDiabetic');
      case DietaryFilter.vegan:
        return Translations.getText(context, 'dietaryVegan');
      case DietaryFilter.vegetarian:
        return Translations.getText(context, 'dietaryVegetarian');
      case DietaryFilter.halal:
        return Translations.getText(context, 'dietaryHalal');
    }
  }
  
  @Deprecated('Use getLabel(context) instead')
  String get label {
    switch (this) {
      case DietaryFilter.celiac:
        return 'Celíaco';
      case DietaryFilter.lactoseFree:
        return 'Sem Lactose';
      case DietaryFilter.aplv:
        return 'APLV';
      case DietaryFilter.eggFree:
        return 'Sem Ovo';
      case DietaryFilter.nutFree:
        return 'Sem Amendoim';
      case DietaryFilter.oilseedFree:
        return 'Sem Oleaginosas';
      case DietaryFilter.soyFree:
        return 'Sem Soja';
      case DietaryFilter.sugarFree:
        return 'Sem Açúcar';
      case DietaryFilter.diabetic:
        return 'Adequado para diabéticos';
      case DietaryFilter.vegan:
        return 'Vegano';
      case DietaryFilter.vegetarian:
        return 'Vegetariano';
      case DietaryFilter.halal:
        return 'Halal';
    }
  }

  static DietaryFilter fromString(String value) {
    // Remover o namespace se existir (DietaryFilter.celiac -> celiac)
    final cleanValue = value.split('.').last.trim();
    
    try {
      return DietaryFilter.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == cleanValue.toLowerCase(),
      );
    } catch (e) {
      // Se não encontrar, tentar correspondência direta pelo name
      try {
        return DietaryFilter.values.firstWhere(
          (e) => e.name.toLowerCase() == cleanValue.toLowerCase(),
        );
      } catch (e) {
        // Log do erro para debug
        print('DietaryFilter.fromString: Valor não reconhecido: "$value" (cleanValue: "$cleanValue")');
        // Retorna celiac como último recurso
        return DietaryFilter.celiac;
      }
    }
  }
}
