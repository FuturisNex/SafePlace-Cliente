import 'package:flutter/material.dart';
import '../utils/translations.dart';

class Review {
  final String id;
  final String establishmentId;
  final String userId;
  final String? userName;
  final String? userPhotoUrl;
  final double rating; // 1.0 a 5.0
  final String comment;
  final DateTime createdAt;
  final List<String>? dietaryRestrictions; // Restrições que o usuário tem
  final bool verifiedVisit; // Se o usuário realmente visitou o estabelecimento
  final List<String>? photos; // URLs das fotos da avaliação
  final int likesCount; // Número de curtidas da avaliação

  Review({
    required this.id,
    required this.establishmentId,
    required this.userId,
    this.userName,
    this.userPhotoUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.dietaryRestrictions,
    this.verifiedVisit = false,
    this.photos,
    this.likesCount = 0,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      establishmentId: json['establishmentId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String?,
      userPhotoUrl: json['userPhotoUrl'] as String?,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      dietaryRestrictions: json['dietaryRestrictions'] != null
          ? (json['dietaryRestrictions'] as List<dynamic>).map((e) => e as String).toList()
          : null,
      verifiedVisit: json['verifiedVisit'] as bool? ?? false,
      photos: json['photos'] != null
          ? (json['photos'] as List<dynamic>).map((e) => e as String).toList()
          : null,
      likesCount: json['likesCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'establishmentId': establishmentId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'dietaryRestrictions': dietaryRestrictions,
      'verifiedVisit': verifiedVisit,
      'photos': photos,
      'likesCount': likesCount,
    };
  }

  // Método para obter estrelas preenchidas
  List<Widget> getStars({double size = 16.0}) {
    final stars = <Widget>[];
    final fullStars = rating.floor();
    final hasHalfStar = rating - fullStars >= 0.5;

    for (int i = 0; i < 5; i++) {
      if (i < fullStars) {
        stars.add(Icon(Icons.star, color: Colors.amber, size: size));
      } else if (i == fullStars && hasHalfStar) {
        stars.add(Icon(Icons.star_half, color: Colors.amber, size: size));
      } else {
        stars.add(Icon(Icons.star_border, color: Colors.grey.shade400, size: size));
      }
    }
    return stars;
  }

  // Método para obter texto do tempo decorrido
  String getTimeAgo(BuildContext? context) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (context == null) {
      // Fallback sem contexto
      if (difference.inDays > 365) {
        final years = (difference.inDays / 365).floor();
        return '$years ${years == 1 ? 'ano' : 'anos'} atrás';
      } else if (difference.inDays > 30) {
        final months = (difference.inDays / 30).floor();
        return '$months ${months == 1 ? 'mês' : 'meses'} atrás';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} ${difference.inDays == 1 ? 'dia' : 'dias'} atrás';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} ${difference.inHours == 1 ? 'hora' : 'horas'} atrás';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minuto' : 'minutos'} atrás';
      } else {
        return 'Agora';
      }
    }

    // Com contexto - usar traduções
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? Translations.getText(context, 'yearAgo') : Translations.getText(context, 'yearsAgo')}';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? Translations.getText(context, 'monthAgo') : Translations.getText(context, 'monthsAgo')}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? Translations.getText(context, 'dayAgo') : Translations.getText(context, 'daysAgo')}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? Translations.getText(context, 'hourAgo') : Translations.getText(context, 'hoursAgo')}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? Translations.getText(context, 'minuteAgo') : Translations.getText(context, 'minutesAgo')}';
    } else {
      return Translations.getText(context, 'now');
    }
  }
}

