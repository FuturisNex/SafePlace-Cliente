import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  // Traduções
  String get search => _getTranslation('search');
  String get nearby => _getTranslation('nearby');
  String get openNow => _getTranslation('openNow');
  String get favorites => _getTranslation('favorites');
  String get profile => _getTranslation('profile');
  String get account => _getTranslation('account');
  String get login => _getTranslation('login');
  String get generateRoute => _getTranslation('generateRoute');
  String get cancel => _getTranslation('cancel');
  String get doYouWantToGo => _getTranslation('doYouWantToGo');

  String _getTranslation(String key) {
    switch (locale.languageCode) {
      case 'pt':
        return _ptTranslations[key] ?? key;
      case 'es':
        return _esTranslations[key] ?? key;
      case 'en':
      default:
        return _enTranslations[key] ?? key;
    }
  }

  static final Map<String, String> _enTranslations = {
    'search': 'Search',
    'nearby': 'Nearby',
    'openNow': 'Open Now',
    'favorites': 'Favorites',
    'profile': 'Profile',
    'account': 'Account',
    'login': 'Login',
    'generateRoute': 'Generate Route',
    'cancel': 'Cancel',
    'doYouWantToGo': 'Do you want to go to this location?',
  };

  static final Map<String, String> _ptTranslations = {
    'search': 'Buscar',
    'nearby': 'Próximos',
    'openNow': 'Abertos',
    'favorites': 'Favoritos',
    'profile': 'Perfil',
    'account': 'Conta',
    'login': 'Login',
    'generateRoute': 'Gerar Rota',
    'cancel': 'Cancelar',
    'doYouWantToGo': 'Deseja ir até este local?',
  };

  static final Map<String, String> _esTranslations = {
    'search': 'Buscar',
    'nearby': 'Cercanos',
    'openNow': 'Abiertos',
    'favorites': 'Favoritos',
    'profile': 'Perfil',
    'account': 'Cuenta',
    'login': 'Iniciar sesión',
    'generateRoute': 'Generar Ruta',
    'cancel': 'Cancelar',
    'doYouWantToGo': '¿Deseas ir a este lugar?',
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'pt', 'es'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

