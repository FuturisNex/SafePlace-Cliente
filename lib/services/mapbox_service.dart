import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../models/establishment.dart';

class MapboxService {
  static const String mapboxAccessToken = 'pk.eyJ1Ijoic2FmZXBsYXRlNTAwIiwiYSI6ImNtaGZoMXF2NTA1dDIya3B5dnljbXkzZG4ifQ.DgeBcy0YXvBdDLdPVerqjA';
  
  // Configurar Mapbox (chamado antes de criar o mapa)
  static Future<void> initialize() async {
    try {
      MapboxOptions.setAccessToken(mapboxAccessToken);
    } catch (e) {
      debugPrint('Erro ao configurar Mapbox: $e');
    }
  }

  // Nota: Os marcadores são criados diretamente no widget do mapa
  // Este método é mantido para referência futura se necessário

  // Obter posição atual do usuário
  static Future<geo.Position?> getCurrentPosition() async {
    try {
      final hasPermission = await ensureLocationPermission();
      if (!hasPermission) return null;

      try {
        return await geo.Geolocator.getCurrentPosition(
          desiredAccuracy: geo.LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );
      } on TimeoutException catch (e) {
        debugPrint('Timeout ao obter posição atual: $e');
      } catch (e) {
        debugPrint('Erro ao obter posição atual: $e');
      }

      return await geo.Geolocator.getLastKnownPosition();
    } catch (e) {
      debugPrint('Erro ao obter posição: $e');
      return null;
    }
  }

  // Obter a última posição conhecida, se disponível (mais rápido no primeiro uso)
  static Future<geo.Position?> getLastKnownPosition() async {
    try {
      final hasPermission = await ensureLocationPermission();
      if (!hasPermission) return null;

      return await geo.Geolocator.getLastKnownPosition();
    } catch (e) {
      debugPrint('Erro ao obter última posição conhecida: $e');
      return null;
    }
  }

  // Garante que a permissão de localização está concedida antes de iniciar leituras/stream.
  static Future<bool> ensureLocationPermission() async {
    try {
      final serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Serviço de localização desabilitado');
        return false;
      }

      var geoPermission = await geo.Geolocator.checkPermission();
      debugPrint('Geolocator permission atual: $geoPermission');

      if (geoPermission == geo.LocationPermission.denied) {
        geoPermission = await geo.Geolocator.requestPermission();
        debugPrint('Geolocator permission apos request: $geoPermission');
      }

      if (geoPermission == geo.LocationPermission.deniedForever) {
        debugPrint('Permissão de localização negada permanentemente');
        return false;
      }

      if (geoPermission == geo.LocationPermission.denied) {
        debugPrint('Permissão de localização negada');
        return false;
      }

      return geoPermission == geo.LocationPermission.always ||
          geoPermission == geo.LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('Erro ao validar permissão de localização: $e');
      return false;
    }
  }

  // Calcular distância entre dois pontos
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return geo.Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // em km
  }
}

