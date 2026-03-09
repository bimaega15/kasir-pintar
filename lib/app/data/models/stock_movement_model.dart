import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class StockMovementType {
  static const purchase = 'purchase';
  static const sale = 'sale';
  static const opname = 'opname';
  static const adjustmentIn = 'adjustment_in';
  static const adjustmentOut = 'adjustment_out';

  static String label(String type) =>
      const {
        'purchase': 'Stok Masuk',
        'sale': 'Terjual',
        'opname': 'Stok Opname',
        'adjustment_in': 'Koreksi Tambah',
        'adjustment_out': 'Koreksi Kurang',
      }[type] ??
      type;

  static bool isInbound(String type) =>
      type == purchase || type == adjustmentIn;

  static bool isOutbound(String type) =>
      type == sale || type == adjustmentOut;
}

class StockMovementModel {
  final String id;
  final String productId;
  final String productName;
  final String productEmoji;
  final String type;
  final int quantity;
  final int qtyBefore;
  final int qtyAfter;
  final String? referenceId;
  final String notes;
  final DateTime createdAt;

  StockMovementModel({
    String? id,
    required this.productId,
    required this.productName,
    this.productEmoji = '📦',
    required this.type,
    required this.quantity,
    required this.qtyBefore,
    required this.qtyAfter,
    this.referenceId,
    this.notes = '',
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  factory StockMovementModel.fromMap(Map<String, dynamic> m) =>
      StockMovementModel(
        id: m['id'] as String,
        productId: m['product_id'] as String,
        productName: m['product_name'] as String,
        productEmoji: m['product_emoji'] as String? ?? '📦',
        type: m['type'] as String,
        quantity: m['quantity'] as int,
        qtyBefore: m['qty_before'] as int,
        qtyAfter: m['qty_after'] as int,
        referenceId: m['reference_id'] as String?,
        notes: m['notes'] as String? ?? '',
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'product_id': productId,
        'product_name': productName,
        'product_emoji': productEmoji,
        'type': type,
        'quantity': quantity,
        'qty_before': qtyBefore,
        'qty_after': qtyAfter,
        'reference_id': referenceId,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };
}

class StockOpnameModel {
  final String id;
  String notes;
  String status;
  int itemsCount;
  final DateTime createdAt;
  DateTime? completedAt;
  List<StockOpnameItemModel> items;

  StockOpnameModel({
    String? id,
    this.notes = '',
    this.status = 'draft',
    this.itemsCount = 0,
    DateTime? createdAt,
    this.completedAt,
    List<StockOpnameItemModel>? items,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        items = items ?? [];

  factory StockOpnameModel.fromMap(Map<String, dynamic> m) => StockOpnameModel(
        id: m['id'] as String,
        notes: m['notes'] as String? ?? '',
        status: m['status'] as String? ?? 'draft',
        itemsCount: m['items_count'] as int? ?? 0,
        createdAt: DateTime.parse(m['created_at'] as String),
        completedAt: m['completed_at'] != null
            ? DateTime.parse(m['completed_at'] as String)
            : null,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'notes': notes,
        'status': status,
        'items_count': itemsCount,
        'created_at': createdAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
      };
}

class StockOpnameItemModel {
  final String id;
  final String opnameId;
  final String productId;
  String productName;
  String productEmoji;
  final int systemQty;
  int actualQty;
  String notes;

  int get difference => actualQty - systemQty;

  StockOpnameItemModel({
    String? id,
    required this.opnameId,
    required this.productId,
    required this.productName,
    this.productEmoji = '📦',
    required this.systemQty,
    int? actualQty,
    this.notes = '',
  })  : id = id ?? _uuid.v4(),
        actualQty = actualQty ?? systemQty;

  factory StockOpnameItemModel.fromMap(Map<String, dynamic> m) =>
      StockOpnameItemModel(
        id: m['id'] as String,
        opnameId: m['opname_id'] as String,
        productId: m['product_id'] as String,
        productName: m['product_name'] as String,
        productEmoji: m['product_emoji'] as String? ?? '📦',
        systemQty: m['system_qty'] as int,
        actualQty: m['actual_qty'] as int,
        notes: m['notes'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'opname_id': opnameId,
        'product_id': productId,
        'product_name': productName,
        'product_emoji': productEmoji,
        'system_qty': systemQty,
        'actual_qty': actualQty,
        'notes': notes,
      };
}
