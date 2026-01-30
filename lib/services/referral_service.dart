import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/establishment.dart';
import '../services/firebase_service.dart';
import '../services/gamification_service.dart';

class ReferralService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Indica um novo estabelecimento
  static Future<bool> referEstablishment({
    required String userId,
    required Establishment establishment,
    String? notes,
  }) async {
    try {
      // Verificar se o estabelecimento já existe
      final existingEstablishments = await FirebaseService.getAllEstablishments();
      final alreadyExists = existingEstablishments.any((e) => 
        e.name.toLowerCase() == establishment.name.toLowerCase() &&
        (e.latitude - establishment.latitude).abs() < 0.001 &&
        (e.longitude - establishment.longitude).abs() < 0.001
      );

      if (alreadyExists) {
        throw Exception('Este estabelecimento já está cadastrado');
      }

      // Salvar indicação
      final referral = {
        'userId': userId,
        'establishmentName': establishment.name,
        'establishmentCategory': establishment.category,
        'latitude': establishment.latitude,
        'longitude': establishment.longitude,
        'address': establishment.address,
        'phone': establishment.phone,
        'dietaryOptions': establishment.dietaryOptions.map((f) => f.toString().split('.').last).toList(),
        'notes': notes,
        'status': 'pending', // pending, approved, rejected
        'origem': 'indicacao', // Diferencia de trilha
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('referrals').add(referral);

      debugPrint('✅ Indicação registrada (aguardando aprovação): ${establishment.name}');
      return true;
    } catch (e) {
      debugPrint('❌ Erro ao indicar estabelecimento: $e');
      rethrow;
    }
  }

  /// Busca indicações do usuário
  static Future<List<Map<String, dynamic>>> getUserReferrals(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('referrals')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('❌ Erro ao buscar indicações: $e');
      return [];
    }
  }
}


