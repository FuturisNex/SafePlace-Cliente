import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/establishment.dart';
import '../models/review.dart';
import '../models/checkin.dart';
import 'firebase_service.dart';
import 'gamification_service.dart';

class OfflineService {
  static const String _keyOfflineEstablishments = 'offline_establishments';
  static const String _keyOfflineReviews = 'offline_reviews';
  static const String _keyOfflineCheckIns = 'offline_checkins';
  static const String _keyOfflineMode = 'offline_mode';
  static const String _keyOfflineRegion = 'offline_region';

  /// Ativa o modo offline e salva estabelecimentos de uma região
  static Future<void> enableOfflineMode({
    required List<Establishment> establishments,
    required String regionName,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Salvar estabelecimentos
      final establishmentsJson = establishments.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(_keyOfflineEstablishments, establishmentsJson);
      
      // Salvar região
      await prefs.setString(_keyOfflineRegion, regionName);
      
      // Ativar modo offline
      await prefs.setBool(_keyOfflineMode, true);
      
      debugPrint('✅ Modo offline ativado para região: $regionName (${establishments.length} estabelecimentos)');
    } catch (e) {
      debugPrint('❌ Erro ao ativar modo offline: $e');
      rethrow;
    }
  }

  /// Desativa o modo offline
  static Future<void> disableOfflineMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyOfflineMode, false);
      await prefs.remove(_keyOfflineRegion);
      await prefs.remove(_keyOfflineEstablishments);
      debugPrint('✅ Modo offline desativado');
    } catch (e) {
      debugPrint('❌ Erro ao desativar modo offline: $e');
    }
  }

  /// Verifica se o modo offline está ativo
  static Future<bool> isOfflineModeActive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyOfflineMode) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Obtém a região salva offline
  static Future<String?> getOfflineRegion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyOfflineRegion);
    } catch (e) {
      return null;
    }
  }

  /// Carrega estabelecimentos salvos offline
  static Future<List<Establishment>> getOfflineEstablishments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final establishmentsJson = prefs.getStringList(_keyOfflineEstablishments) ?? [];
      
      return establishmentsJson.map((json) {
        final data = jsonDecode(json) as Map<String, dynamic>;
        return Establishment.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('❌ Erro ao carregar estabelecimentos offline: $e');
      return [];
    }
  }

  /// Salva um check-in offline para sincronizar depois
  static Future<void> saveOfflineCheckIn({
    required String userId,
    required String establishmentId,
    String? establishmentName,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final checkInsJson = prefs.getStringList(_keyOfflineCheckIns) ?? [];
      
      final checkIn = CheckIn(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        establishmentId: establishmentId,
        establishmentName: establishmentName,
        createdAt: DateTime.now(),
      );
      
      checkInsJson.add(jsonEncode(checkIn.toJson()));
      await prefs.setStringList(_keyOfflineCheckIns, checkInsJson);
      
      debugPrint('✅ Check-in salvo offline: ${checkIn.id}');
    } catch (e) {
      debugPrint('❌ Erro ao salvar check-in offline: $e');
    }
  }

  /// Salva uma avaliação offline para sincronizar depois
  static Future<void> saveOfflineReview(Review review) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reviewsJson = prefs.getStringList(_keyOfflineReviews) ?? [];
      
      reviewsJson.add(jsonEncode(review.toJson()));
      await prefs.setStringList(_keyOfflineReviews, reviewsJson);
      
      debugPrint('✅ Avaliação salva offline: ${review.id}');
    } catch (e) {
      debugPrint('❌ Erro ao salvar avaliação offline: $e');
    }
  }

  /// Sincroniza check-ins e avaliações pendentes quando voltar online
  static Future<void> syncOfflineData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Sincronizar check-ins
      final checkInsJson = prefs.getStringList(_keyOfflineCheckIns) ?? [];
      for (final checkInJson in checkInsJson) {
        try {
          final checkInData = jsonDecode(checkInJson) as Map<String, dynamic>;
          final checkIn = CheckIn.fromJson(checkInData);
          
          await GamificationService.registerCheckIn(
            userId: checkIn.userId,
            establishmentId: checkIn.establishmentId,
            establishmentName: checkIn.establishmentName,
          );
        } catch (e) {
          debugPrint('⚠️ Erro ao sincronizar check-in: $e');
        }
      }
      
      // Limpar check-ins sincronizados
      await prefs.remove(_keyOfflineCheckIns);
      
      // Sincronizar avaliações
      final reviewsJson = prefs.getStringList(_keyOfflineReviews) ?? [];
      for (final reviewJson in reviewsJson) {
        try {
          final reviewData = jsonDecode(reviewJson) as Map<String, dynamic>;
          final review = Review.fromJson(reviewData);
          
          await FirebaseService.saveReview(review);
        } catch (e) {
          debugPrint('⚠️ Erro ao sincronizar avaliação: $e');
        }
      }
      
      // Limpar avaliações sincronizadas
      await prefs.remove(_keyOfflineReviews);
      
      debugPrint('✅ Dados offline sincronizados');
    } catch (e) {
      debugPrint('❌ Erro ao sincronizar dados offline: $e');
    }
  }
}


