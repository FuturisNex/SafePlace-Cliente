import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/user_seal.dart';
import '../models/checkin.dart';
import '../models/coupon.dart';
import 'firebase_service.dart';

class GamificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============ PONTOS ============

  /// Adiciona pontos ao usuário
  static Future<void> addPoints(String userId, int points, String reason) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      await userRef.update({
        'points': FieldValue.increment(points),
      });
      debugPrint('✅ $points pontos adicionados ao usuário $userId ($reason)');
    } catch (e) {
      debugPrint('❌ Erro ao adicionar pontos: $e');
      rethrow;
    }
  }

  /// Calcula pontos baseado na ação
  static int getPointsForAction(String action) {
    switch (action) {
      case 'checkin':
        return 10;
      case 'review_with_photo':
        return 25;
      case 'review':
        return 15;
      case 'referral':
        return 50;
      case 'survey':
        return 15;
      default:
        return 0;
    }
  }

  // ============ SELOS ============

  /// Atualiza o selo do usuário baseado nas estatísticas
  static Future<UserSeal> updateUserSeal(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return UserSeal.bronze;
      }

      final data = userDoc.data()!;
      final totalCheckIns = data['totalCheckIns'] as int? ?? 0;
      final totalReviews = data['totalReviews'] as int? ?? 0;
      final totalReferrals = data['totalReferrals'] as int? ?? 0;

      UserSeal newSeal = UserSeal.bronze;

      // Bronze: cadastro + 1 check-in
      if (totalCheckIns >= 1) {
        // Prata: 10 avaliações, 5 check-ins, 2 indicações
        if (totalReviews >= 10 && totalCheckIns >= 5 && totalReferrals >= 2) {
          // Ouro: mais de 25 avaliações, 10 indicações
          if (totalReviews >= 25 && totalReferrals >= 10) {
            newSeal = UserSeal.gold;
          } else {
            newSeal = UserSeal.silver;
          }
        } else {
          newSeal = UserSeal.bronze;
        }
      }

      // Atualizar selo no Firestore
      await _firestore.collection('users').doc(userId).update({
        'seal': newSeal.toString().split('.').last,
      });

      debugPrint('✅ Selo atualizado para ${newSeal.label}');
      return newSeal;
    } catch (e) {
      debugPrint('❌ Erro ao atualizar selo: $e');
      return UserSeal.bronze;
    }
  }

  // ============ CHECK-INS ============

  /// Registra um check-in
  static Future<String> registerCheckIn({
    required String userId,
    required String establishmentId,
    String? establishmentName,
  }) async {
    try {
      // Verificar se já fez check-in neste estabelecimento hoje
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      // Buscar todos os check-ins do usuário neste estabelecimento e filtrar manualmente
      // (Firestore não permite múltiplos range filters na mesma query)
      final establishmentCheckIns = await _firestore
          .collection('checkins')
          .where('userId', isEqualTo: userId)
          .where('establishmentId', isEqualTo: establishmentId)
          .get();

      final todayCheckInsFiltered = establishmentCheckIns.docs.where((doc) {
        final data = doc.data();
        if (data['createdAt'] == null) return false;
        final createdAt = DateTime.parse(data['createdAt'] as String);
        return createdAt.isAfter(startOfDay) && createdAt.isBefore(now);
      }).toList();

      if (todayCheckInsFiltered.isNotEmpty) {
        throw Exception('Você já fez check-in neste estabelecimento hoje. Tente novamente amanhã!');
      }

      // Verificar cooldown de 1 hora entre check-ins (mesmo em estabelecimentos diferentes)
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      final allUserCheckIns = await _firestore
          .collection('checkins')
          .where('userId', isEqualTo: userId)
          .get();

      final recentCheckInsFiltered = allUserCheckIns.docs.where((doc) {
        final data = doc.data();
        if (data['createdAt'] == null) return false;
        final createdAt = DateTime.parse(data['createdAt'] as String);
        return createdAt.isAfter(oneHourAgo);
      }).toList();

      if (recentCheckInsFiltered.isNotEmpty) {
        // Ordenar por data mais recente
        recentCheckInsFiltered.sort((a, b) {
          final aTime = DateTime.parse(a.data()['createdAt'] as String);
          final bTime = DateTime.parse(b.data()['createdAt'] as String);
          return bTime.compareTo(aTime);
        });
        
        final lastCheckIn = recentCheckInsFiltered.first.data();
        final lastCheckInTime = DateTime.parse(lastCheckIn['createdAt'] as String);
        final timeSinceLastCheckIn = now.difference(lastCheckInTime);
        
        if (timeSinceLastCheckIn.inMinutes < 60) {
          final minutesRemaining = 60 - timeSinceLastCheckIn.inMinutes;
          throw Exception('Aguarde $minutesRemaining minuto(s) antes de fazer outro check-in.');
        }
      }

      final checkIn = CheckIn(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        establishmentId: establishmentId,
        establishmentName: establishmentName,
        createdAt: now,
      );

      // Salvar check-in
      await _firestore.collection('checkins').doc(checkIn.id).set(checkIn.toJson());

      // Atualizar estatísticas do usuário
      await _firestore.collection('users').doc(userId).update({
        'totalCheckIns': FieldValue.increment(1),
      });

      // Adicionar pontos
      await addPoints(userId, getPointsForAction('checkin'), 'Check-in');

      // Atualizar selo
      await updateUserSeal(userId);

      debugPrint('✅ Check-in registrado: ${checkIn.id}');
      return checkIn.id;
    } catch (e) {
      debugPrint('❌ Erro ao registrar check-in: $e');
      rethrow;
    }
  }

  /// Busca histórico de check-ins do usuário
  static Future<List<CheckIn>> getUserCheckIns(String userId) async {
    try {
      QuerySnapshot querySnapshot;
      try {
        querySnapshot = await _firestore
            .collection('checkins')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .get();
      } catch (e) {
        // Se orderBy falhar (índice não criado), tentar sem orderBy
        debugPrint('⚠️ Erro com orderBy, tentando sem: $e');
        querySnapshot = await _firestore
            .collection('checkins')
            .where('userId', isEqualTo: userId)
            .get();
        // Ordenar manualmente
        final docs = querySnapshot.docs.toList();
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['createdAt'] != null 
              ? DateTime.parse(aData['createdAt'] as String)
              : DateTime(1970);
          final bTime = bData['createdAt'] != null
              ? DateTime.parse(bData['createdAt'] as String)
              : DateTime(1970);
          return bTime.compareTo(aTime);
        });
        return docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return CheckIn.fromJson(data);
        }).toList();
      }

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return CheckIn.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('❌ Erro ao buscar check-ins: $e');
      return [];
    }
  }

  // ============ CUPONS ============

  /// Resgata um cupom com pontos
  static Future<Coupon?> redeemCoupon({
    required String userId,
    required String couponId,
    required int pointsCost,
  }) async {
    try {
      // Verificar se o usuário tem pontos suficientes
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('Usuário não encontrado');
      }

      final userPoints = userDoc.data()!['points'] as int? ?? 0;
      if (userPoints < pointsCost) {
        throw Exception('Pontos insuficientes');
      }

      // Buscar cupom disponível
      final couponDoc = await _firestore.collection('availableCoupons').doc(couponId).get();
      if (!couponDoc.exists) {
        throw Exception('Cupom não encontrado');
      }

      final couponData = couponDoc.data()!;
      final coupon = Coupon(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        establishmentId: couponData['establishmentId'] as String,
        establishmentName: couponData['establishmentName'] as String?,
        title: couponData['title'] as String,
        description: couponData['description'] as String,
        discount: (couponData['discount'] as num).toDouble(),
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(days: couponData['validityDays'] as int? ?? 30)),
        pointsCost: pointsCost,
      );

      // Salvar cupom do usuário
      await _firestore.collection('userCoupons').doc(coupon.id).set(coupon.toJson());

      // Deduzir pontos
      await _firestore.collection('users').doc(userId).update({
        'points': FieldValue.increment(-pointsCost),
      });

      debugPrint('✅ Cupom resgatado: ${coupon.id}');
      return coupon;
    } catch (e) {
      debugPrint('❌ Erro ao resgatar cupom: $e');
      rethrow;
    }
  }

  /// Busca cupons do usuário
  static Future<List<Coupon>> getUserCoupons(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('userCoupons')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Coupon.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('❌ Erro ao buscar cupons: $e');
      return [];
    }
  }

  /// Busca cupons disponíveis para resgate
  static Future<List<Map<String, dynamic>>> getAvailableCoupons() async {
    try {
      final querySnapshot = await _firestore
          .collection('availableCoupons')
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('❌ Erro ao buscar cupons disponíveis: $e');
      return [];
    }
  }

  // ============ PREMIUM ============

  /// Ativa Premium por assinatura
  static Future<void> activatePremiumBySubscription(String userId, int months) async {
    try {
      final expiresAt = DateTime.now().add(Duration(days: months * 30));
      await _firestore.collection('users').doc(userId).update({
        'isPremium': true,
        'premiumExpiresAt': expiresAt.toIso8601String(),
      });
      debugPrint('✅ Premium ativado por $months meses');
    } catch (e) {
      debugPrint('❌ Erro ao ativar Premium: $e');
      rethrow;
    }
  }

  /// Ativa Premium por pontos (1.000 pts = 1 mês)
  static Future<void> activatePremiumByPoints(String userId, int months) async {
    try {
      const pointsPerMonth = 1000;
      final pointsNeeded = months * pointsPerMonth;

      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('Usuário não encontrado');
      }

      final userPoints = userDoc.data()!['points'] as int? ?? 0;
      if (userPoints < pointsNeeded) {
        throw Exception('Pontos insuficientes');
      }

      final expiresAt = DateTime.now().add(Duration(days: months * 30));
      await _firestore.collection('users').doc(userId).update({
        'isPremium': true,
        'premiumExpiresAt': expiresAt.toIso8601String(),
        'points': FieldValue.increment(-pointsNeeded),
      });

      debugPrint('✅ Premium ativado por $months meses (${pointsNeeded} pontos)');
    } catch (e) {
      debugPrint('❌ Erro ao ativar Premium por pontos: $e');
      rethrow;
    }
  }
}

