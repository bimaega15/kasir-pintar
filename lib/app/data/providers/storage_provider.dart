import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/cart_item_model.dart';
import '../models/category_model.dart';
import '../models/customer_model.dart';
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
import '../models/stock_movement_model.dart';
import '../models/bahan_baku_model.dart';
import '../models/void_log_model.dart';
import '../models/expense_model.dart';
import '../models/employee_model.dart';
import '../models/attendance_model.dart';

/// Provider SQLite — mendukung offline penuh tanpa jaringan.
class DatabaseProvider extends GetxService {
  static const _dbName = 'kasir_pintar.db';
  static const _dbVersion = 19;

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
        image_path  TEXT,
        created_at  TEXT    NOT NULL,
        is_package  INTEGER NOT NULL DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE product_package_items (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id   TEXT    NOT NULL,
        item_id      TEXT    NOT NULL,
        item_name    TEXT    NOT NULL,
        item_emoji   TEXT    NOT NULL DEFAULT '📦',
        quantity     INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (product_id) REFERENCES products(id)
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
        id                 INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id     TEXT    NOT NULL,
        product_id         TEXT    NOT NULL,
        product_name       TEXT    NOT NULL,
        product_price      REAL    NOT NULL,
        product_emoji      TEXT    NOT NULL DEFAULT '📦',
        quantity           INTEGER NOT NULL,
        note               TEXT    NOT NULL DEFAULT '',
        is_package         INTEGER NOT NULL DEFAULT 0,
        package_items_json TEXT    NOT NULL DEFAULT '[]',
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
        id                  INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id            TEXT    NOT NULL,
        product_id          TEXT    NOT NULL,
        product_name        TEXT    NOT NULL,
        product_price       REAL    NOT NULL,
        product_emoji       TEXT    NOT NULL DEFAULT '📦',
        quantity            INTEGER NOT NULL,
        note                TEXT    NOT NULL DEFAULT '',
        is_package          INTEGER NOT NULL DEFAULT 0,
        package_items_json  TEXT    NOT NULL DEFAULT '[]',
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

    batch.execute('''
      CREATE TABLE stock_movements (
        id           TEXT    PRIMARY KEY,
        product_id   TEXT    NOT NULL,
        product_name TEXT    NOT NULL,
        product_emoji TEXT   NOT NULL DEFAULT '📦',
        type         TEXT    NOT NULL,
        quantity     INTEGER NOT NULL DEFAULT 0,
        qty_before   INTEGER NOT NULL DEFAULT 0,
        qty_after    INTEGER NOT NULL DEFAULT 0,
        reference_id TEXT,
        notes        TEXT    NOT NULL DEFAULT '',
        created_at   TEXT    NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE stock_opname (
        id          TEXT    PRIMARY KEY,
        notes       TEXT    NOT NULL DEFAULT '',
        status      TEXT    NOT NULL DEFAULT 'draft',
        items_count INTEGER NOT NULL DEFAULT 0,
        created_at  TEXT    NOT NULL,
        completed_at TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE stock_opname_items (
        id            TEXT    PRIMARY KEY,
        opname_id     TEXT    NOT NULL,
        product_id    TEXT    NOT NULL,
        product_name  TEXT    NOT NULL,
        product_emoji TEXT    NOT NULL DEFAULT '📦',
        system_qty    INTEGER NOT NULL DEFAULT 0,
        actual_qty    INTEGER NOT NULL DEFAULT 0,
        notes         TEXT    NOT NULL DEFAULT ''
      )
    ''');

    batch.execute('''
      CREATE TABLE bahan_baku (
        id         TEXT    PRIMARY KEY,
        name       TEXT    NOT NULL,
        unit       TEXT    NOT NULL,
        stock      REAL    NOT NULL DEFAULT 0,
        min_stock  REAL    NOT NULL DEFAULT 0,
        price      REAL    NOT NULL DEFAULT 0,
        emoji      TEXT    NOT NULL DEFAULT '📦',
        notes      TEXT    NOT NULL DEFAULT '',
        created_at TEXT    NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE bahan_baku_movements (
        id              TEXT PRIMARY KEY,
        bahan_baku_id   TEXT NOT NULL,
        bahan_baku_name TEXT NOT NULL,
        bahan_baku_emoji TEXT NOT NULL DEFAULT '📦',
        type            TEXT NOT NULL,
        quantity        REAL NOT NULL DEFAULT 0,
        qty_before      REAL NOT NULL DEFAULT 0,
        qty_after       REAL NOT NULL DEFAULT 0,
        total_cost      REAL,
        notes           TEXT NOT NULL DEFAULT '',
        created_at      TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE customers (
        id         TEXT    PRIMARY KEY,
        name       TEXT    NOT NULL,
        phone      TEXT    NOT NULL DEFAULT '',
        address    TEXT    NOT NULL DEFAULT '',
        notes      TEXT    NOT NULL DEFAULT '',
        created_at TEXT    NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE operational_expenses (
        id             TEXT    PRIMARY KEY,
        category       TEXT    NOT NULL,
        description    TEXT    NOT NULL DEFAULT '',
        amount         REAL    NOT NULL,
        payment_method TEXT    NOT NULL DEFAULT 'Tunai',
        date           TEXT    NOT NULL,
        created_by     TEXT    NOT NULL DEFAULT 'Kasir',
        notes          TEXT    NOT NULL DEFAULT '',
        created_at     TEXT    NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE employees (
        id         TEXT    PRIMARY KEY,
        name       TEXT    NOT NULL,
        role       TEXT    NOT NULL DEFAULT 'Kasir',
        phone      TEXT    NOT NULL DEFAULT '',
        is_active  INTEGER NOT NULL DEFAULT 1,
        created_at TEXT    NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE attendances (
        id            TEXT    PRIMARY KEY,
        employee_id   TEXT    NOT NULL,
        employee_name TEXT    NOT NULL,
        employee_role TEXT    NOT NULL DEFAULT '',
        date          TEXT    NOT NULL,
        status        TEXT    NOT NULL DEFAULT 'hadir',
        check_in      TEXT,
        check_out     TEXT,
        notes         TEXT    NOT NULL DEFAULT '',
        created_at    TEXT    NOT NULL,
        UNIQUE(employee_id, date)
      )
    ''');

    batch.execute('''
      CREATE TABLE app_users (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        username   TEXT    NOT NULL UNIQUE,
        password   TEXT    NOT NULL,
        role       TEXT    NOT NULL DEFAULT 'kasir',
        created_at TEXT    NOT NULL
      )
    ''');

    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 19) {
      try {
        await db.execute(
            'ALTER TABLE transaction_items ADD COLUMN is_package INTEGER NOT NULL DEFAULT 0');
        await db.execute(
            "ALTER TABLE transaction_items ADD COLUMN package_items_json TEXT NOT NULL DEFAULT '[]'");
      } catch (_) {}
    }
    if (oldVersion < 18) {
      try {
        await db.execute(
            'ALTER TABLE order_items ADD COLUMN is_package INTEGER NOT NULL DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute(
            "ALTER TABLE order_items ADD COLUMN package_items_json TEXT NOT NULL DEFAULT '[]'");
      } catch (_) {}
    }
    if (oldVersion < 17) {
      try {
        await db.execute(
            'ALTER TABLE products ADD COLUMN is_package INTEGER NOT NULL DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS product_package_items (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            product_id TEXT    NOT NULL,
            item_id    TEXT    NOT NULL,
            item_name  TEXT    NOT NULL,
            item_emoji TEXT    NOT NULL DEFAULT '📦',
            quantity   INTEGER NOT NULL DEFAULT 1,
            FOREIGN KEY (product_id) REFERENCES products(id)
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 16) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS app_users (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            username   TEXT    NOT NULL UNIQUE,
            password   TEXT    NOT NULL,
            role       TEXT    NOT NULL DEFAULT 'kasir',
            created_at TEXT    NOT NULL
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 15) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS employees (
            id TEXT PRIMARY KEY, name TEXT NOT NULL,
            role TEXT NOT NULL DEFAULT 'Kasir',
            phone TEXT NOT NULL DEFAULT '',
            is_active INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL
          )
        ''');
      } catch (_) {}
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS attendances (
            id TEXT PRIMARY KEY,
            employee_id TEXT NOT NULL, employee_name TEXT NOT NULL,
            employee_role TEXT NOT NULL DEFAULT '',
            date TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'hadir',
            check_in TEXT, check_out TEXT,
            notes TEXT NOT NULL DEFAULT '', created_at TEXT NOT NULL,
            UNIQUE(employee_id, date)
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 14) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS operational_expenses (
            id TEXT PRIMARY KEY, category TEXT NOT NULL,
            description TEXT NOT NULL DEFAULT '', amount REAL NOT NULL,
            payment_method TEXT NOT NULL DEFAULT 'Tunai',
            date TEXT NOT NULL, created_by TEXT NOT NULL DEFAULT 'Kasir',
            notes TEXT NOT NULL DEFAULT '', created_at TEXT NOT NULL
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 13) {
      try {
        await db.execute('ALTER TABLE products ADD COLUMN image_path TEXT');
      } catch (_) {}
    }
    if (oldVersion < 12) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS bahan_baku (
            id TEXT PRIMARY KEY, name TEXT NOT NULL,
            unit TEXT NOT NULL, stock REAL NOT NULL DEFAULT 0,
            min_stock REAL NOT NULL DEFAULT 0, price REAL NOT NULL DEFAULT 0,
            emoji TEXT NOT NULL DEFAULT '📦',
            notes TEXT NOT NULL DEFAULT '', created_at TEXT NOT NULL
          )
        ''');
      } catch (_) {}
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS bahan_baku_movements (
            id TEXT PRIMARY KEY, bahan_baku_id TEXT NOT NULL,
            bahan_baku_name TEXT NOT NULL,
            bahan_baku_emoji TEXT NOT NULL DEFAULT '📦',
            type TEXT NOT NULL, quantity REAL NOT NULL DEFAULT 0,
            qty_before REAL NOT NULL DEFAULT 0, qty_after REAL NOT NULL DEFAULT 0,
            total_cost REAL, notes TEXT NOT NULL DEFAULT '',
            created_at TEXT NOT NULL
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 11) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS customers (
            id TEXT PRIMARY KEY, name TEXT NOT NULL,
            phone TEXT NOT NULL DEFAULT '', address TEXT NOT NULL DEFAULT '',
            notes TEXT NOT NULL DEFAULT '', created_at TEXT NOT NULL
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 10) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS stock_movements (
            id TEXT PRIMARY KEY, product_id TEXT NOT NULL,
            product_name TEXT NOT NULL, product_emoji TEXT NOT NULL DEFAULT '📦',
            type TEXT NOT NULL, quantity INTEGER NOT NULL DEFAULT 0,
            qty_before INTEGER NOT NULL DEFAULT 0, qty_after INTEGER NOT NULL DEFAULT 0,
            reference_id TEXT, notes TEXT NOT NULL DEFAULT '',
            created_at TEXT NOT NULL
          )
        ''');
      } catch (_) {}
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS stock_opname (
            id TEXT PRIMARY KEY, notes TEXT NOT NULL DEFAULT '',
            status TEXT NOT NULL DEFAULT 'draft',
            items_count INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL, completed_at TEXT
          )
        ''');
      } catch (_) {}
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS stock_opname_items (
            id TEXT PRIMARY KEY, opname_id TEXT NOT NULL,
            product_id TEXT NOT NULL, product_name TEXT NOT NULL,
            product_emoji TEXT NOT NULL DEFAULT '📦',
            system_qty INTEGER NOT NULL DEFAULT 0,
            actual_qty INTEGER NOT NULL DEFAULT 0,
            notes TEXT NOT NULL DEFAULT ''
          )
        ''');
      } catch (_) {}
    }
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

    final bahanBakuCount =
        Sqflite.firstIntValue(
          await _db.rawQuery('SELECT COUNT(*) FROM bahan_baku'),
        ) ??
        0;
    if (bahanBakuCount == 0) {
      final batch = _db.batch();
      for (final bb in BahanBakuModel.sampleBahanBaku) {
        batch.insert('bahan_baku', bb.toMap());
      }
      await batch.commit(noResult: true);
    }

    // Seed default admin account jika belum ada
    final existingUsername = await getSetting('app_username');
    if (existingUsername == null || existingUsername.isEmpty) {
      await setSetting('app_username', 'rizky_syahputra');
      await setSetting('app_password', 'admin123#');
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

      // Load package items (isolated — failure here must not break product load)
      try {
        await _db.execute('''
          CREATE TABLE IF NOT EXISTS product_package_items (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            product_id TEXT    NOT NULL,
            item_id    TEXT    NOT NULL,
            item_name  TEXT    NOT NULL,
            item_emoji TEXT    NOT NULL DEFAULT '📦',
            quantity   INTEGER NOT NULL DEFAULT 1
          )
        ''');
        final packageMaps = await _db.query('product_package_items');
        final packageMap = <String, List<PackageItem>>{};
        for (final row in packageMaps) {
          final pid = row['product_id'] as String;
          packageMap.putIfAbsent(pid, () => []).add(PackageItem(
            productId: row['item_id'] as String,
            productName: row['item_name'] as String,
            productEmoji: row['item_emoji'] as String? ?? '📦',
            quantity: row['quantity'] as int? ?? 1,
          ));
        }
        for (final p in products) {
          p.packageItems = packageMap[p.id] ?? [];
        }
      } catch (e) {
        print('[getProducts] Warning: could not load package items: $e');
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
      if (product.isPackage) {
        await _savePackageItems(product.id, product.packageItems);
      }
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
    await _savePackageItems(product.id, product.isPackage ? product.packageItems : []);
  }

  Future<void> deleteProduct(String id) async {
    await _db.delete('product_package_items', where: 'product_id = ?', whereArgs: [id]);
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
      final imagePath = m['image_path'] as String?;
      final createdAtStr = m['created_at'] as String?;

      if (id == null || name == null || categoryId == null || priceValue == null || stockValue == null || createdAtStr == null) {
        throw FormatException('Missing required fields in product map: $m');
      }

      final price = (priceValue as num).toDouble();
      final stock = stockValue as int;

      final isPackageVal = m['is_package'];
      final isPackage = isPackageVal != null && isPackageVal != 0;

      return ProductModel(
        id: id,
        name: name,
        categoryId: categoryId,
        price: price,
        stock: stock,
        description: description,
        emoji: emoji,
        imagePath: imagePath,
        createdAt: DateTime.parse(createdAtStr),
        isPackage: isPackage,
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
    'image_path': p.imagePath,
    'created_at': p.createdAt.toIso8601String(),
    'is_package': p.isPackage ? 1 : 0,
  };

  Future<void> _savePackageItems(String productId, List<PackageItem> items) async {
    await _db.delete('product_package_items',
        where: 'product_id = ?', whereArgs: [productId]);
    for (final item in items) {
      await _db.insert('product_package_items', {
        'product_id': productId,
        'item_id': item.productId,
        'item_name': item.productName,
        'item_emoji': item.productEmoji,
        'quantity': item.quantity,
      });
    }
  }

  // ── Customers ──────────────────────────────────────────────────────────────

  Future<List<CustomerModel>> getCustomers() async {
    try {
      final maps = await _db.query('customers', orderBy: 'created_at ASC');
      final customers = maps.map(_customerFromMap).toList();

      // Aggregate transaction stats per customer_name from the transactions table
      final statsMaps = await _db.rawQuery('''
        SELECT customer_name,
               COUNT(*) AS tx_count,
               COALESCE(SUM(total), 0) AS tx_total
        FROM transactions
        WHERE customer_name != ''
        GROUP BY customer_name
      ''');

      final statsLookup = <String, Map<String, dynamic>>{
        for (final row in statsMaps)
          (row['customer_name'] as String): row,
      };

      for (final customer in customers) {
        final stats = statsLookup[customer.name];
        if (stats != null) {
          customer.totalTransactions = (stats['tx_count'] as int?) ?? 0;
          customer.totalSpent =
              (stats['tx_total'] as num?)?.toDouble() ?? 0.0;
        }
      }

      return customers;
    } catch (e) {
      print('[getCustomers] Error: $e');
      rethrow;
    }
  }

  Future<void> insertCustomer(CustomerModel customer) async {
    try {
      final map = _customerToMap(customer);
      await _db.insert('customers', map);
    } catch (e) {
      print('[insertCustomer] Error: $e');
      rethrow;
    }
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    try {
      await _db.update(
        'customers',
        _customerToMap(customer),
        where: 'id = ?',
        whereArgs: [customer.id],
      );
    } catch (e) {
      print('[updateCustomer] Error: $e');
      rethrow;
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await _db.delete('customers', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      print('[deleteCustomer] Error: $e');
      rethrow;
    }
  }

  Future<List<TransactionModel>> getTransactionsByCustomerId(String customerId) async {
    try {
      // First get customer name
      final customerMaps = await _db.query(
        'customers',
        where: 'id = ?',
        whereArgs: [customerId],
      );

      if (customerMaps.isEmpty) {
        return [];
      }

      final customerName = customerMaps.first['name'] as String;

      // Then get all transactions with that customer name
      final txMaps = await _db.query(
        'transactions',
        where: 'customer_name = ?',
        whereArgs: [customerName],
        orderBy: 'created_at DESC',
      );

      if (txMaps.isEmpty) return [];

      // Get all transaction items
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
          serviceChargeAmount: (m['service_charge_amount'] as num?)?.toDouble() ?? 0,
          customerName: m['customer_name'] as String? ?? '',
        );
      }).toList();
    } catch (e) {
      print('[getTransactionsByCustomerId] Error: $e');
      rethrow;
    }
  }

  CustomerModel _customerFromMap(Map<String, Object?> m) {
    try {
      final id = m['id'] as String?;
      final name = m['name'] as String?;
      final phone = m['phone'] as String? ?? '';
      final address = m['address'] as String? ?? '';
      final notes = m['notes'] as String? ?? '';
      final createdAtStr = m['created_at'] as String?;

      if (id == null || name == null || createdAtStr == null) {
        throw FormatException('Missing required fields in customer map: $m');
      }

      return CustomerModel(
        id: id,
        name: name,
        phone: phone,
        address: address,
        notes: notes,
        createdAt: DateTime.parse(createdAtStr),
      );
    } catch (e) {
      print('[_customerFromMap] Error parsing map: $m with error: $e');
      rethrow;
    }
  }

  Map<String, Object?> _customerToMap(CustomerModel c) => {
    'id': c.id,
    'name': c.name,
    'phone': c.phone,
    'address': c.address,
    'notes': c.notes,
    'created_at': c.createdAt.toIso8601String(),
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

  Future<OrderModel?> getOrderByTableId(String tableId) async {
    final maps = await _db.rawQuery(
      "SELECT * FROM orders WHERE table_id = ? AND kitchen_status != 'paid' AND kitchen_status != 'parked' ORDER BY created_at DESC LIMIT 1",
      [tableId],
    );
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
          'is_package': item.isPackage ? 1 : 0,
          'package_items_json': jsonEncode(
            item.packageItems.map((p) => p.toJson()).toList(),
          ),
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
      final pkgJson = m['package_items_json'] as String? ?? '[]';
      List<PackageItem> pkgItems = [];
      try {
        final decoded = jsonDecode(pkgJson) as List<dynamic>;
        pkgItems = decoded
            .map((e) => PackageItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (_) {}
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
              isPackage: (m['is_package'] as int? ?? 0) != 0,
              packageItems: pkgItems,
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

  Future<List<TransactionModel>> getTransactions({
    String? datePrefix,
    String? cashierName,
    DateTime? shiftStart,
    DateTime? shiftEnd,
  }) async {
    final List<Map<String, Object?>> txMaps;

    final whereParts = <String>[];
    final whereArgs = <dynamic>[];

    if (datePrefix != null) {
      whereParts.add('created_at LIKE ?');
      whereArgs.add('$datePrefix%');
    }
    if (cashierName != null) {
      whereParts.add('cashier_name = ?');
      whereArgs.add(cashierName);
    }
    if (shiftStart != null) {
      whereParts.add('created_at >= ?');
      whereArgs.add(shiftStart.toIso8601String());
    }
    if (shiftEnd != null) {
      whereParts.add('created_at <= ?');
      whereArgs.add(shiftEnd.toIso8601String());
    }

    txMaps = await _db.query(
      'transactions',
      where: whereParts.isEmpty ? null : whereParts.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'created_at DESC',
    );

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
          'is_package': item.product.isPackage ? 1 : 0,
          'package_items_json': jsonEncode(
              item.product.packageItems.map((p) => p.toJson()).toList()),
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
    final isPackage = (m['is_package'] as int? ?? 0) == 1;
    List<PackageItem> packageItems = [];
    if (isPackage) {
      try {
        final raw = m['package_items_json'] as String? ?? '[]';
        final decoded = jsonDecode(raw) as List<dynamic>;
        packageItems =
            decoded.map((e) => PackageItem.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
    final product = ProductModel(
      id: m['product_id'] as String,
      name: m['product_name'] as String,
      categoryId: 'other',
      price: (m['product_price'] as num).toDouble(),
      emoji: m['product_emoji'] as String? ?? '📦',
      isPackage: isPackage,
    )..packageItems = packageItems;
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

  // ── App Users (Kasir Accounts) ────────────────────────────────────────────

  Future<void> insertAppUser({
    required String username,
    required String password,
    String role = 'kasir',
  }) async {
    await _db.insert('app_users', {
      'username': username,
      'password': password,
      'role': role,
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getAppUserByUsername(String username) async {
    final result = await _db.query(
      'app_users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    return result.isEmpty ? null : result.first;
  }

  Future<bool> appUsernameExists(String username) async {
    final result = await _db.query(
      'app_users',
      columns: ['id'],
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getAllAppUsers() async {
    return await _db.query('app_users', orderBy: 'created_at ASC');
  }

  Future<void> deleteAppUser(String username) async {
    await _db.delete('app_users', where: 'username = ?', whereArgs: [username]);
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

  Future<Map<String, dynamic>> getShiftStats({
    required DateTime openedAt,
    DateTime? closedAt,
  }) async {
    final end = closedAt ?? DateTime.now();
    final startIso = openedAt.toIso8601String();
    final endIso = end.toIso8601String();

    final aggResult = await _db.rawQuery('''
      SELECT COUNT(*) as tx_count,
             COALESCE(SUM(total), 0) as revenue,
             COALESCE(SUM(subtotal), 0) as subtotal_sum,
             COALESCE(SUM(discount), 0) as discount_sum,
             COALESCE(SUM(tax_amount), 0) as tax_sum,
             COALESCE(SUM(service_charge_amount), 0) as sc_sum
      FROM transactions
      WHERE created_at >= ? AND created_at <= ?
    ''', [startIso, endIso]);

    final paymentResult = await _db.rawQuery('''
      SELECT payment_method,
             COALESCE(SUM(total), 0) as total,
             COUNT(*) as count
      FROM transactions
      WHERE created_at >= ? AND created_at <= ?
      GROUP BY payment_method
      ORDER BY total DESC
    ''', [startIso, endIso]);

    final productResult = await _db.rawQuery('''
      SELECT ti.product_name, ti.product_emoji,
             SUM(ti.quantity) as qty,
             SUM(CAST(ti.quantity AS REAL) * ti.product_price) as total
      FROM transaction_items ti
      INNER JOIN transactions t ON t.id = ti.transaction_id
      WHERE t.created_at >= ? AND t.created_at <= ?
      GROUP BY ti.product_name, ti.product_emoji
      ORDER BY qty DESC
      LIMIT 10
    ''', [startIso, endIso]);

    final agg = aggResult.first;
    return {
      'tx_count': agg['tx_count'] as int,
      'revenue': (agg['revenue'] as num).toDouble(),
      'subtotal': (agg['subtotal_sum'] as num).toDouble(),
      'discount': (agg['discount_sum'] as num).toDouble(),
      'tax': (agg['tax_sum'] as num).toDouble(),
      'service_charge': (agg['sc_sum'] as num).toDouble(),
      'payments': paymentResult
          .map((r) => {
                'method': r['payment_method'] as String,
                'total': (r['total'] as num).toDouble(),
                'count': r['count'] as int,
              })
          .toList(),
      'products': productResult
          .map((r) => {
                'name': r['product_name'] as String,
                'emoji': r['product_emoji'] as String? ?? '📦',
                'qty': r['qty'] as int,
                'total': (r['total'] as num).toDouble(),
              })
          .toList(),
    };
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

  Future<Map<String, dynamic>> getDebtStats() async {
    final summary = await _db.rawQuery('''
      SELECT
        COUNT(*) as total_count,
        COALESCE(SUM(total_amount), 0) as total_amount,
        COALESCE(SUM(remaining_amount), 0) as total_remaining,
        COALESCE(SUM(CASE WHEN status = 'unpaid' THEN 1 ELSE 0 END), 0) as unpaid_count,
        COALESCE(SUM(CASE WHEN status = 'partial' THEN 1 ELSE 0 END), 0) as partial_count,
        COALESCE(SUM(CASE WHEN status = 'paid' THEN 1 ELSE 0 END), 0) as paid_count,
        COALESCE(SUM(CASE WHEN status = 'unpaid' THEN remaining_amount ELSE 0 END), 0) as unpaid_amount,
        COALESCE(SUM(CASE WHEN status = 'partial' THEN remaining_amount ELSE 0 END), 0) as partial_amount,
        COALESCE(SUM(CASE WHEN status = 'paid' THEN total_amount ELSE 0 END), 0) as paid_amount
      FROM debts
    ''');

    final aging = await _db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN julianday('now') - julianday(created_at) < 7
          THEN remaining_amount ELSE 0 END), 0) as age_0_7,
        COALESCE(SUM(CASE WHEN julianday('now') - julianday(created_at) >= 7
          AND julianday('now') - julianday(created_at) < 30
          THEN remaining_amount ELSE 0 END), 0) as age_7_30,
        COALESCE(SUM(CASE WHEN julianday('now') - julianday(created_at) >= 30
          THEN remaining_amount ELSE 0 END), 0) as age_over_30,
        COUNT(CASE WHEN julianday('now') - julianday(created_at) < 7 THEN 1 END) as age_0_7_count,
        COUNT(CASE WHEN julianday('now') - julianday(created_at) >= 7
          AND julianday('now') - julianday(created_at) < 30 THEN 1 END) as age_7_30_count,
        COUNT(CASE WHEN julianday('now') - julianday(created_at) >= 30 THEN 1 END) as age_over_30_count
      FROM debts WHERE status != 'paid'
    ''');

    final topDebtors = await _db.rawQuery('''
      SELECT customer_name, invoice_number, total_amount, remaining_amount, status, created_at
      FROM debts
      WHERE status != 'paid'
      ORDER BY remaining_amount DESC
      LIMIT 10
    ''');

    return {
      'summary': summary.first,
      'aging': aging.first,
      'top_debtors': topDebtors,
    };
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

  // ── Reset All Data ────────────────────────────────────────────────────────

  /// Hapus semua data operasional. Tabel settings & app_users tetap dipertahankan.
  Future<void> resetAllData() async {
    // Urutan: child table dulu agar tidak melanggar foreign key
    const tables = [
      'attendances',
      'debt_payments',
      'debts',
      'split_transactions',
      'void_logs',
      'order_payments',
      'order_items',
      'orders',
      'transaction_payments',
      'transaction_items',
      'transactions',
      'stock_opname_items',
      'stock_opname',
      'stock_movements',
      'bahan_baku_movements',
      'bahan_baku',
      'operational_expenses',
      'customers',
      'product_price_levels',
      'product_package_items',
      'products',
      'price_levels',
      'categories',
      'shifts',
      'tables',
      'employees',
    ];

    await _db.transaction((txn) async {
      await txn.execute('PRAGMA foreign_keys = OFF');
      for (final t in tables) {
        await txn.delete(t);
      }
      // Reset invoice counter
      await txn.delete('settings', where: 'key = ?', whereArgs: ['invoice_counter']);
      await txn.execute('PRAGMA foreign_keys = ON');
    });
  }

  // ── Seed Data Mie Gacor ───────────────────────────────────────────────────

  /// Hapus semua produk & kategori lama, lalu isi dengan data menu Mie Gacor.
  Future<void> seedMieGacorData() async {
    await _db.transaction((txn) async {
      // Clear existing data
      await txn.delete('product_package_items');
      await txn.delete('product_price_levels');
      await txn.delete('products');
      await txn.delete('categories');

      // Insert categories
      final categories = [
        {'id': 'mie', 'name': 'Mie Gacor', 'icon': '🍜', 'sort_order': 1},
        {'id': 'toping', 'name': 'Toping', 'icon': '🌶️', 'sort_order': 2},
        {'id': 'minuman', 'name': 'Minuman', 'icon': '🥤', 'sort_order': 3},
        {'id': 'paket', 'name': 'Paket', 'icon': '📦', 'sort_order': 4},
      ];
      for (final c in categories) {
        await txn.insert('categories', c, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      final now = DateTime.now().toIso8601String();

      // Insert produk mie
      final mieProducts = [
        {'id': 'mie_gacor_aja', 'name': 'Mie Gacor Aja', 'category_id': 'mie', 'price': 8000.0, 'stock': 100, 'description': 'Ayam, Pangsit, Mie', 'emoji': '🍜', 'image_path': null, 'created_at': now, 'is_package': 0},
        {'id': 'mie_sedap_gacor_aja', 'name': 'Mie Sedap Gacor Aja', 'category_id': 'mie', 'price': 8000.0, 'stock': 100, 'description': 'Ayam, Pangsit, Mie Sedap', 'emoji': '🍜', 'image_path': null, 'created_at': now, 'is_package': 0},
        {'id': 'mie_gacor_brutal', 'name': 'Mie Gacor Brutal', 'category_id': 'mie', 'price': 10000.0, 'stock': 100, 'description': 'Ayam, Pangsit, Smoke Beef/Sosis, Level 1-5', 'emoji': '🌶️', 'image_path': null, 'created_at': now, 'is_package': 0},
        {'id': 'mie_sedap_gacor_brutal', 'name': 'Mie Sedap Gacor Brutal', 'category_id': 'mie', 'price': 10000.0, 'stock': 100, 'description': 'Ayam, Smoke Beef/Sosis, Level 1-5', 'emoji': '🌶️', 'image_path': null, 'created_at': now, 'is_package': 0},
      ];

      // Insert toping
      final topingProducts = [
        {'id': 'toping_sosis', 'name': 'Sosis', 'category_id': 'toping', 'price': 5000.0, 'stock': 100, 'description': '', 'emoji': '🌭', 'image_path': null, 'created_at': now, 'is_package': 0},
        {'id': 'toping_nugget', 'name': 'Nugget', 'category_id': 'toping', 'price': 5000.0, 'stock': 100, 'description': '', 'emoji': '🍗', 'image_path': null, 'created_at': now, 'is_package': 0},
        {'id': 'toping_bakso', 'name': 'Bakso', 'category_id': 'toping', 'price': 5000.0, 'stock': 100, 'description': '', 'emoji': '🥩', 'image_path': null, 'created_at': now, 'is_package': 0},
        {'id': 'toping_pangsit', 'name': 'Pangsit', 'category_id': 'toping', 'price': 5000.0, 'stock': 100, 'description': '', 'emoji': '🥟', 'image_path': null, 'created_at': now, 'is_package': 0},
      ];

      // Insert minuman
      final minumanProducts = [
        {'id': 'es_teh_manis', 'name': 'Es Teh Manis', 'category_id': 'minuman', 'price': 4000.0, 'stock': 100, 'description': '', 'emoji': '🧋', 'image_path': null, 'created_at': now, 'is_package': 0},
        {'id': 'lemon_tea', 'name': 'Lemon Tea', 'category_id': 'minuman', 'price': 5000.0, 'stock': 100, 'description': '', 'emoji': '🍋', 'image_path': null, 'created_at': now, 'is_package': 0},
        {'id': 'green_tea', 'name': 'Green Tea', 'category_id': 'minuman', 'price': 5000.0, 'stock': 100, 'description': '', 'emoji': '🍵', 'image_path': null, 'created_at': now, 'is_package': 0},
      ];

      // Insert paket (isPackage = 1)
      final paketProducts = [
        {'id': 'paket_1_mie_gacor', 'name': 'Paket Gacor 1 (Mie Gacor)', 'category_id': 'paket', 'price': 12000.0, 'stock': 100, 'description': 'Mie Gacor + Es Teh Manis', 'emoji': '📦', 'image_path': null, 'created_at': now, 'is_package': 1},
        {'id': 'paket_1_mie_sedap', 'name': 'Paket Gacor 1 (Mie Sedap)', 'category_id': 'paket', 'price': 12000.0, 'stock': 100, 'description': 'Mie Sedap + Es Teh Manis', 'emoji': '📦', 'image_path': null, 'created_at': now, 'is_package': 1},
        {'id': 'paket_2_mie_gacor', 'name': 'Paket Gacor 2 (Mie Gacor)', 'category_id': 'paket', 'price': 13000.0, 'stock': 100, 'description': 'Mie Gacor + Lemon Tea', 'emoji': '📦', 'image_path': null, 'created_at': now, 'is_package': 1},
        {'id': 'paket_2_mie_sedap', 'name': 'Paket Gacor 2 (Mie Sedap)', 'category_id': 'paket', 'price': 13000.0, 'stock': 100, 'description': 'Mie Sedap + Lemon Tea', 'emoji': '📦', 'image_path': null, 'created_at': now, 'is_package': 1},
        {'id': 'paket_3_mie_gacor', 'name': 'Paket Gacor 3 (Mie Gacor)', 'category_id': 'paket', 'price': 13000.0, 'stock': 100, 'description': 'Mie Gacor + Green Tea', 'emoji': '📦', 'image_path': null, 'created_at': now, 'is_package': 1},
        {'id': 'paket_3_mie_sedap', 'name': 'Paket Gacor 3 (Mie Sedap)', 'category_id': 'paket', 'price': 13000.0, 'stock': 100, 'description': 'Mie Sedap + Green Tea', 'emoji': '📦', 'image_path': null, 'created_at': now, 'is_package': 1},
      ];

      for (final p in [...mieProducts, ...topingProducts, ...minumanProducts, ...paketProducts]) {
        await txn.insert('products', p, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // Insert package items
      final packageItems = [
        // Paket 1 Mie Gacor
        {'product_id': 'paket_1_mie_gacor', 'item_id': 'mie_gacor_aja', 'item_name': 'Mie Gacor Aja', 'item_emoji': '🍜', 'quantity': 1},
        {'product_id': 'paket_1_mie_gacor', 'item_id': 'es_teh_manis', 'item_name': 'Es Teh Manis', 'item_emoji': '🧋', 'quantity': 1},
        // Paket 1 Mie Sedap
        {'product_id': 'paket_1_mie_sedap', 'item_id': 'mie_sedap_gacor_aja', 'item_name': 'Mie Sedap Gacor Aja', 'item_emoji': '🍜', 'quantity': 1},
        {'product_id': 'paket_1_mie_sedap', 'item_id': 'es_teh_manis', 'item_name': 'Es Teh Manis', 'item_emoji': '🧋', 'quantity': 1},
        // Paket 2 Mie Gacor
        {'product_id': 'paket_2_mie_gacor', 'item_id': 'mie_gacor_aja', 'item_name': 'Mie Gacor Aja', 'item_emoji': '🍜', 'quantity': 1},
        {'product_id': 'paket_2_mie_gacor', 'item_id': 'lemon_tea', 'item_name': 'Lemon Tea', 'item_emoji': '🍋', 'quantity': 1},
        // Paket 2 Mie Sedap
        {'product_id': 'paket_2_mie_sedap', 'item_id': 'mie_sedap_gacor_aja', 'item_name': 'Mie Sedap Gacor Aja', 'item_emoji': '🍜', 'quantity': 1},
        {'product_id': 'paket_2_mie_sedap', 'item_id': 'lemon_tea', 'item_name': 'Lemon Tea', 'item_emoji': '🍋', 'quantity': 1},
        // Paket 3 Mie Gacor
        {'product_id': 'paket_3_mie_gacor', 'item_id': 'mie_gacor_aja', 'item_name': 'Mie Gacor Aja', 'item_emoji': '🍜', 'quantity': 1},
        {'product_id': 'paket_3_mie_gacor', 'item_id': 'green_tea', 'item_name': 'Green Tea', 'item_emoji': '🍵', 'quantity': 1},
        // Paket 3 Mie Sedap
        {'product_id': 'paket_3_mie_sedap', 'item_id': 'mie_sedap_gacor_aja', 'item_name': 'Mie Sedap Gacor Aja', 'item_emoji': '🍜', 'quantity': 1},
        {'product_id': 'paket_3_mie_sedap', 'item_id': 'green_tea', 'item_name': 'Green Tea', 'item_emoji': '🍵', 'quantity': 1},
      ];

      for (final item in packageItems) {
        await txn.insert('product_package_items', item, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  // ── SQL Backup & Restore ─────────────────────────────────────────────────

  /// Generate SQL dump seluruh database (hanya data, bukan schema).
  Future<String> exportToSql() async {
    final buffer = StringBuffer();
    final now = DateTime.now();
    buffer.writeln('-- Kasir Pintar Sasbim Database Backup');
    buffer.writeln('-- Generated: ${now.toIso8601String()}');
    buffer.writeln('-- DB Version: $_dbVersion');
    buffer.writeln();

    // Ambil semua tabel user (bukan tabel internal sqlite)
    final tables = await _db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
    );

    for (final tableRow in tables) {
      final tableName = tableRow['name'] as String;
      buffer.writeln('-- [$tableName]');
      buffer.writeln('DELETE FROM "$tableName";');

      final rows = await _db.query(tableName);
      if (rows.isNotEmpty) {
        final cols = rows.first.keys.map((c) => '"$c"').join(', ');
        for (final row in rows) {
          final vals = row.values.map(_sqlLiteral).join(', ');
          buffer.writeln('INSERT INTO "$tableName" ($cols) VALUES ($vals);');
        }
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  String _sqlLiteral(dynamic v) {
    if (v == null) return 'NULL';
    if (v is int || v is double) return v.toString();
    // String & fallback: escape single quotes
    return "'${v.toString().replaceAll("'", "''")}'";
  }

  /// Jalankan SQL dump untuk menggantikan seluruh isi database.
  Future<void> importFromSql(String sqlContent) async {
    final statements = _parseSqlStatements(sqlContent);
    // Jalankan langsung tanpa transaction wrapper karena beberapa statement
    // (PRAGMA) tidak bisa di dalam transaction sqflite
    await _db.execute('PRAGMA foreign_keys = OFF');
    for (final stmt in statements) {
      final trimmed = stmt.trim();
      if (trimmed.isEmpty) continue;
      // Skip komentar
      if (trimmed.startsWith('--')) continue;
      // Skip PRAGMA (sudah dihandle di luar)
      if (trimmed.toUpperCase().startsWith('PRAGMA')) continue;
      try {
        await _db.execute(trimmed);
      } catch (e) {
        debugPrint('[importFromSql] Error: $e\nStatement: $trimmed');
        rethrow;
      }
    }
    await _db.execute('PRAGMA foreign_keys = ON');
  }

  List<String> _parseSqlStatements(String sql) {
    final statements = <String>[];
    final current = StringBuffer();
    bool inString = false;

    for (int i = 0; i < sql.length; i++) {
      final ch = sql[i];
      if (ch == "'" && !inString) {
        inString = true;
        current.write(ch);
      } else if (ch == "'" && inString) {
        // Escaped quote: ''
        if (i + 1 < sql.length && sql[i + 1] == "'") {
          current.write("''");
          i++;
        } else {
          inString = false;
          current.write(ch);
        }
      } else if (ch == ';' && !inString) {
        final stmt = current.toString().trim();
        if (stmt.isNotEmpty) statements.add(stmt);
        current.clear();
      } else {
        current.write(ch);
      }
    }
    final remaining = current.toString().trim();
    if (remaining.isNotEmpty) statements.add(remaining);
    return statements;
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

  // ── Stock Movements ───────────────────────────────────────────────────────

  Future<void> insertStockMovement(StockMovementModel m) async {
    await _db.insert('stock_movements', m.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<StockMovementModel>> getStockMovements(
      {String? productId, int limit = 100}) async {
    final maps = await _db.query(
      'stock_movements',
      where: productId != null ? 'product_id = ?' : null,
      whereArgs: productId != null ? [productId] : null,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return maps.map((m) => StockMovementModel.fromMap(m)).toList();
  }

  Future<void> adjustProductStock(String productId, int newQty) async {
    await _db.update(
      'products',
      {'stock': newQty},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  // ── Stock Opname ──────────────────────────────────────────────────────────

  Future<void> insertStockOpname(StockOpnameModel opname) async {
    await _db.insert('stock_opname', opname.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateStockOpname(StockOpnameModel opname) async {
    await _db.update(
      'stock_opname',
      {
        'notes': opname.notes,
        'status': opname.status,
        'items_count': opname.itemsCount,
        'completed_at': opname.completedAt?.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [opname.id],
    );
  }

  Future<List<StockOpnameModel>> getStockOpnames() async {
    final maps =
        await _db.query('stock_opname', orderBy: 'created_at DESC');
    return maps.map((m) => StockOpnameModel.fromMap(m)).toList();
  }

  Future<List<StockOpnameItemModel>> getStockOpnameItems(
      String opnameId) async {
    final maps = await _db.query(
      'stock_opname_items',
      where: 'opname_id = ?',
      whereArgs: [opnameId],
      orderBy: 'product_name ASC',
    );
    return maps.map((m) => StockOpnameItemModel.fromMap(m)).toList();
  }

  Future<void> upsertStockOpnameItem(StockOpnameItemModel item) async {
    await _db.insert('stock_opname_items', item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteStockOpname(String id) async {
    await _db.delete('stock_opname_items',
        where: 'opname_id = ?', whereArgs: [id]);
    await _db.delete('stock_opname', where: 'id = ?', whereArgs: [id]);
  }

  // ── Bahan Baku ────────────────────────────────────────────────────────────

  Future<List<BahanBakuModel>> getBahanBakuList() async {
    final maps = await _db.query('bahan_baku', orderBy: 'name ASC');
    return maps.map((m) => BahanBakuModel.fromMap(m)).toList();
  }

  Future<BahanBakuModel?> getBahanBakuById(String id) async {
    final maps =
        await _db.query('bahan_baku', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return BahanBakuModel.fromMap(maps.first);
  }

  Future<void> insertBahanBaku(BahanBakuModel bb) async {
    await _db.insert('bahan_baku', bb.toMap());
  }

  Future<void> updateBahanBaku(BahanBakuModel bb) async {
    await _db.update(
      'bahan_baku',
      {
        'name': bb.name,
        'unit': bb.unit,
        'stock': bb.stock,
        'min_stock': bb.minStock,
        'price': bb.price,
        'emoji': bb.emoji,
        'notes': bb.notes,
      },
      where: 'id = ?',
      whereArgs: [bb.id],
    );
  }

  Future<void> updateBahanBakuStock(String id, double newStock) async {
    await _db.update(
      'bahan_baku',
      {'stock': newStock},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteBahanBaku(String id) async {
    await _db.delete('bahan_baku_movements',
        where: 'bahan_baku_id = ?', whereArgs: [id]);
    await _db.delete('bahan_baku', where: 'id = ?', whereArgs: [id]);
  }

  // ── Bahan Baku Movements ──────────────────────────────────────────────────

  Future<void> insertBahanBakuMovement(BahanBakuMovementModel m) async {
    await _db.insert('bahan_baku_movements', m.toMap());
  }

  Future<List<BahanBakuMovementModel>> getBahanBakuMovements({
    String? bahanBakuId,
    int limit = 100,
  }) async {
    final maps = await _db.query(
      'bahan_baku_movements',
      where: bahanBakuId != null ? 'bahan_baku_id = ?' : null,
      whereArgs: bahanBakuId != null ? [bahanBakuId] : null,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return maps.map((m) => BahanBakuMovementModel.fromMap(m)).toList();
  }

  // ── Operational Expenses ──────────────────────────────────────────────────

  Future<List<ExpenseModel>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String? where;
    List<dynamic>? whereArgs;
    if (startDate != null && endDate != null) {
      where = 'date >= ? AND date <= ?';
      whereArgs = [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ];
    }
    final maps = await _db.query(
      'operational_expenses',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'date DESC, created_at DESC',
    );
    return maps.map((m) => ExpenseModel.fromMap(m)).toList();
  }

  Future<void> insertExpense(ExpenseModel expense) async {
    await _db.insert('operational_expenses', expense.toMap());
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    await _db.update(
      'operational_expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<void> deleteExpense(String id) async {
    await _db.delete('operational_expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalExpenses({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String whereClause = '';
    List<dynamic> whereArgs = [];
    if (startDate != null && endDate != null) {
      whereClause = 'WHERE date >= ? AND date <= ?';
      whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
    }
    final result = await _db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM operational_expenses $whereClause',
      whereArgs.isEmpty ? null : whereArgs,
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, double>> getExpensesByCategory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String whereClause = '';
    List<dynamic> whereArgs = [];
    if (startDate != null && endDate != null) {
      whereClause = 'WHERE date >= ? AND date <= ?';
      whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
    }
    final result = await _db.rawQuery(
      'SELECT category, COALESCE(SUM(amount), 0) as total FROM operational_expenses $whereClause GROUP BY category ORDER BY total DESC',
      whereArgs.isEmpty ? null : whereArgs,
    );
    return {for (final r in result) r['category'] as String: (r['total'] as num).toDouble()};
  }

  // ── Employees ─────────────────────────────────────────────────────────────

  Future<List<EmployeeModel>> getEmployees({bool activeOnly = false}) async {
    final maps = await _db.query(
      'employees',
      where: activeOnly ? 'is_active = 1' : null,
      orderBy: 'name ASC',
    );
    return maps.map((m) => EmployeeModel.fromMap(m)).toList();
  }

  /// Load all registered app_users as EmployeeModel (username = id & name).
  Future<List<EmployeeModel>> getAppUsersAsEmployees() async {
    final maps = await _db.query('app_users', orderBy: 'created_at ASC');
    return maps.map((m) {
      final username = m['username'] as String;
      final role = m['role'] as String? ?? 'kasir';
      return EmployeeModel(
        id: username,
        name: username,
        role: role == 'admin' ? 'Admin' : 'Kasir',
        phone: '',
        isActive: true,
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
    }).toList();
  }

  Future<void> insertEmployee(EmployeeModel employee) async {
    await _db.insert('employees', employee.toMap());
  }

  Future<void> updateEmployee(EmployeeModel employee) async {
    await _db.update(
      'employees',
      employee.toMap(),
      where: 'id = ?',
      whereArgs: [employee.id],
    );
  }

  Future<void> deleteEmployee(String id) async {
    await _db.delete('employees', where: 'id = ?', whereArgs: [id]);
    await _db.delete('attendances', where: 'employee_id = ?', whereArgs: [id]);
  }

  // ── Attendances ───────────────────────────────────────────────────────────

  Future<List<AttendanceModel>> getAttendancesByDate(DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day).toIso8601String();
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
    final maps = await _db.query(
      'attendances',
      where: 'date >= ? AND date <= ?',
      whereArgs: [dayStart, dayEnd],
      orderBy: 'employee_name ASC',
    );
    return maps.map((m) => AttendanceModel.fromMap(m)).toList();
  }

  Future<List<AttendanceModel>> getAttendancesByEmployee(
      String employeeId, {DateTime? startDate, DateTime? endDate}) async {
    String? where;
    List<dynamic>? whereArgs;
    if (startDate != null && endDate != null) {
      where = 'employee_id = ? AND date >= ? AND date <= ?';
      whereArgs = [
        employeeId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ];
    } else {
      where = 'employee_id = ?';
      whereArgs = [employeeId];
    }
    final maps = await _db.query(
      'attendances',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );
    return maps.map((m) => AttendanceModel.fromMap(m)).toList();
  }

  Future<AttendanceModel?> getAttendanceByEmployeeDate(
      String employeeId, DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day).toIso8601String();
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
    final maps = await _db.query(
      'attendances',
      where: 'employee_id = ? AND date >= ? AND date <= ?',
      whereArgs: [employeeId, dayStart, dayEnd],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return AttendanceModel.fromMap(maps.first);
  }

  Future<void> insertAttendance(AttendanceModel a) async {
    await _db.insert('attendances', a.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateAttendance(AttendanceModel a) async {
    await _db.update(
      'attendances',
      a.toMap(),
      where: 'id = ?',
      whereArgs: [a.id],
    );
  }

  Future<void> deleteAttendance(String id) async {
    await _db.delete('attendances', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, int>> getAttendanceSummary(
      {required DateTime startDate, required DateTime endDate}) async {
    final result = await _db.rawQuery(
      '''SELECT status, COUNT(*) as count FROM attendances
         WHERE date >= ? AND date <= ?
         GROUP BY status''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    return {for (final r in result) r['status'] as String: r['count'] as int};
  }
}
