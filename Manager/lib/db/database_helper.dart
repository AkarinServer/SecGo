import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:manager/models/product.dart';
import 'package:manager/models/kiosk.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._init();
  static DatabaseHelper? _mockInstance;
  
  static DatabaseHelper get instance => _mockInstance ?? _instance;

  @visibleForTesting
  static set mockInstance(DatabaseHelper? mock) => _mockInstance = mock;

  DatabaseHelper._init();
  @visibleForTesting
  DatabaseHelper.testing();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('manager.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5, // Incremented version for search fields
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        barcode TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        last_updated INTEGER NOT NULL,
        brand TEXT,
        size TEXT,
        type TEXT,
        pinyin TEXT,
        initials TEXT
      )
    ''');
    
    await _createKiosksTable(db);
  }

  Future<void> _createKiosksTable(Database db) async {
    await db.execute('''
      CREATE TABLE kiosks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ip TEXT NOT NULL,
        port INTEGER NOT NULL,
        pin TEXT NOT NULL,
        name TEXT,
        last_synced INTEGER,
        device_id TEXT
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE products ADD COLUMN brand TEXT');
      await db.execute('ALTER TABLE products ADD COLUMN size TEXT');
      await db.execute('ALTER TABLE products ADD COLUMN type TEXT');
    }
    if (oldVersion < 3) {
      await _createKiosksTable(db);
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE kiosks ADD COLUMN device_id TEXT');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE products ADD COLUMN pinyin TEXT');
      await db.execute('ALTER TABLE products ADD COLUMN initials TEXT');
    }
  }

  // Product Methods
  Future<void> upsertProduct(Product product) async {
    final db = await instance.database;
    await db.insert(
      'products',
      product.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Product?> getProduct(String barcode) async {
    final db = await instance.database;
    final maps = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );

    if (maps.isNotEmpty) {
      return Product.fromJson(maps.first);
    }
    return null;
  }

  Future<List<Product>> getAllProducts() async {
    final db = await instance.database;
    final maps = await db.query('products');
    return maps.map((json) => Product.fromJson(json)).toList();
  }

  Future<int> deleteProduct(String barcode) async {
    final db = await instance.database;
    return await db.delete(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );
  }

  Future<String> getNextNoBarcodeId() async {
    final db = await instance.database;
    final rows = await db.query(
      'products',
      columns: ['barcode'],
      where: 'barcode LIKE ?',
      whereArgs: const ['NB-%'],
    );
    var maxN = 0;
    for (final row in rows) {
      final raw = row['barcode']?.toString() ?? '';
      if (!raw.startsWith('NB-')) continue;
      final n = int.tryParse(raw.substring(3));
      if (n == null) continue;
      if (n > maxN) maxN = n;
    }
    return 'NB-${maxN + 1}';
  }

  // Kiosk Methods
  Future<int> insertKiosk(Kiosk kiosk) async {
    final db = await instance.database;
    final hasDeviceId = kiosk.deviceId != null && kiosk.deviceId!.isNotEmpty;
    final existing = await db.query(
      'kiosks',
      where: hasDeviceId ? 'device_id = ?' : 'ip = ?',
      whereArgs: [hasDeviceId ? kiosk.deviceId : kiosk.ip],
    );

    if (existing.isNotEmpty) {
      return await db.update(
        'kiosks',
        kiosk.toMap(),
        where: hasDeviceId ? 'device_id = ?' : 'ip = ?',
        whereArgs: [hasDeviceId ? kiosk.deviceId : kiosk.ip],
      );
    } else {
      return await db.insert('kiosks', kiosk.toMap());
    }
  }

  Future<int> updateKiosk(Kiosk kiosk) async {
    final db = await instance.database;
    if (kiosk.id == null) {
      return await insertKiosk(kiosk);
    }
    return await db.update(
      'kiosks',
      kiosk.toMap(),
      where: 'id = ?',
      whereArgs: [kiosk.id],
    );
  }

  Future<List<Kiosk>> getAllKiosks() async {
    final db = await instance.database;
    final maps = await db.query('kiosks', orderBy: 'last_synced DESC');
    return maps.map((map) => Kiosk.fromMap(map)).toList();
  }
  
  Future<int> deleteKiosk(int id) async {
    final db = await instance.database;
    return await db.delete('kiosks', where: 'id = ?', whereArgs: [id]);
  }
}
