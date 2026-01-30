import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/establishment.dart';

class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'favorites.db');

    return await openDatabase(
      path,
      version: 2, // Incrementado para adicionar userId
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE favorites(
            id TEXT,
            userId TEXT,
            name TEXT,
            category TEXT,
            latitude REAL,
            longitude REAL,
            distance REAL,
            avatarUrl TEXT,
            difficultyLevel TEXT,
            dietaryOptions TEXT,
            isOpen INTEGER,
            savedAt INTEGER,
            PRIMARY KEY (id, userId)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Migração: adicionar coluna userId e recriar tabela
          await db.execute('''
            CREATE TABLE favorites_new(
              id TEXT,
              userId TEXT,
              name TEXT,
              category TEXT,
              latitude REAL,
              longitude REAL,
              distance REAL,
              avatarUrl TEXT,
              difficultyLevel TEXT,
              dietaryOptions TEXT,
              isOpen INTEGER,
              savedAt INTEGER,
              PRIMARY KEY (id, userId)
            )
          ''');
          // Limpar dados antigos (sem userId) - não podemos migrar sem saber o usuário
          await db.execute('DROP TABLE favorites');
          await db.execute('ALTER TABLE favorites_new RENAME TO favorites');
        }
      },
    );
  }

  Future<void> saveFavorite(Establishment establishment, String userId) async {
    if (userId.isEmpty) {
      throw Exception('userId não pode ser vazio');
    }
    final db = await database;
    await db.insert(
      'favorites',
      {
        'id': establishment.id,
        'userId': userId,
        'name': establishment.name,
        'category': establishment.category,
        'latitude': establishment.latitude,
        'longitude': establishment.longitude,
        'distance': establishment.distance,
        'avatarUrl': establishment.avatarUrl ?? '',
        'difficultyLevel': establishment.difficultyLevel.toString().split('.').last,
        'dietaryOptions': establishment.dietaryOptions.map((e) => e.toString().split('.').last).join(','),
        'isOpen': establishment.isOpen ? 1 : 0,
        'savedAt': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeFavorite(String establishmentId, String userId) async {
    if (userId.isEmpty) {
      throw Exception('userId não pode ser vazio');
    }
    final db = await database;
    await db.delete(
      'favorites',
      where: 'id = ? AND userId = ?',
      whereArgs: [establishmentId, userId],
    );
  }

  Future<bool> isFavorite(String establishmentId, String userId) async {
    if (userId.isEmpty) {
      return false;
    }
    final db = await database;
    final result = await db.query(
      'favorites',
      where: 'id = ? AND userId = ?',
      whereArgs: [establishmentId, userId],
    );
    return result.isNotEmpty;
  }

  Future<List<Establishment>> getAllFavorites(String userId) async {
    if (userId.isEmpty) {
      return [];
    }
    final db = await database;
    final result = await db.query(
      'favorites',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'savedAt DESC',
    );

    return result.map((row) {
      return Establishment(
        id: row['id'] as String,
        name: row['name'] as String,
        category: row['category'] as String,
        latitude: row['latitude'] as double,
        longitude: row['longitude'] as double,
        distance: row['distance'] as double,
        avatarUrl: row['avatarUrl'] as String? ?? '',
        difficultyLevel: DifficultyLevel.fromString(row['difficultyLevel'] as String),
        dietaryOptions: (row['dietaryOptions'] as String? ?? '')
            .split(',')
            .where((e) => e.isNotEmpty)
            .map((e) => DietaryFilter.fromString(e))
            .toList(),
        isOpen: (row['isOpen'] as int) == 1,
      );
    }).toList();
  }

  Future<void> clearAllFavorites(String userId) async {
    if (userId.isEmpty) {
      throw Exception('userId não pode ser vazio');
    }
    final db = await database;
    await db.delete(
      'favorites',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }
}


