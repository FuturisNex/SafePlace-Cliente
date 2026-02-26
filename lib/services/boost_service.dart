import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Serviço para gerenciar campanhas de impulsionamento (boost)
class BoostService {
  // URL base do backend - definida via dart-define ou fallback
  static const String _baseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'https://portal.pratoseguro.com',
  );

  /// Configurações de boost
  static const double minTotalBudget = 50.0;
  static const double maxDailyBudget = 200.0;
  static const List<int> availableDurations = [7, 14, 30];
  
  /// Descontos por duração
  static double getDiscount(int days) {
    switch (days) {
      case 14: return 0.10;
      case 30: return 0.20;
      default: return 0.0;
    }
  }

  /// Calcula o valor mínimo para uma duração
  static double getMinBudgetForDuration(int days) {
    final discount = getDiscount(days);
    return minTotalBudget * (1 - discount);
  }

  /// Criar checkout para campanha de boost
  static Future<Map<String, dynamic>> createBoostCheckout({
    required String establishmentId,
    required String ownerId,
    required double totalBudget,
    required int durationDays,
  }) async {
    try {
      debugPrint('🚀 Criando checkout de boost: $establishmentId, R\$ $totalBudget, $durationDays dias');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/boost/create-checkout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'establishmentId': establishmentId,
          'ownerId': ownerId,
          'totalBudget': totalBudget,
          'durationDays': durationDays,
        }),
      ).timeout(const Duration(seconds: 30));

      debugPrint('📡 Resposta: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Checkout criado: ${data['initPoint']}');
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Erro ao criar checkout');
      }
    } catch (e) {
      debugPrint('❌ Erro ao criar checkout de boost: $e');
      rethrow;
    }
  }

  /// Obter estimativa de posição baseada no lance
  static Future<Map<String, dynamic>> getPositionEstimate({
    required double dailyBudget,
    String? city,
    String? state,
  }) async {
    final queryParams = {
      'dailyBudget': dailyBudget.toString(),
      if (city != null) 'city': city,
      if (state != null) 'state': state,
    };

    final uri = Uri.parse('$_baseUrl/api/boost/estimate-position')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao obter estimativa');
    }
  }

  /// Listar campanhas de um owner
  static Future<List<Map<String, dynamic>>> getCampaigns(String ownerId, {String? status}) async {
    try {
      final queryParams = {
        if (status != null) 'status': status,
      };

      final uri = Uri.parse('$_baseUrl/api/boost/campaigns/$ownerId')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      debugPrint('📡 BoostService.getCampaigns: $uri');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      debugPrint('📡 BoostService.getCampaigns: status=${response.statusCode}');
      debugPrint('📡 BoostService.getCampaigns: body=${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('✅ BoostService: ${data.length} campanhas encontradas');
        return data.cast<Map<String, dynamic>>();
      } else {
        debugPrint('❌ BoostService: Erro ${response.statusCode}: ${response.body}');
        throw Exception('Erro ao listar campanhas');
      }
    } catch (e) {
      debugPrint('❌ Erro ao buscar campanhas: $e');
      rethrow;
    }
  }

  /// Obter métricas de uma campanha
  static Future<Map<String, dynamic>> getCampaignMetrics(String campaignId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/boost/campaigns/$campaignId/metrics'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao obter métricas');
    }
  }

  /// Pausar ou retomar campanha
  static Future<void> updateCampaignStatus(String campaignId, String status) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/api/boost/campaigns/$campaignId/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erro ao atualizar status');
    }
  }

  /// Obter IDs de estabelecimentos com boost ativo
  static Future<List<String>> getActiveBoostedIds({String? city, String? state, int limit = 10}) async {
    final queryParams = {
      'limit': limit.toString(),
      if (city != null) 'city': city,
      if (state != null) 'state': state,
    };

    final uri = Uri.parse('$_baseUrl/api/boost/active')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['boostedIds'] ?? []);
    } else {
      return [];
    }
  }

  /// Retorna o label da posição estimada
  static String getPositionLabel(String positionLabel) {
    switch (positionLabel) {
      case 'top3':
        return 'Top 3 🏆';
      case 'top10':
        return 'Top 10 ⭐';
      default:
        return 'Em destaque';
    }
  }

  /// Registrar impressão de estabelecimento boosted
  static Future<void> registerImpression(String establishmentId) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/api/boost/impression/$establishmentId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      // Silenciosamente ignorar erros de impressão
      debugPrint('⚠️ Erro ao registrar impressão: $e');
    }
  }

  /// Registrar clique em estabelecimento boosted
  static Future<void> registerClick(String establishmentId) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/api/boost/click/$establishmentId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      // Silenciosamente ignorar erros de clique
      debugPrint('⚠️ Erro ao registrar clique: $e');
    }
  }
}
