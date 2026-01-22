import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:kiosk/models/product.dart';
import 'package:kiosk/models/order.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kiosk.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Incremented version
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
    
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        items TEXT NOT NULL, -- JSON string
        total_amount REAL NOT NULL,
        timestamp INTEGER NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE products ADD COLUMN brand TEXT');
      await db.execute('ALTER TABLE products ADD COLUMN size TEXT');
      await db.execute('ALTER TABLE products ADD COLUMN type TEXT');
    }
  }

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

  // Order Methods
  Future<void> insertOrder(Order order) async {
    final db = await instance.database;
    await db.insert(
      'orders',
      order.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Order>> getAllOrders() async {
    final db = await instance.database;
    final maps = await db.query('orders', orderBy: 'timestamp DESC');
    return maps.map((map) => Order.fromMap(map)).toList();
  }

  // Restore Logic
  Future<void> restoreProductsFromBackup(String backupPath) async {
    final db = await instance.database;
    
    // Attach the backup database
    // Note: We use raw SQL to attach because sqflite doesn't support DETACH via API directly easily
    // But standard SQL 'ATTACH DATABASE' works.
    
    try {
      await db.execute("ATTACH DATABASE '$backupPath' AS backup_db");
      
      // Clear current products
      await db.execute("DELETE FROM products");
      
      // Insert products from backup
      // Assuming backup_db has 'products' table with same schema
      await db.execute("INSERT INTO products SELECT * FROM backup_db.products");
      
      // Detach
      await db.execute("DETACH DATABASE backup_db");
    } catch (e) {
      // Attempt detach in case of error to avoid lock
      try {
        await db.execute("DETACH DATABASE backup_db");
      } catch (_) {}
      rethrow;
    }
  }
}
