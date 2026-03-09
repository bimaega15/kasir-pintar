import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/cart_item_model.dart';
import '../models/category_model.dart';
import '../models/order_item_model.dart';
import '../models/order_model.dart';
import '../models/payment_entry_model.dart';
import '../models/product_model.dart';
import '../models/shift_model.dart';
import '../models/split_transaction_model.dart';
import '../models/table_model.dart';
import '../models/transaction_model.dart';
import '../models/debt_model.dart';
import '../models/price_level_model.dart';
import '../models/void_log_model.dart';

/// Provider SQLite — mendukung offline penuh tanpa jaringan.
class DatabaseProvider extends GetxService {
  static const _dbName = 'kasir_pintar.db';
  static const _dbVersion = 9;

  late Database _db;

  Future<DatabaseProvider> init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    _db = await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.rawQuery('PRAGMA journal_mode=WAL');
        await db.rawQuery('PRAGMA busy_timeout=5000');
      },
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );

    await _seedIfNeeded();
    return this;
  }

  // ── Schema ────────────────────────────────────────────────────────────────

  Future<void> _createTables(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE products (
        id          TEXT    PRIMARY KEY,
        name        TEXT    NOT NULL,
        category_id TEXT    NOT NULL,
        price       REAL    NOT NULL,
        stock       INTEGER NOT NULL DEFAULT 0,
        description TEXT    NOT NULL DEFAULT '',
        emoji       TEXT    NOT NULL DEFAULT '📦',
        created_at  TEXT    NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE transactions (
        id                    TEXT PRIMARY KEY,
        invoice_number        TEXT NOT NULL,
        subtotal              REAL NOT NULL,
        discount              REAL NOT NULL DEFAULT 0,
        total                 REAL NOT NULL,
        payment_amount        REAL NOT NULL,
        change_amount         REAL NOT NULL,
        payment_method        TEXT NOT NULL DEFAULT 'Tunai',
        created_at            TEXT NOT NULL,
        cashier_name          TEXT NOT NULL DEFAULT 'Kasir',
        order_type            TEXT NOT NULL DEFAULT 'dine_in',
        table_number          INTEGER,
        tax_amount            REAL NOT NULL DEFAULT 0,
        service_charge_amount REAL NOT NULL DEFAULT 0,
        customer_name         TEXT NOT NULL DEFAULT '',
        shift_id              TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE transaction_items (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id TEXT    NOT NULL,
        product_id     TEXT    NOT NULL,
        product_name   TEXT    NOT NULL,
        product_price  REAL    NOT NULL,
        product_emoji  TEXT    NOT NULL DEFAULT '📦',
        quantity       INTEGER NOT NULL,
        note           TEXT    NOT NULL DEFAULT '',
        FOREIGN KEY (transaction_id) REFERENCES transactions(id)
      )
    ''');

    batch.execute('''
      CREATE TABLE transaction_payments (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id TEXT    NOT NULL,
        method         TEXT    NOT NULL,
        amount         REAL    NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES transactions(id)
      )
    ''');

    batch.execute('''
      CREATE TABLE settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE tables (
        id               TEXT PRIMARY KEY,
        number           INTEGER NOT NULL,
        capacity         INTEGER NOT NULL DEFAULT 4,
        status           TEXT    NOT NULL DEFAULT 'available',
        current_order_id TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE orders (
        id                     TEXT PRIMARY KEY,
        invoice_number         TEXT NOT NULL,
        order_type             TEXT NOT NULL DEFAULT 'dine_in',
        table_id               TEXT,
        table_number           INTEGER,
        guest_count            INTEGER NOT NULL DEFAULT 1,
        kitchen_status         TEXT NOT NULL DEFAULT 'pending',
        subtotal               REAL NOT NULL,
        discount               REAL NOT NULL DEFAULT 0,
        tax_percent            REAL NOT NULL DEFAULT 0,
        tax_amount             REAL NOT NULL DEFAULT 0,
        service_charge_percent REAL NOT NULL DEFAULT 0,
        service_charge_amount  REAL NOT NULL DEFAULT 0,
        total                  REAL NOT NULL,
        cashier_name           TEXT NOT NULL DEFAULT 'Kasir',
        created_at             TEXT NOT NULL,
        kitchen_sent_at        TEXT,
        ready_at               TEXT,
        customer_name          TEXT NOT NULL DEFAULT ''
      )
    ''');

    batch.execute('''
      CREATE TABLE order_items (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id       TEXT    NOT NULL,
        product_id     TEXT    NOT NULL,
        product_name   TEXT    NOT NULL,
        product_price  REAL    NOT NULL,
        product_emoji  TEXT    NOT NULL DEFAULT '📦',
        quantity       INTEGER NOT NULL,
        note           TEXT    NOT NULL DEFAULT '',
        FOREIGN KEY (order_id) REFERENCES orders(id)
      )
    ''');

    batch.execute('''
      CREATE TABLE order_payments (
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id TEXT NOT NULL,
        method   TEXT NOT NULL,
        amount   REAL NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders(id)
      )
    ''');

    batch.execute('''
      CREATE TABLE shifts (
        id               TEXT    PRIMARY KEY,
        cashier_name     TEXT    NOT NULL,
        opening_balance  REAL    NOT NULL DEFAULT 0,
        closing_balance  REAL,
        expected_cash    REAL,
        difference       REAL,
        notes            TEXT    NOT NULL DEFAULT '',
        opened_at        TEXT    NOT NULL,
        closed_at        TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE void_logs (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id         TEXT    NOT NULL,
        invoice_number   TEXT    NOT NULL,
        order_total      REAL    NOT NULL,
        reason           TEXT    NOT NULL,
        voided_by        TEXT    NOT NULL DEFAULT 'Kasir',
        voided_at        TEXT    NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE split_transactions (
        id                  INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id      TEXT    NOT NULL,
        split_number        INTEGER NOT NULL,
        total_split_amount  REAL    NOT NULL,
        amount_paid         REAL    NOT NULL,
        change_amount       REAL    NOT NULL,
        payment_method      TEXT    NOT NULL,
        notes               TEXT    NOT NULL DEFAULT '',
        created_at          TEXT    NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES transactions(id),
        UNIQUE(transaction_id, split_number)
      )
    ''');

    batch.execute('''
      CREATE TABLE debts (
        id               TEXT    PRIMARY KEY,
        invoice_number   TEXT    NOT NULL,
        customer_name    TEXT    NOT NULL DEFAULT '',
        total_amount     REAL    NOT NULL,
        dp_amount        REAL    NOT NULL DEFAULT 0,
        remaining_amount REAL    NOT NULL,
        status           TEXT    NOT NULL DEFAULT 'unpaid',
        created_at       TEXT    NOT NULL,
        paid_at          TEXT,
        notes            TEXT    NOT NULL DEFAULT ''
      )
    ''');

    batch.execute('''
      CREATE TABLE debt_payments (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        debt_id   TEXT    NOT NULL,
        amount    REAL    NOT NULL,
        method    TEXT    NOT NULL DEFAULT 'Tunai',
        paid_at   TEXT    NOT NULL,
        notes     TEXT    NOT NULL DEFAULT '',
        FOREIGN KEY (debt_id) REFERENCES debts(id)
      )
    ''');

    batch.execute('''
      CREATE TABLE categories (
        id         TEXT PRIMARY KEY,
        name       TEXT NOT NULL,
        icon       TEXT NOT NULL DEFAULT '📦',
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE price_levels (
        id          TEXT PRIMARY KEY,
        name        TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        sort_order  INTEGER NOT NULL DEFAULT 0,
        is_default  INTEGER NOT NULL DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE product_price_levels (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id     TEXT NOT NULL,
        price_level_id TEXT NOT NULL,
        price          REAL NOT NULL,
        UNIQUE(product_id, price_level_id)
      )
    ''');

    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 9) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS price_levels (
          id TEXT PRIMARY KEY, name TEXT NOT NULL,
          description TEXT NOT NULL DEFAULT '',
          sort_order INTEGER NOT NULL DEFAULT 0,
          is_default INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS product_price_levels (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id TEXT NOT NULL, price_level_id TEXT NOT NULL,
          price REAL NOT NULL,
          UNIQUE(product_id, price_level_id)
        )
      ''');
    }
    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          icon TEXT NOT NULL DEFAULT '📦',
          sort_order INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }
    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS debts (
          id TEXT PRIMARY KEY, invoice_number TEXT NOT NULL,
          customer_name TEXT NOT NULL DEFAULT '', total_amount REAL NOT NULL,
          dp_amount REAL NOT NULL DEFAULT 0, remaining_amount REAL NOT NULL,
          status TEXT NOT NULL DEFAULT 'unpaid', created_at TEXT NOT NULL,
          paid_at TEXT, notes TEXT NOT NULL DEFAULT ''
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS debt_payments (
          id INTEGER PRIMARY KEY AUTOINCREMENT, debt_id TEXT NOT NULL,
          amount REAL NOT NULL, method TEXT NOT NULL DEFAULT 'Tunai',
          paid_at TEXT NOT NULL, notes TEXT NOT NULL DEFAULT '',
          FOREIGN KEY (debt_id) REFERENCES debts(id)
        )
      ''');
    }
    if (oldVersion < 6) {
      final batch = db.batch();
      batch.execute('''
        CREATE TABLE IF NOT EXISTS split_transactions (
          id                  INTEGER PRIMARY KEY AUTOINCREMENT,
          transaction_id      TEXT    NOT NULL,
          split_number        INTEGER NOT NULL,
          total_split_amount  REAL    NOT NULL,
          amount_paid         REAL    NOT NULL,
          change_amount       REAL    NOT NULL,
          payment_method      TEXT    NOT NULL,
          notes               TEXT    NOT NULL DEFAULT '',
          created_at          TEXT    NOT NULL,
          FOREIGN KEY (transaction_id) REFERENCES transactions(id),
          UNIQUE(transaction_id, split_number)
        )
      ''');
      await batch.commit(noResult: true);
    }
    if (oldVersion < 5) {
      final batch = db.batch();
      batch.execute('''
        CREATE TABLE IF NOT EXISTS transaction_payments (
          id             INTEGER PRIMARY KEY AUTOINCREMENT,
          transaction_id TEXT    NOT NULL,
          method         TEXT    NOT NULL,
          amount         REAL    NOT NULL,
          FOREIGN KEY (transaction_id) REFERENCES transactions(id)
        )
      ''');
      await batch.commit(noResult: true);
    }
    if (oldVersion < 4) {
      final batch = db.batch();
      batch.execute('''
        CREATE TABLE IF NOT EXISTS shifts (
          id TEXT PRIMARY KEY, cashier_name TEXT NOT NULL,
          opening_balance REAL NOT NULL DEFAULT 0, closing_balance REAL,
          expected_cash REAL, difference REAL,
          notes TEXT NOT NULL DEFAULT '', opened_at TEXT NOT NULL, closed_at TEXT
        )
      ''');
      batch.execute('''
        CREATE TABLE IF NOT EXISTS void_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT, order_id TEXT NOT NULL,
          invoice_number TEXT NOT NULL, order_total REAL NOT NULL,
          reason TEXT NOT NULL, voided_by TEXT NOT NULL DEFAULT 'Kasir',
          voided_at TEXT NOT NULL
        )
      ''');
      await batch.commit(noResult: true);
      // ALTER TABLE may fail if column already exists — safe to ignore
      try {
        await db.execute(
          'ALTER TABLE transactions ADD COLUMN shift_id TEXT',
        );
      } catch (_) {}
    }
    if (oldVersion < 3) {
      final batch = db.batch();
      batch.execute(
        "ALTER TABLE transactions ADD COLUMN customer_name TEXT NOT NULL DEFAULT ''",
      );
      batch.execute(
        "ALTER TABLE orders ADD COLUMN customer_name TEXT NOT NULL DEFAULT ''",
      );
      await batch.commit(noResult: true);
    }
    if (oldVersion < 2) {
      final batch = db.batch();
      batch.execute(
        "ALTER TABLE transactions ADD COLUMN order_type TEXT NOT NULL DEFAULT 'dine_in'",
      );
      batch.execute('ALTER TABLE transactions ADD COLUMN table_number INTEGER');
      batch.execute(
        'ALTER TABLE transactions ADD COLUMN tax_amount REAL NOT NULL DEFAULT 0',
      );
      batch.execute(
        'ALTER TABLE transactions ADD COLUMN service_charge_amount REAL NOT NULL DEFAULT 0',
      );
      batch.execute('''
        CREATE TABLE IF NOT EXISTS tables (
          id TEXT PRIMARY KEY, number INTEGER NOT NULL,
          capacity INTEGER NOT NULL DEFAULT 4,
          status TEXT NOT NULL DEFAULT 'available', current_order_id TEXT
        )
      ''');
      batch.execute('''
        CREATE TABLE IF NOT EXISTS orders (
          id TEXT PRIMARY KEY, invoice_number TEXT NOT NULL,
          order_type TEXT NOT NULL DEFAULT 'dine_in', table_id TEXT,
          table_number INTEGER, guest_count INTEGER NOT NULL DEFAULT 1,
          kitchen_status TEXT NOT NULL DEFAULT 'pending',
          subtotal REAL NOT NULL, discount REAL NOT NULL DEFAULT 0,
          tax_percent REAL NOT NULL DEFAULT 0, tax_amount REAL NOT NULL DEFAULT 0,
          service_charge_percent REAL NOT NULL DEFAULT 0,
          service_charge_amount REAL NOT NULL DEFAULT 0,
          total REAL NOT NULL, cashier_name TEXT NOT NULL DEFAULT 'Kasir',
          created_at TEXT NOT NULL, kitchen_sent_at TEXT, ready_at TEXT
        )
      ''');
      batch.execute('''
        CREATE TABLE IF NOT EXISTS order_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT, order_id TEXT NOT NULL,
          product_id TEXT NOT NULL, product_name TEXT NOT NULL,
          product_price REAL NOT NULL, product_emoji TEXT NOT NULL DEFAULT '📦',
          quantity INTEGER NOT NULL, note TEXT NOT NULL DEFAULT ''
        )
      ''');
      batch.execute('''
        CREATE TABLE IF NOT EXISTS order_payments (
          id INTEGER PRIMARY KEY AUTOINCREMENT, order_id TEXT NOT NULL,
          method TEXT NOT NULL, amount REAL NOT NULL
        )
      ''');
      await batch.commit(noResult: true);
    }
  }

  // ── Seeding ───────────────────────────────────────────────────────────────

  Future<void> _seedIfNeeded() async {
    final productCount =
        Sqflite.firstIntValue(
          await _db.rawQuery('SELECT COUNT(*) FROM products'),
        ) ??
        0;
    if (productCount == 0) {
      final batch = _db.batch();
      for (final p in ProductModel.sampleProducts) {
        batch.insert('products', _productToMap(p));
      }
      await batch.commit(noResult: true);
    }

    final tableCount =
        Sqflite.firstIntValue(
          await _db.rawQuery('SELECT COUNT(*) FROM tables'),
        ) ??
        0;
    if (tableCount == 0) {
      final batch = _db.batch();
      for (final t in TableModel.defaultTables) {
        batch.insert('tables', _tableToMap(t));
      }
      await batch.commit(noResult: true);
    }

    final priceLevelCount =
        Sqflite.firstIntValue(
          await _db.rawQuery('SELECT COUNT(*) FROM price_levels'),
        ) ??
        0;
    if (priceLevelCount == 0) {
      final batch = _db.batch();
      for (int i = 0; i < PriceLevelModel.defaultLevels.length; i++) {
        final lvl = PriceLevelModel.defaultLevels[i];
        batch.insert('price_levels', {
          'id': lvl.id,
          'name': lvl.name,
          'description': lvl.description,
          'sort_order': i,
          'is_default': lvl.isDefault ? 1 : 0,
        });
      }
      await batch.commit(noResult: true);
    }

    final categoryCount =
        Sqflite.firstIntValue(
          await _db.rawQuery('SELECT COUNT(*) FROM categories'),
        ) ??
        0;
    if (categoryCount == 0) {
      final batch = _db.batch();
      final defaults = [
        const CategoryModel(id: 'food', name: 'Makanan', icon: '🍔'),
        const CategoryModel(id: 'drink', name: 'Minuman', icon: '☕'),
        const CategoryModel(id: 'snack', name: 'Snack', icon: '🍿'),
        const CategoryModel(id: 'other', name: 'Lainnya', icon: '📦'),
      ];
      for (int i = 0; i < defaults.length; i++) {
        batch.insert('categories', _categoryToMap(defaults[i], i));
      }
      await batch.commit(noResult: true);
    }
  }

  // ── Products ──────────────────────────────────────────────────────────────

  Future<List<ProductModel>> getProducts() async {
    try {
      final maps = await _db.query('products', orderBy: 'created_at ASC');
      final products = maps.map(_productFromMap).toList();

      // Load semua product_price_levels + nama level dalam 1 query JOIN
      final priceMaps = await _db.rawQuery('''
        SELECT ppl.product_id, ppl.price_level_id, ppl.price, pl.name as level_name
        FROM product_price_levels ppl
        JOIN price_levels pl ON ppl.price_level_id = pl.id
      ''');

      // Kelompokkan per product_id
      final priceMap = <String, List<ProductPriceLevelEntry>>{};
      for (final row in priceMaps) {
        final pid = row['product_id'] as String;
        priceMap.putIfAbsent(pid, () => []).add(ProductPriceLevelEntry(
          priceLevelId: row['price_level_id'] as String,
          priceLevelName: row['level_name'] as String,
          price: (row['price'] as num).toDouble(),
        ));
      }
      for (final p in products) {
        p.priceLevels = priceMap[p.id] ?? [];
      }
      return products;
    } catch (e) {
      print('[getProducts] Error: $e');
      rethrow;
    }
  }

  Future<void> insertProduct(ProductModel product) async {
    try {
      final map = _productToMap(product);
      print('[insertProduct] Inserting product: ${product.name} with map: $map');
      await _db.insert('products', map);
      print('[insertProduct] Successfully inserted product: ${product.name}');
    } catch (e) {
      print('[insertProduct] Error inserting product: $e');
      rethrow;
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    await _db.update(
      'products',
      _productToMap(product),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> deleteProduct(String id) async {
    await _db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  ProductModel _productFromMap(Map<String, Object?> m) {
    try {
      // Defensive parsing with null checks
      final id = m['id'] as String?;
      final name = m['name'] as String?;
      final categoryId = m['category_id'] as String?;
      final priceValue = m['price'];
      final stockValue = m['stock'];
      final description = m['description'] as String? ?? '';
      final emoji = m['emoji'] as String? ?? '📦';
      final createdAtStr = m['created_at'] as String?;

      if (id == null || name == null || categoryId == null || priceValue == null || stockValue == null || createdAtStr == null) {
        throw FormatException('Missing required fields in product map: $m');
      }

      final price = (priceValue as num).toDouble();
      final stock = stockValue as int;

      return ProductModel(
        id: id,
        name: name,
        categoryId: categoryId,
        price: price,
        stock: stock,
        description: description,
        emoji: emoji,
        createdAt: DateTime.parse(createdAtStr),
      );
    } catch (e) {
      print('[_productFromMap] Error parsing map: $m with error: $e');
      rethrow;
    }
  }

  Map<String, Object?> _productToMap(ProductModel p) => {
    'id': p.id,
    'name': p.name,
    'category_id': p.categoryId,
    'price': p.price,
    'stock': p.stock,
    'description': p.description,
    'emoji': p.emoji,
    'created_at': p.createdAt.toIso8601String(),
  };

  // ── Tables ────────────────────────────────────────────────────────────────

  Future<List<TableModel>> getTables() async {
    final maps = await _db.query('tables', orderBy: 'number ASC');
    return maps.map(_tableFromMap).toList();
  }

  Future<void> insertTable(TableModel table) async {
    await _db.insert('tables', _tableToMap(table));
  }

  Future<void> updateTable(TableModel table) async {
    await _db.update(
      'tables',
      _tableToMap(table),
      where: 'id = ?',
      whereArgs: [table.id],
    );
  }

  Future<void> deleteTable(String id) async {
    await _db.delete('tables', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setTableOccupied(String tableId, String orderId) async {
    await _db.update(
      'tables',
      {'status': 'occupied', 'current_order_id': orderId},
      where: 'id = ?',
      whereArgs: [tableId],
    );
  }

  Future<void> setTableAvailable(String tableId) async {
    await _db.update(
      'tables',
      {'status': 'available', 'current_order_id': null},
      where: 'id = ?',
      whereArgs: [tableId],
    );
  }

  TableModel _tableFromMap(Map<String, Object?> m) => TableModel(
    id: m['id'] as String,
    number: m['number'] as int,
    capacity: m['capacity'] as int? ?? 4,
    status: TableModel.statusFromString(m['status'] as String? ?? 'available'),
    currentOrderId: m['current_order_id'] as String?,
  );

  Map<String, Object?> _tableToMap(TableModel t) => {
    'id': t.id,
    'number': t.number,
    'capacity': t.capacity,
    'status': TableModel.statusToString(t.status),
    'current_order_id': t.currentOrderId,
  };

  // ── Orders ────────────────────────────────────────────────────────────────

  Future<List<OrderModel>> getOrders({String? kitchenStatus}) async {
    final List<Map<String, Object?>> orderMaps;
    if (kitchenStatus != null) {
      orderMaps = await _db.query(
        'orders',
        where: 'kitchen_status = ?',
        whereArgs: [kitchenStatus],
        orderBy: 'created_at ASC',
      );
    } else {
      orderMaps = await _db.query('orders', orderBy: 'created_at ASC');
    }
    if (orderMaps.isEmpty) return [];
    return _assembleOrders(orderMaps);
  }

  Future<List<OrderModel>> getActiveOrders() async {
    final orderMaps = await _db.rawQuery(
      "SELECT * FROM orders WHERE kitchen_status != 'paid' AND kitchen_status != 'parked' ORDER BY created_at ASC",
    );
    if (orderMaps.isEmpty) return [];
    return _assembleOrders(orderMaps);
  }

  Future<List<OrderModel>> getParkedOrders() async {
    final orderMaps = await _db.rawQuery(
      "SELECT * FROM orders WHERE kitchen_status = 'parked' ORDER BY created_at ASC",
    );
    if (orderMaps.isEmpty) return [];
    return _assembleOrders(orderMaps);
  }

  Future<OrderModel?> getOrderById(String id) async {
    final maps = await _db.query('orders', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    final assembled = await _assembleOrders(maps);
    return assembled.first;
  }

  Future<void> insertOrder(OrderModel order) async {
    await _db.transaction((txn) async {
      await txn.insert('orders', _orderToMap(order));
      for (final item in order.items) {
        await txn.insert('order_items', {
          'order_id': order.id,
          'product_id': item.productId,
          'product_name': item.productName,
          'product_price': item.productPrice,
          'product_emoji': item.productEmoji,
          'quantity': item.quantity,
          'note': item.note,
        });
      }
    });
  }

  Future<void> updateOrderKitchenStatus(
    String orderId,
    KitchenStatus status,
  ) async {
    final extra = <String, Object?>{};
    if (status == KitchenStatus.inProgress) {
      extra['kitchen_sent_at'] = DateTime.now().toIso8601String();
    } else if (status == KitchenStatus.ready) {
      extra['ready_at'] = DateTime.now().toIso8601String();
    }
    await _db.update(
      'orders',
      {'kitchen_status': OrderModel.kitchenStatusToString(status), ...extra},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  Future<void> insertOrderPayments(
    String orderId,
    List<PaymentEntry> payments,
  ) async {
    final batch = _db.batch();
    for (final p in payments) {
      batch.insert('order_payments', {
        'order_id': orderId,
        'method': p.method,
        'amount': p.amount,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteOrder(String id) async {
    await _db.transaction((txn) async {
      await txn.delete('order_items', where: 'order_id = ?', whereArgs: [id]);
      await txn.delete(
        'order_payments',
        where: 'order_id = ?',
        whereArgs: [id],
      );
      await txn.delete('orders', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<OrderModel>> _assembleOrders(
    List<Map<String, Object?>> orderMaps,
  ) async {
    final ids = orderMaps.map((m) => m['id'] as String).toList();
    final placeholders = List.filled(ids.length, '?').join(', ');

    final itemMaps = await _db.rawQuery(
      'SELECT * FROM order_items WHERE order_id IN ($placeholders) ORDER BY id ASC',
      ids,
    );
    final paymentMaps = await _db.rawQuery(
      'SELECT * FROM order_payments WHERE order_id IN ($placeholders) ORDER BY id ASC',
      ids,
    );

    final itemsByOrder = <String, List<OrderItemModel>>{};
    for (final m in itemMaps) {
      final oid = m['order_id'] as String;
      itemsByOrder
          .putIfAbsent(oid, () => [])
          .add(
            OrderItemModel(
              productId: m['product_id'] as String,
              productName: m['product_name'] as String,
              productPrice: (m['product_price'] as num).toDouble(),
              productEmoji: m['product_emoji'] as String? ?? '📦',
              quantity: m['quantity'] as int,
              note: m['note'] as String? ?? '',
            ),
          );
    }

    final paymentsByOrder = <String, List<PaymentEntry>>{};
    for (final m in paymentMaps) {
      final oid = m['order_id'] as String;
      paymentsByOrder
          .putIfAbsent(oid, () => [])
          .add(
            PaymentEntry(
              method: m['method'] as String,
              amount: (m['amount'] as num).toDouble(),
            ),
          );
    }

    return orderMaps.map((m) {
      final oid = m['id'] as String;
      return OrderModel(
        id: oid,
        invoiceNumber: m['invoice_number'] as String,
        orderType: OrderModel.orderTypeFromString(
          m['order_type'] as String? ?? 'dine_in',
        ),
        tableId: m['table_id'] as String?,
        tableNumber: m['table_number'] as int?,
        guestCount: m['guest_count'] as int? ?? 1,
        kitchenStatus: OrderModel.kitchenStatusFromString(
          m['kitchen_status'] as String? ?? 'pending',
        ),
        subtotal: (m['subtotal'] as num).toDouble(),
        discount: (m['discount'] as num?)?.toDouble() ?? 0,
        taxPercent: (m['tax_percent'] as num?)?.toDouble() ?? 0,
        taxAmount: (m['tax_amount'] as num?)?.toDouble() ?? 0,
        serviceChargePercent:
            (m['service_charge_percent'] as num?)?.toDouble() ?? 0,
        serviceChargeAmount:
            (m['service_charge_amount'] as num?)?.toDouble() ?? 0,
        total: (m['total'] as num).toDouble(),
        items: itemsByOrder[oid] ?? [],
        payments: paymentsByOrder[oid] ?? [],
        customerName: m['customer_name'] as String? ?? '',
        cashierName: m['cashier_name'] as String? ?? 'Kasir',
        createdAt: DateTime.parse(m['created_at'] as String),
        kitchenSentAt: m['kitchen_sent_at'] != null
            ? DateTime.parse(m['kitchen_sent_at'] as String)
            : null,
        readyAt: m['ready_at'] != null
            ? DateTime.parse(m['ready_at'] as String)
            : null,
      );
    }).toList();
  }

  Map<String, Object?> _orderToMap(OrderModel o) => {
    'id': o.id,
    'invoice_number': o.invoiceNumber,
    'order_type': OrderModel.orderTypeToString(o.orderType),
    'table_id': o.tableId,
    'table_number': o.tableNumber,
    'guest_count': o.guestCount,
    'kitchen_status': OrderModel.kitchenStatusToString(o.kitchenStatus),
    'subtotal': o.subtotal,
    'discount': o.discount,
    'tax_percent': o.taxPercent,
    'tax_amount': o.taxAmount,
    'service_charge_percent': o.serviceChargePercent,
    'service_charge_amount': o.serviceChargeAmount,
    'total': o.total,
    'cashier_name': o.cashierName,
    'created_at': o.createdAt.toIso8601String(),
    'kitchen_sent_at': o.kitchenSentAt?.toIso8601String(),
    'ready_at': o.readyAt?.toIso8601String(),
    'customer_name': o.customerName,
  };

  // ── Transactions ──────────────────────────────────────────────────────────

  Future<List<TransactionModel>> getTransactions({String? datePrefix}) async {
    final List<Map<String, Object?>> txMaps;

    if (datePrefix != null) {
      txMaps = await _db.query(
        'transactions',
        where: 'created_at LIKE ?',
        whereArgs: ['$datePrefix%'],
        orderBy: 'created_at DESC',
      );
    } else {
      txMaps = await _db.query('transactions', orderBy: 'created_at DESC');
    }

    if (txMaps.isEmpty) return [];

    final txIds = txMaps.map((m) => m['id'] as String).toList();
    final placeholders = List.filled(txIds.length, '?').join(', ');
    final itemMaps = await _db.rawQuery(
      'SELECT * FROM transaction_items WHERE transaction_id IN ($placeholders) ORDER BY id ASC',
      txIds,
    );

    final itemsByTx = <String, List<CartItemModel>>{};
    for (final item in itemMaps) {
      final txId = item['transaction_id'] as String;
      itemsByTx.putIfAbsent(txId, () => []).add(_cartItemFromMap(item));
    }

    return txMaps.map((m) {
      final txId = m['id'] as String;
      return TransactionModel(
        id: txId,
        invoiceNumber: m['invoice_number'] as String,
        items: itemsByTx[txId] ?? [],
        subtotal: (m['subtotal'] as num).toDouble(),
        discount: (m['discount'] as num?)?.toDouble() ?? 0,
        total: (m['total'] as num).toDouble(),
        paymentAmount: (m['payment_amount'] as num).toDouble(),
        change: (m['change_amount'] as num).toDouble(),
        paymentMethod: m['payment_method'] as String? ?? 'Tunai',
        createdAt: DateTime.parse(m['created_at'] as String),
        cashierName: m['cashier_name'] as String? ?? 'Kasir',
        orderType: m['order_type'] as String? ?? 'dine_in',
        tableNumber: m['table_number'] as int?,
        taxAmount: (m['tax_amount'] as num?)?.toDouble() ?? 0,
        serviceChargeAmount:
            (m['service_charge_amount'] as num?)?.toDouble() ?? 0,
        customerName: m['customer_name'] as String? ?? '',
      );
    }).toList();
  }

  Future<List<TransactionModel>> getTransactionsToday() async {
    final now = DateTime.now();
    final prefix =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return getTransactions(datePrefix: prefix);
  }

  Future<void> insertTransaction(TransactionModel transaction,
      [List paymentEntries = const []]) async {
    await _db.transaction((txn) async {
      await txn.insert('transactions', {
        'id': transaction.id,
        'invoice_number': transaction.invoiceNumber,
        'subtotal': transaction.subtotal,
        'discount': transaction.discount,
        'total': transaction.total,
        'payment_amount': transaction.paymentAmount,
        'change_amount': transaction.change,
        'payment_method': transaction.paymentMethod,
        'created_at': transaction.createdAt.toIso8601String(),
        'cashier_name': transaction.cashierName,
        'order_type': transaction.orderType,
        'table_number': transaction.tableNumber,
        'tax_amount': transaction.taxAmount,
        'service_charge_amount': transaction.serviceChargeAmount,
        'customer_name': transaction.customerName,
      });

      for (final item in transaction.items) {
        await txn.insert('transaction_items', {
          'transaction_id': transaction.id,
          'product_id': item.product.id,
          'product_name': item.product.name,
          'product_price': item.product.price,
          'product_emoji': item.product.emoji,
          'quantity': item.quantity,
          'note': item.note,
        });
      }

      // Save individual payment entries
      for (final payment in paymentEntries) {
        await txn.insert('transaction_payments', {
          'transaction_id': transaction.id,
          'method': payment.method,
          'amount': payment.amount,
        });
      }
    });
  }

  CartItemModel _cartItemFromMap(Map<String, Object?> m) {
    final product = ProductModel(
      id: m['product_id'] as String,
      name: m['product_name'] as String,
      categoryId: 'other',
      price: (m['product_price'] as num).toDouble(),
      emoji: m['product_emoji'] as String? ?? '📦',
    );
    return CartItemModel(
      product: product,
      quantity: m['quantity'] as int,
      note: m['note'] as String? ?? '',
    );
  }

  Future<List<PaymentEntry>> getTransactionPayments(String transactionId) async {
    final result = await _db.query(
      'transaction_payments',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
    return result
        .map((m) => PaymentEntry(
              method: m['method'] as String,
              amount: (m['amount'] as num).toDouble(),
            ))
        .toList();
  }

  // ── Split Transactions ────────────────────────────────────────────────────

  Future<int> insertSplitTransaction(SplitTransactionModel split) async {
    return await _db.insert('split_transactions', split.toMap());
  }

  Future<List<SplitTransactionModel>> getSplitTransactionsByTransactionId(
      String transactionId) async {
    final result = await _db.query(
      'split_transactions',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
      orderBy: 'split_number ASC',
    );
    return result.map((m) => SplitTransactionModel.fromMap(m)).toList();
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  Future<String?> getSetting(String key) async {
    final result = await _db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (result.isEmpty) return null;
    return result.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    await _db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ── Invoice Number ────────────────────────────────────────────────────────

  // ── Shifts ────────────────────────────────────────────────────────────────

  Future<void> insertShift(ShiftModel shift) async {
    await _db.insert('shifts', shift.toMap());
  }

  Future<ShiftModel?> getActiveShift() async {
    final maps = await _db.query(
      'shifts',
      where: 'closed_at IS NULL',
      orderBy: 'opened_at DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ShiftModel.fromMap(maps.first);
  }

  Future<void> updateShiftClose(
    String id,
    double closingBalance,
    double expectedCash,
    String notes,
  ) async {
    final difference = closingBalance - expectedCash;
    await _db.update(
      'shifts',
      {
        'closing_balance': closingBalance,
        'expected_cash': expectedCash,
        'difference': difference,
        'notes': notes,
        'closed_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ShiftModel>> getShifts() async {
    final maps = await _db.query('shifts', orderBy: 'opened_at DESC');
    return maps.map(ShiftModel.fromMap).toList();
  }

  Future<double> getTunaiRevenueSince(DateTime since) async {
    final result = await _db.rawQuery(
      "SELECT COALESCE(SUM(payment_amount), 0) as total FROM transactions "
      "WHERE payment_method = 'Tunai' AND created_at >= ?",
      [since.toIso8601String()],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // ── Void Logs ─────────────────────────────────────────────────────────────

  Future<void> insertVoidLog(VoidLogModel log) async {
    await _db.insert('void_logs', log.toMap());
  }

  Future<List<VoidLogModel>> getVoidLogs() async {
    final maps = await _db.query('void_logs', orderBy: 'voided_at DESC');
    return maps.map(VoidLogModel.fromMap).toList();
  }

  Future<void> deleteTransaction(String id) async {
    await _db.delete('transaction_items',
        where: 'transaction_id = ?', whereArgs: [id]);
    await _db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // ── Debts ─────────────────────────────────────────────────────────────────

  Future<void> insertDebt(DebtModel debt) async {
    await _db.insert('debts', debt.toMap());
  }

  Future<List<DebtModel>> getDebts({bool unpaidOnly = false}) async {
    final maps = unpaidOnly
        ? await _db.query('debts',
            where: "status != 'paid'", orderBy: 'created_at DESC')
        : await _db.query('debts', orderBy: 'created_at DESC');
    final debts = maps.map(DebtModel.fromMap).toList();
    for (final debt in debts) {
      debt.payments = await getDebtPayments(debt.id);
    }
    return debts;
  }

  Future<DebtModel?> getDebtByInvoice(String invoiceNumber) async {
    final maps = await _db.query('debts',
        where: 'invoice_number = ?', whereArgs: [invoiceNumber]);
    if (maps.isEmpty) return null;
    final debt = DebtModel.fromMap(maps.first);
    debt.payments = await getDebtPayments(debt.id);
    return debt;
  }

  Future<DebtModel?> getDebtById(String id) async {
    final maps = await _db.query('debts', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    final debt = DebtModel.fromMap(maps.first);
    debt.payments = await getDebtPayments(id);
    return debt;
  }

  Future<List<DebtPaymentEntry>> getDebtPayments(String debtId) async {
    final maps = await _db.query('debt_payments',
        where: 'debt_id = ?', whereArgs: [debtId], orderBy: 'paid_at ASC');
    return maps.map(DebtPaymentEntry.fromMap).toList();
  }

  Future<void> insertDebtPayment(DebtPaymentEntry payment) async {
    await _db.insert('debt_payments', payment.toMap());
    final debt = await getDebtById(payment.debtId);
    if (debt == null) return;
    final totalPaid =
        debt.payments.fold(0.0, (s, p) => s + p.amount) + debt.dpAmount;
    final remaining =
        (debt.totalAmount - totalPaid).clamp(0.0, double.infinity);
    final status = remaining <= 0
        ? 'paid'
        : totalPaid > debt.dpAmount
            ? 'partial'
            : debt.status;
    await _db.update(
      'debts',
      {
        'remaining_amount': remaining,
        'status': status,
        'paid_at': remaining <= 0 ? DateTime.now().toIso8601String() : null,
      },
      where: 'id = ?',
      whereArgs: [payment.debtId],
    );
  }

  Future<void> deleteDebt(String id) async {
    await _db.delete('debt_payments', where: 'debt_id = ?', whereArgs: [id]);
    await _db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalOutstandingDebt() async {
    final result = await _db.rawQuery(
      "SELECT SUM(remaining_amount) as total FROM debts WHERE status != 'paid'",
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // ── Price Levels ──────────────────────────────────────────────────────────

  Future<List<PriceLevelModel>> getPriceLevels() async {
    final maps = await _db.query('price_levels', orderBy: 'sort_order ASC');
    return maps.map(_priceLevelFromMap).toList();
  }

  Future<void> insertPriceLevel(PriceLevelModel level, {int sortOrder = 99}) async {
    await _db.insert('price_levels', _priceLevelToMap(level, sortOrder),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updatePriceLevel(PriceLevelModel level) async {
    await _db.update(
      'price_levels',
      {'name': level.name, 'description': level.description,
       'is_default': level.isDefault ? 1 : 0},
      where: 'id = ?', whereArgs: [level.id],
    );
  }

  Future<void> setDefaultPriceLevel(String id) async {
    await _db.update('price_levels', {'is_default': 0});
    await _db.update('price_levels', {'is_default': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deletePriceLevel(String id) async {
    await _db.delete('product_price_levels',
        where: 'price_level_id = ?', whereArgs: [id]);
    await _db.delete('price_levels', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> saveProductPriceLevels(
      String productId, List<ProductPriceLevelEntry> entries) async {
    await _db.delete('product_price_levels',
        where: 'product_id = ?', whereArgs: [productId]);
    if (entries.isEmpty) return;
    final batch = _db.batch();
    for (final e in entries) {
      batch.insert('product_price_levels', {
        'product_id': productId,
        'price_level_id': e.priceLevelId,
        'price': e.price,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  PriceLevelModel _priceLevelFromMap(Map<String, Object?> m) => PriceLevelModel(
    id: m['id'] as String,
    name: m['name'] as String,
    description: m['description'] as String? ?? '',
    sortOrder: m['sort_order'] as int? ?? 0,
    isDefault: (m['is_default'] as int? ?? 0) == 1,
  );

  Map<String, Object?> _priceLevelToMap(PriceLevelModel l, int sortOrder) => {
    'id': l.id,
    'name': l.name,
    'description': l.description,
    'sort_order': sortOrder,
    'is_default': l.isDefault ? 1 : 0,
  };

  // ── Categories ────────────────────────────────────────────────────────────

  Future<List<CategoryModel>> getCategories() async {
    final maps = await _db.query('categories', orderBy: 'sort_order ASC, name ASC');
    return maps.map(_categoryFromMap).toList();
  }

  Future<void> insertCategory(CategoryModel category, {int sortOrder = 999}) async {
    await _db.insert(
      'categories',
      _categoryToMap(category, sortOrder),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCategory(CategoryModel category) async {
    await _db.update(
      'categories',
      {'name': category.name, 'icon': category.icon},
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(String id) async {
    await _db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  CategoryModel _categoryFromMap(Map<String, Object?> m) => CategoryModel(
    id: m['id'] as String,
    name: m['name'] as String,
    icon: m['icon'] as String? ?? '📦',
  );

  Map<String, Object?> _categoryToMap(CategoryModel c, int sortOrder) => {
    'id': c.id,
    'name': c.name,
    'icon': c.icon,
    'sort_order': sortOrder,
  };

  // ── Invoice Number ────────────────────────────────────────────────────────

  Future<String> generateInvoiceNumber() async {
    final result = await _db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['invoice_counter'],
    );

    int counter = 0;
    if (result.isNotEmpty) {
      counter = int.tryParse(result.first['value'] as String) ?? 0;
    }
    counter++;

    await _db.insert('settings', {
      'key': 'invoice_counter',
      'value': counter.toString(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    final now = DateTime.now();
    final date =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    return 'INV/$date/${counter.toString().padLeft(4, '0')}';
  }
}
