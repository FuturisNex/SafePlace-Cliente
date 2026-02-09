import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geofencing_api/geofencing_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/establishment.dart';
import 'notification_service.dart';

class GeofencingService {
  static const bool _enableGeofencing = false;
  static bool _isSetup = false;
  static bool _isStarted = false;
  static final Set<String> _registeredIds = <String>{};

  static Future<void> _ensureSetup() async {
    if (_isSetup) return;
    Geofencing.instance.setup(
      interval: 5000,
      accuracy: 100,
      statusChangeDelay: 10000,
      allowsMockLocation: false,
      printsDebugLog: !kReleaseMode,
    );
    Geofencing.instance.addGeofenceStatusChangedListener(_onGeofenceStatusChanged);
    Geofencing.instance.addGeofenceErrorCallbackListener(_onError);
    _isSetup = true;
  }

  static Future<Set<DietaryFilter>> _loadUserDietaryFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      if (userJson == null) return {};

      final data = json.decode(userJson) as Map<String, dynamic>;
      final raw = data['dietaryPreferences'];
      if (raw is List) {
        return raw
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .map(DietaryFilter.fromString)
            .toSet();
      }
    } catch (e) {
      debugPrint('Erro ao carregar preferências dietéticas para geofencing: $e');
    }
    return {};
  }

  static Future<bool> requestPermissions({bool background = true}) async {
    if (!_enableGeofencing) {
      debugPrint('Geofencing desabilitado: não solicitando permissões');
      return false;
    }
    try {
      final permission = await Geofencing.instance.requestLocationPermission();
      final status = permission.toString().toLowerCase();
      // Considerar concedido se não estiver em estado "denied"
      return !status.contains('denied');
    } catch (_) {
      return false;
    }
  }

  static Future<void> updateRegions(List<Establishment> establishments) async {
    if (!_enableGeofencing) {
      debugPrint('Geofencing desabilitado: não registrando regiões');
      return;
    }
    if (establishments.isEmpty) return;
    await _ensureSetup();
    final granted = await requestPermissions(background: true);
    if (!granted) return;

    final regions = <GeofenceRegion>{};
    final unique = <String>{};

    final preferredFilters = await _loadUserDietaryFilters();

    for (final e in establishments) {
      if (unique.contains(e.id)) continue;
      if (preferredFilters.isNotEmpty) {
        final options = e.dietaryOptions.toSet();
        if (!options.containsAll(preferredFilters)) {
          continue;
        }
      }
      unique.add(e.id);

      regions.add(
        GeofenceRegion.circular(
          id: e.id,
          data: {
            'id': e.id,
            'name': e.name,
          },
          center: LatLng(e.latitude, e.longitude),
          radius: 300,
          loiteringDelay: 60000,
        ),
      );

      if (regions.length >= 50) {
        break;
      }
    }

    if (regions.isEmpty) return;

    Geofencing.instance.clearAllRegions();
    Geofencing.instance.addRegions(regions);
    _registeredIds
      ..clear()
      ..addAll(regions.map((r) => r.id));

    if (!_isStarted) {
      try {
        await Geofencing.instance.start(regions: regions);
        _isStarted = true;
      } catch (e) {
        debugPrint('⚠️ Geofencing start failed (expected if background location is disabled): $e');
        // Não propagar erro para evitar crash, apenas logar
      }
    }
  }

  static Future<void> _onGeofenceStatusChanged(
    GeofenceRegion geofenceRegion,
    GeofenceStatus geofenceStatus,
    Location location,
  ) async {
    if (geofenceStatus == GeofenceStatus.enter ||
        geofenceStatus == GeofenceStatus.dwell) {
      final data = (geofenceRegion.data as Map<String, dynamic>?) ?? const <String, dynamic>{};
      final name = data['name'] as String? ?? 'Estabelecimento seguro';

      await NotificationService.showLocalNotificationAndSave(
        id: geofenceRegion.id.hashCode,
        title: 'Você está perto de um local seguro',
        body: name,
        type: 'nearby_safe_place',
      );
    }
  }

  static void _onError(Object error, StackTrace stackTrace) {
    debugPrint('Erro no geofencing: $error');
  }

  static Future<void> stop() async {
    if (!_isSetup) return;
    Geofencing.instance.stop(keepsRegions: false);
    _registeredIds.clear();
    _isStarted = false;
  }
}
