import 'user_seal.dart';

enum UserType {
  user,
  business;

  String get label {
    switch (this) {
      case UserType.user:
        return 'Usuário';
      case UserType.business:
        return 'Empresa';
    }
  }
}

class User {
  final String id;
  final String email;
  final String? name;
  final UserType type;
  final String? photoUrl;
  final String? coverPhotoUrl;
  final String? preferredLanguage; // Idioma preferido do usuário (pt, en, es)
  final String? phone; // Telefone de contato do usuário (com DDD)
  
  // Sistema de gamificação
  final int points; // Pontuação acumulada
  final UserSeal seal; // Selo atual (Bronze, Prata, Ouro)
  final int totalCheckIns; // Total de check-ins realizados
  final int totalReviews; // Total de avaliações realizadas
  final int totalReferrals; // Total de indicações de novos locais
  final int followersCount; // Total de seguidores
  final int followingCount; // Total de perfis seguidos
  final List<String> dietaryPreferences;
  final DateTime createdAt; // Data de cadastro

  User({
    required this.id,
    required this.email,
    this.name,
    required this.type,
    this.photoUrl,
    this.coverPhotoUrl,
    this.preferredLanguage,
    this.phone,
    this.points = 0,
    this.seal = UserSeal.bronze,
    this.totalCheckIns = 0,
    this.totalReviews = 0,
    this.totalReferrals = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.dietaryPreferences = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory User.fromJson(Map<String, dynamic> json) {
    // Helper para converter Timestamp do Firestore ou String para DateTime
    DateTime? _parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      // Firestore Timestamp - verificar se tem método toDate
      try {
        if (value.runtimeType.toString().contains('Timestamp')) {
          return (value as dynamic).toDate();
        }
      } catch (e) {
        // Ignorar erro
      }
      return null;
    }

    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      type: UserType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => UserType.user,
      ),
      photoUrl: json['photoUrl'] as String?,
      coverPhotoUrl: json['coverPhotoUrl'] as String?,
      preferredLanguage: json['preferredLanguage'] as String?,
      phone: json['phone'] as String?,
      points: json['points'] as int? ?? 0,
      seal: json['seal'] != null
          ? UserSeal.values.firstWhere(
              (e) => e.toString().split('.').last == json['seal'],
              orElse: () => UserSeal.bronze,
            )
          : UserSeal.bronze,
      totalCheckIns: json['totalCheckIns'] as int? ?? 0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      totalReferrals: json['totalReferrals'] as int? ?? 0,
      followersCount: json['followersCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
      dietaryPreferences: (json['dietaryPreferences'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'type': type.toString().split('.').last,
      'photoUrl': photoUrl,
      'coverPhotoUrl': coverPhotoUrl,
      'preferredLanguage': preferredLanguage,
      'phone': phone,
      'points': points,
      'seal': seal.toString().split('.').last,
      'totalCheckIns': totalCheckIns,
      'totalReviews': totalReviews,
      'totalReferrals': totalReferrals,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'dietaryPreferences': dietaryPreferences,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Método para calcular o selo baseado nas estatísticas
  UserSeal calculateSeal() {
    // Bronze: cadastro + 1 check-in
    if (totalCheckIns >= 1) {
      // Prata: 10 avaliações, 5 check-ins, 2 indicações
      if (totalReviews >= 10 && totalCheckIns >= 5 && totalReferrals >= 2) {
        // Ouro: mais de 25 avaliações, 10 indicações
        if (totalReviews >= 25 && totalReferrals >= 10) {
          return UserSeal.gold;
        }
        return UserSeal.silver;
      }
      return UserSeal.bronze;
    }
    return UserSeal.bronze;
  }
}


