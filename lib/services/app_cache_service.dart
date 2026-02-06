import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppCacheService {
  static const String _firstLaunchKey = 'first_launch_cleaned_v1';

  static Future<void> clearOnFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyCleaned = prefs.getBool(_firstLaunchKey) ?? false;
    if (alreadyCleaned) return;

    debugPrint('🧹 Primeira abertura detectada: limpando cache local');

    try {
      await prefs.clear();
    } catch (e) {
      debugPrint('⚠️ Erro ao limpar SharedPreferences: $e');
    }

    try {
      await _deleteDatabase('favorites.db');
    } catch (e) {
      debugPrint('⚠️ Erro ao remover banco local: $e');
    }

    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('⚠️ Erro ao limpar sessao Firebase: $e');
    }

    await prefs.setBool(_firstLaunchKey, true);
  }

  static Future<void> _deleteDatabase(String dbName) async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, dbName);
    await deleteDatabase(path);
  }
}
