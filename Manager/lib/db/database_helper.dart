import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:manager/models/product.dart';
import 'package:manager/models/kiosk.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

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
      version: 3, // Incremented version
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
        type TEXT
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
        last_synced INTEGER
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

  // Kiosk Methods
  Future<int> insertKiosk(Kiosk kiosk) async {
    final db = await instance.database;
    // Check if kiosk with same IP exists, update if so
    final existing = await db.query(
      'kiosks',
      where: 'ip = ?',
      whereArgs: [kiosk.ip],
    );

    if (existing.isNotEmpty) {
      return await db.update(
        'kiosks',
        kiosk.toMap(),
        where: 'ip = ?',
        whereArgs: [kiosk.ip],
      );
    } else {
      return await db.insert('kiosks', kiosk.toMap());
    }
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
