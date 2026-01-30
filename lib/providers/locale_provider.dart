import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider with ChangeNotifier {
  Locale _locale = const Locale('en', ''); // Default: inglês

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('language') ?? 'en';
      _locale = Locale(languageCode);
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar idioma: $e');
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    _locale = locale;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', locale.languageCode);
    } catch (e) {
      debugPrint('Erro ao salvar idioma: $e');
    }
  }

  void selectLanguage(String code) {
    switch (code) {
      case 'pt':
        setLocale(const Locale('pt', ''));
        break;
      case 'en':
        setLocale(const Locale('en', ''));
        break;
      case 'es':
        setLocale(const Locale('es', ''));
        break;
    }
  }

  bool isSelected(String code) {
    return _locale.languageCode == code;
  }
}

