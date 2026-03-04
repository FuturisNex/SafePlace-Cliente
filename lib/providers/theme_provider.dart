import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _configCollection = 'appConfig';
  static const String _configDoc = 'global';
  static const String _primaryColorField = 'themePrimaryColor';
  static const String _fallbackPrimaryColorField = 'primaryColor';
  static const String _themeImageField = 'themeImage';
  static const String _cachedPrimaryColorKey = 'theme_cached_primary_color_v1';
  static const String _cachedThemeImageKey = 'theme_cached_image_url_v1';

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;

  Color _primaryColor = AppTheme.primaryGreen;
  String? _themeImageUrl;
  bool _isLoaded = false;

  Color get primaryColor => _primaryColor;
  String? get themeImageUrl => _themeImageUrl;
  bool get isLoaded => _isLoaded;
  ThemeData get themeData => AppTheme.lightThemeWithPrimary(_primaryColor);

  ThemeProvider() {
    _loadCachedThemeConfig();
    _listenThemeConfig();
    _ensureThemeDefaults();
  }

  Future<void> _loadCachedThemeConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var changed = false;

      final cachedHex = prefs.getString(_cachedPrimaryColorKey);
      final cachedColor = _parseHexColor(cachedHex);
      if (cachedColor != null && cachedColor != _primaryColor) {
        _primaryColor = cachedColor;
        changed = true;
      }

      final cachedImage = _normalizeThemeImage(prefs.getString(_cachedThemeImageKey));
      if (cachedImage != _themeImageUrl) {
        _themeImageUrl = cachedImage;
        changed = true;
      }

      if (changed) {
        notifyListeners();
      }
    } catch (_) {
      // Fail silently: cache is an optimization only.
    }
  }

  void _listenThemeConfig() {
    _subscription = _db
        .collection(_configCollection)
        .doc(_configDoc)
        .snapshots()
        .listen(
      (snapshot) {
        final data = snapshot.data();
        final rawHex =
            data?[_primaryColorField] ?? data?[_fallbackPrimaryColorField];
        final nextColor = _parseHexColor(rawHex?.toString());
        final nextThemeImage = _normalizeThemeImage(data?[_themeImageField]);
        var changed = false;

        if (nextColor != null && nextColor != _primaryColor) {
          _primaryColor = nextColor;
          changed = true;
        }

        if (nextThemeImage != _themeImageUrl) {
          _themeImageUrl = nextThemeImage;
          changed = true;
        }

        if (changed) {
          notifyListeners();
          unawaited(_persistThemeCache());
        }
        if (!_isLoaded) {
          _isLoaded = true;
          notifyListeners();
        }
      },
      onError: (_) {
        if (!_isLoaded) {
          _isLoaded = true;
          notifyListeners();
        }
      },
    );
  }

  Future<void> _persistThemeCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedPrimaryColorKey, _toHex(_primaryColor));
      final image = _themeImageUrl;
      if (image == null || image.isEmpty) {
        await prefs.remove(_cachedThemeImageKey);
      } else {
        await prefs.setString(_cachedThemeImageKey, image);
      }
    } catch (_) {
      // Fail silently: cache is an optimization only.
    }
  }

  Future<void> _ensureThemeDefaults() async {
    try {
      final ref = _db.collection(_configCollection).doc(_configDoc);
      final doc = await ref.get();
      final data = doc.data();
      if (data == null ||
          data[_primaryColorField] == null ||
          data[_primaryColorField].toString().trim().isEmpty) {
        await ref.set(
          {
            _primaryColorField: _toHex(_primaryColor),
          },
          SetOptions(merge: true),
        );
      }
    } catch (_) {
      // Fail silently: fallback color is applied locally.
    }
  }

  Color? _parseHexColor(String? hex) {
    if (hex == null) return null;
    final normalized = hex.trim().replaceAll('#', '');
    if (normalized.length != 6 && normalized.length != 8) return null;
    final value = int.tryParse(
      normalized.length == 6 ? 'FF$normalized' : normalized,
      radix: 16,
    );
    if (value == null) return null;
    return Color(value);
  }

  String _toHex(Color color) {
    final rgb = color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2);
    return '#${rgb.toUpperCase()}';
  }

  String? _normalizeThemeImage(Object? rawValue) {
    if (rawValue is! String) return null;
    final normalized = rawValue.trim();
    if (normalized.isEmpty) return null;
    return normalized;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
