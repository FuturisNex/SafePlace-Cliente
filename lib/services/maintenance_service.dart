import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MaintenanceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Verifica se o app está em modo de manutenção
  static Future<Map<String, dynamic>> checkMaintenanceStatus() async {
    try {
      final doc = await _firestore
          .collection('appSettings')
          .doc('maintenance')
          .get()
          .timeout(const Duration(seconds: 5));

      if (doc.exists) {
        final data = doc.data();
        return {
          'enabled': data?['enabled'] ?? false,
          'message': data?['message'] ?? 'O aplicativo está em manutenção. Tente novamente mais tarde.',
        };
      }

      return {
        'enabled': false,
        'message': '',
      };
    } catch (e) {
      // Se houver erro, não bloquear o app
      debugPrint('⚠️ Erro ao verificar manutenção: $e');
      return {
        'enabled': false,
        'message': '',
      };
    }
  }
}

