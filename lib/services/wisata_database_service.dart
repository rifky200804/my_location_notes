import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:my_location_notes/models/wisata.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb; // Tetap impor kIsWeb untuk debugging _initDatabase

class WisataDatabaseService {
  static Database? _database;
  static const String _tableName = 'wisata';

  // Getter untuk mendapatkan instance database
  Future<Database> get database async {
    // Jika _database belum diinisialisasi, panggil _initDatabase()
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Fungsi untuk menginisialisasi database
  Future<Database> _initDatabase() async {
    try {
      String path = await getDatabasesPath();
      String databasePath = join(path, 'wisata.db');
      print('DB_DEBUG: Opening database at: $databasePath');
      return await openDatabase(
        databasePath,
        version: 1,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      print('DB_ERROR: Failed to open database: $e');
      if (kIsWeb) {
        print(
          'DB_ERROR: Ini adalah masalah umum di web jika sqflite_sw.js tidak dimuat. Database TIDAK akan berfungsi di web.',
        );
        print(
          'DB_ERROR: Pastikan file sqflite_sw.js telah disalin ke folder web/ dan index.html telah dikonfigurasi.',
        );
      }
      rethrow; // Lempar ulang error agar bisa ditangkap di level atas
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    print('DB_DEBUG: Creating table $_tableName, version $version');
    await db.execute('''
      CREATE TABLE $_tableName(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        namaWisata TEXT,
        kota TEXT,
        kategori TEXT,
        latitude REAL,
        longitude REAL,
        timestamp TEXT,
        isFavorite INTEGER DEFAULT 0
      )
    ''');
    print('DB_DEBUG: Table $_tableName created successfully.');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print(
      'DB_DEBUG: Upgrading database from version $oldVersion to $newVersion',
    );
    // Implementasi upgrade skema database di sini jika version diubah di masa depan
  }

  Future<int> insertWisata(Wisata wisata) async {
    if (kIsWeb) {
      print(
        'DB_DEBUG: Insert operation skipped on web (database not available).',
      );
      return Future.value(0);
    }
    final db = await database; // Ini akan memicu _initDatabase() jika belum
    print('DB_DEBUG: Attempting to insert Wisata: ${wisata.toMap()}');
    try {
      final id = await db.insert(
        _tableName,
        wisata.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('DB_DEBUG: Wisata inserted successfully with ID: $id');
      return id;
    } catch (e) {
      print('DB_ERROR: Failed to insert Wisata: $e');
      rethrow;
    }
  }

  Future<List<Wisata>> getWisataList({String? kota, bool? isFavorite}) async {
    if (kIsWeb) {
      // Jika di web, lewati operasi dan kembalikan list kosong
      print(
        'DB_DEBUG: Get list operation skipped on web (database not available).',
      );
      return Future.value([]);
    }
    final db = await database; // Ini akan memicu _initDatabase() jika belum
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (kota != null && kota.isNotEmpty) {
      whereClauses.add('kota = ?');
      whereArgs.add(kota);
    }
    if (isFavorite != null) {
      whereClauses.add('isFavorite = ?');
      whereArgs.add(isFavorite ? 1 : 0);
    }

    String whereString = whereClauses.isEmpty ? '' : whereClauses.join(' AND ');
    print(
      'DB_DEBUG: Executing query: SELECT * FROM $_tableName ${whereString.isNotEmpty ? "WHERE $whereString" : ""} ORDER BY timestamp DESC, Args: $whereArgs',
    );

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: whereString.isEmpty ? null : whereString,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'timestamp DESC',
      );
      print('DB_DEBUG: Query returned ${maps.length} items: $maps');
      return List.generate(maps.length, (i) {
        return Wisata.fromMap(maps[i]);
      });
    } catch (e) {
      print('DB_ERROR: Failed to getWisataList: $e');
      rethrow;
    }
  }

  Future<int> updateWisata(Wisata wisata) async {
    final db = await database; // Ini akan memicu _initDatabase() jika belum
    try {
      final result = await db.update(
        _tableName,
        wisata.toMap(),
        where: 'id = ?',
        whereArgs: [wisata.id],
      );
      print('DB_DEBUG: Wisata updated: $result');
      return result;
    } catch (e) {
      print('DB_ERROR: Failed to update Wisata: $e');
      rethrow;
    }
  }

  Future<int> deleteWisata(int id) async {
    final db = await database; // Ini akan memicu _initDatabase() jika belum
    try {
      final result = await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      print('DB_DEBUG: Wisata deleted: $result');
      return result;
    } catch (e) {
      print('DB_ERROR: Failed to delete Wisata: $e');
      rethrow;
    }
  }
}
