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
      version: 3,
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
        synced INTEGER NOT NULL DEFAULT 0,
        alipay_notify_checked_amount INTEGER NOT NULL DEFAULT 0,
        alipay_checkout_time_ms INTEGER,
        alipay_matched_key TEXT,
        alipay_matched_post_time_ms INTEGER,
        alipay_matched_title TEXT,
        alipay_matched_text TEXT,
        alipay_matched_parsed_amount_fen INTEGER
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
      await db.execute(
        'ALTER TABLE orders ADD COLUMN alipay_notify_checked_amount INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute('ALTER TABLE orders ADD COLUMN alipay_checkout_time_ms INTEGER');
      await db.execute('ALTER TABLE orders ADD COLUMN alipay_matched_key TEXT');
      await db.execute('ALTER TABLE orders ADD COLUMN alipay_matched_post_time_ms INTEGER');
      await db.execute('ALTER TABLE orders ADD COLUMN alipay_matched_title TEXT');
      await db.execute('ALTER TABLE orders ADD COLUMN alipay_matched_text TEXT');
      await db.execute('ALTER TABLE orders ADD COLUMN alipay_matched_parsed_amount_fen INTEGER');
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

  Future<void> clearProducts() async {
    final db = await instance.database;
    await db.delete('products');
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

  Future<Order?> getLatestPendingAlipayOrder({Duration maxAge = const Duration(minutes: 30)}) async {
    final db = await instance.database;
    final maps = await db.query(
      'orders',
      where: 'alipay_notify_checked_amount = 0 AND alipay_checkout_time_ms IS NOT NULL',
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final order = Order.fromMap(maps.first);
    final checkoutTimeMs = order.alipayCheckoutTimeMs;
    if (checkoutTimeMs == null) return null;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - checkoutTimeMs > maxAge.inMilliseconds) return null;
    return order;
  }

  Future<void> updateOrderAlipayMatch({
    required String orderId,
    required int checkoutTimeMs,
    required String matchedKey,
    required int matchedPostTimeMs,
    required String? matchedTitle,
    required String? matchedText,
    required int matchedParsedAmountFen,
  }) async {
    final db = await instance.database;
    await db.update(
      'orders',
      {
        'alipay_notify_checked_amount': 1,
        'alipay_checkout_time_ms': checkoutTimeMs,
        'alipay_matched_key': matchedKey,
        'alipay_matched_post_time_ms': matchedPostTimeMs,
        'alipay_matched_title': matchedTitle,
        'alipay_matched_text': matchedText,
        'alipay_matched_parsed_amount_fen': matchedParsedAmountFen,
      },
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  Future<bool> isAlipayNotificationKeyAlreadyUsed(String key) async {
    final db = await instance.database;
    final result = await db.query(
      'orders',
      columns: ['id'],
      where: 'alipay_notify_checked_amount = 1 AND alipay_matched_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // Restore Logic
  Future<void> restoreProductsFromBackup(String backupPath) async {
    final db = await instance.database;
    
    // Attach the backup database
    // Note: We use raw SQL to attach because sqflite doesn't support DETACH via API directly easily
    // But standard SQL 'ATTACH DATABASE' works.
    
    var attached = false;
    try {
      await db.execute("ATTACH DATABASE '$backupPath' AS backup_db");
      attached = true;

      final tables = await db.rawQuery(
        "SELECT name FROM backup_db.sqlite_master WHERE type='table' AND name='products'",
      );
      if (tables.isEmpty) {
        throw Exception('Backup missing products table');
      }
      
      // Clear current products
      await db.execute("DELETE FROM products");
      
      // Insert products from backup
      // Assuming backup_db has 'products' table with same schema
      await db.execute("INSERT INTO products SELECT * FROM backup_db.products");
    } catch (e) {
      rethrow;
    } finally {
      if (attached) {
        try {
          await db.execute("DETACH DATABASE backup_db");
        } catch (_) {}
      }
    }
  }
}
