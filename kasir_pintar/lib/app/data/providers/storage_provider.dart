import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/cart_item_model.dart';
import '../models/order_item_model.dart';
import '../models/order_model.dart';
import '../models/payment_entry_model.dart';
import '../models/product_model.dart';
import '../models/table_model.dart';
import '../models/transaction_model.dart';

/// Provider SQLite — mendukung offline penuh tanpa jaringan.
class DatabaseProvider extends GetxService {
  static const _dbName = 'kasir_pintar.db';
  static const _dbVersion = 3;

  late Database _db;

  Future<DatabaseProvider> init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    _db = await openDatabase(
      path,
      version: _dbVersion,
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
        customer_name         TEXT NOT NULL DEFAULT ''
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

    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
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
  }

  // ── Products ──────────────────────────────────────────────────────────────

  Future<List<ProductModel>> getProducts() async {
    final maps = await _db.query('products', orderBy: 'created_at ASC');
    return maps.map(_productFromMap).toList();
  }

  Future<void> insertProduct(ProductModel product) async {
    await _db.insert('products', _productToMap(product));
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

  ProductModel _productFromMap(Map<String, Object?> m) => ProductModel(
    id: m['id'] as String,
    name: m['name'] as String,
    categoryId: m['category_id'] as String,
    price: (m['price'] as num).toDouble(),
    stock: m['stock'] as int,
    description: m['description'] as String? ?? '',
    emoji: m['emoji'] as String? ?? '📦',
    createdAt: DateTime.parse(m['created_at'] as String),
  );

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
      "SELECT * FROM orders WHERE kitchen_status != 'paid' ORDER BY created_at ASC",
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

  Future<void> insertTransaction(TransactionModel transaction) async {
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
