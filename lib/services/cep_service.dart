import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class CepService {
  /// Busca endereço completo via CEP usando ViaCEP
  static Future<Map<String, String>?> getAddressByCep(String cep) async {
    try {
      // Remove caracteres não numéricos
      final cleanCep = cep.replaceAll(RegExp(r'[^0-9]'), '');
      
      if (cleanCep.length != 8) {
        return null;
      }
      
      final url = Uri.parse('https://viacep.com.br/ws/$cleanCep/json/');
      final response = await http.get(url).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Timeout ao buscar CEP');
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        // Verifica se o CEP foi encontrado (não tem erro)
        if (data.containsKey('erro')) {
          return null;
        }
        
        return {
          'street': data['logradouro'] as String? ?? '',
          'neighborhood': data['bairro'] as String? ?? '',
          'city': data['localidade'] as String? ?? '',
          'state': data['uf'] as String? ?? '',
          'cep': data['cep'] as String? ?? cleanCep,
        };
      }
      
      return null;
    } catch (e) {
      debugPrint('Erro ao buscar CEP: $e');
      return null;
    }
  }
  
  /// Formata endereço completo a partir dos dados do CEP
  static String formatAddress(Map<String, String> addressData, String? number) {
    final street = addressData['street'] ?? '';
    final neighborhood = addressData['neighborhood'] ?? '';
    final city = addressData['city'] ?? '';
    final state = addressData['state'] ?? '';
    
    final parts = <String>[];
    if (street.isNotEmpty) {
      parts.add(street);
      if (number != null && number.isNotEmpty) {
        parts.add(number);
      }
    }
    if (neighborhood.isNotEmpty) {
      parts.add(neighborhood);
    }
    if (city.isNotEmpty) {
      parts.add(city);
    }
    if (state.isNotEmpty) {
      parts.add(state);
    }
    
    return parts.join(', ');
  }
}



