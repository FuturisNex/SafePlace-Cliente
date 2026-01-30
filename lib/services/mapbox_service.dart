import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:permission_handler/permission_handler.dart' as ph;
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
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Serviço de localização desabilitado');
        return null;
      }

      // Usar permission_handler para pedir permissão (evita bug do Geolocator ao tratar grantResults vazios)
      ph.PermissionStatus status = await ph.Permission.locationWhenInUse.status;

      if (status.isDenied || status.isRestricted) {
        status = await ph.Permission.locationWhenInUse.request();
      }

      if (status.isPermanentlyDenied) {
        debugPrint('Permissão de localização negada permanentemente');
        return null;
      }

      if (!status.isGranted) {
        debugPrint('Permissão de localização não concedida (status: $status)');
        return null;
      }

      return await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Erro ao obter posição: $e');
      return null;
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

