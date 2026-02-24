import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';

/// Provider SQLite — mendukung offline penuh tanpa jaringan.
class DatabaseProvider extends GetxService {
  static const _dbName = 'kasir_pintar.db';
  static const _dbVersion = 1;

  late Database _db;

  Future<DatabaseProvider> init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createTables,
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
        id             TEXT PRIMARY KEY,
        invoice_number TEXT NOT NULL,
        subtotal       REAL NOT NULL,
        discount       REAL NOT NULL DEFAULT 0,
        total          REAL NOT NULL,
        payment_amount REAL NOT NULL,
        change_amount  REAL NOT NULL,
        payment_method TEXT NOT NULL DEFAULT 'Tunai',
        created_at     TEXT NOT NULL,
        cashier_name   TEXT NOT NULL DEFAULT 'Kasir'
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

    await batch.commit(noResult: true);
  }

  // ── Seeding ───────────────────────────────────────────────────────────────

  Future<void> _seedIfNeeded() async {
    final count = Sqflite.firstIntValue(
          await _db.rawQuery('SELECT COUNT(*) FROM products')) ??
        0;
    if (count == 0) {
      final batch = _db.batch();
      for (final p in ProductModel.sampleProducts) {
        batch.insert('products', _productToMap(p));
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

    // Batch-load semua items sekaligus (hindari N+1 queries)
    final txIds = txMaps.map((m) => m['id'] as String).toList();
    final placeholders = List.filled(txIds.length, '?').join(', ');
    final itemMaps = await _db.rawQuery(
      'SELECT * FROM transaction_items WHERE transaction_id IN ($placeholders) ORDER BY id ASC',
      txIds,
    );

    // Group items by transaction_id
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
    // Gunakan SQLite transaction untuk atomicity
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
      });

      for (final item in transaction.items) {
        await txn.insert('transaction_items', {
          'transaction_id': transaction.id,
          'product_id': item.product.id,
          'product_name': item.product.name,   // snapshot harga saat transaksi
          'product_price': item.product.price, // tetap akurat meski produk diedit
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
    await _db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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

    await _db.insert(
      'settings',
      {'key': 'invoice_counter', 'value': counter.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final now = DateTime.now();
    final date =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    return 'INV/$date/${counter.toString().padLeft(4, '0')}';
  }
}
