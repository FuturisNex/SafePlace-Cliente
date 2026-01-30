import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class GeocodingService {
  /// Obtém coordenadas (latitude/longitude) a partir de um endereço
  /// Usa Nominatim (OpenStreetMap) - gratuito e não requer API key
  static Future<Map<String, double>?> getCoordinatesFromAddress(String address) async {
    try {
      if (address.isEmpty) {
        return null;
      }
      
      // Usa Nominatim para geocoding
      final encodedAddress = Uri.encodeComponent(address);
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$encodedAddress&format=json&limit=1',
      );
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'Prato Seguro App', // Nominatim requer User-Agent
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout ao buscar coordenadas');
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        
        if (data.isNotEmpty) {
          final result = data[0] as Map<String, dynamic>;
          final lat = double.tryParse(result['lat'] as String? ?? '');
          final lon = double.tryParse(result['lon'] as String? ?? '');
          
          if (lat != null && lon != null) {
            return {
              'latitude': lat,
              'longitude': lon,
            };
          }
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Erro ao buscar coordenadas: $e');
      return null;
    }
  }
}


