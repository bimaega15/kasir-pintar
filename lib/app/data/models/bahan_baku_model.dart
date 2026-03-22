import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class BahanBakuModel {
  final String id;
  String name;
  String unit; // satuan: kg, liter, pcs, gram, dll
  double stock;
  double minStock; // stok minimum untuk alert
  double price; // harga per unit
  String emoji;
  String notes;
  final DateTime createdAt;

  BahanBakuModel({
    String? id,
    required this.name,
    required this.unit,
    this.stock = 0,
    this.minStock = 0,
    this.price = 0,
    this.emoji = '\u{1F4E6}',
    this.notes = '',
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  bool get isLowStock => stock <= minStock && minStock > 0;

  factory BahanBakuModel.fromMap(Map<String, dynamic> m) => BahanBakuModel(
        id: m['id'] as String,
        name: m['name'] as String,
        unit: m['unit'] as String,
        stock: (m['stock'] as num).toDouble(),
        minStock: (m['min_stock'] as num?)?.toDouble() ?? 0,
        price: (m['price'] as num?)?.toDouble() ?? 0,
        emoji: m['emoji'] as String? ?? '\u{1F4E6}',
        notes: m['notes'] as String? ?? '',
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'unit': unit,
        'stock': stock,
        'min_stock': minStock,
        'price': price,
        'emoji': emoji,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  BahanBakuModel copyWith({
    String? name,
    String? unit,
    double? stock,
    double? minStock,
    double? price,
    String? emoji,
    String? notes,
  }) =>
      BahanBakuModel(
        id: id,
        name: name ?? this.name,
        unit: unit ?? this.unit,
        stock: stock ?? this.stock,
        minStock: minStock ?? this.minStock,
        price: price ?? this.price,
        emoji: emoji ?? this.emoji,
        notes: notes ?? this.notes,
        createdAt: createdAt,
      );

  static List<BahanBakuModel> get sampleBahanBaku => [
        BahanBakuModel(
            id: 'bb_mie', name: 'Mie Mentah', unit: 'kg', stock: 50, minStock: 10, price: 15000, emoji: '\u{1F35C}'),
        BahanBakuModel(
            id: 'bb_telur', name: 'Telur', unit: 'butir', stock: 100, minStock: 20, price: 2500, emoji: '\u{1F95A}'),
        BahanBakuModel(
            id: 'bb_sayur', name: 'Sayur Sawi', unit: 'kg', stock: 10, minStock: 3, price: 8000, emoji: '\u{1F96C}'),
        BahanBakuModel(
            id: 'bb_ayam', name: 'Daging Ayam', unit: 'kg', stock: 15, minStock: 5, price: 35000, emoji: '\u{1F357}'),
        BahanBakuModel(
            id: 'bb_bumbu', name: 'Bumbu Racik', unit: 'kg', stock: 5, minStock: 2, price: 25000, emoji: '\u{1F9C2}'),
        BahanBakuModel(
            id: 'bb_kecap', name: 'Kecap Manis', unit: 'liter', stock: 8, minStock: 2, price: 18000, emoji: '\u{1F962}'),
        BahanBakuModel(
            id: 'bb_minyak', name: 'Minyak Goreng', unit: 'liter', stock: 20, minStock: 5, price: 16000, emoji: '\u{1FAD8}'),
        BahanBakuModel(
            id: 'bb_bawang', name: 'Bawang Merah', unit: 'kg', stock: 8, minStock: 2, price: 30000, emoji: '\u{1F9C5}'),
      ];
}

class BahanBakuMovementType {
  static const purchase = 'purchase';
  static const usage = 'usage';
  static const adjustmentIn = 'adjustment_in';
  static const adjustmentOut = 'adjustment_out';
  static const opname = 'opname';

  static String label(String type) =>
      const {
        'purchase': 'Pembelian',
        'usage': 'Pemakaian',
        'adjustment_in': 'Koreksi Tambah',
        'adjustment_out': 'Koreksi Kurang',
        'opname': 'Stok Opname',
      }[type] ??
      type;

  static bool isInbound(String type) =>
      type == purchase || type == adjustmentIn;

  static bool isOutbound(String type) =>
      type == usage || type == adjustmentOut;
}

class BahanBakuMovementModel {
  final String id;
  final String bahanBakuId;
  final String bahanBakuName;
  final String bahanBakuEmoji;
  final String type;
  final double quantity;
  final double qtyBefore;
  final double qtyAfter;
  final double? totalCost; // total biaya (untuk pembelian)
  final String notes;
  final DateTime createdAt;

  BahanBakuMovementModel({
    String? id,
    required this.bahanBakuId,
    required this.bahanBakuName,
    this.bahanBakuEmoji = '\u{1F4E6}',
    required this.type,
    required this.quantity,
    required this.qtyBefore,
    required this.qtyAfter,
    this.totalCost,
    this.notes = '',
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  factory BahanBakuMovementModel.fromMap(Map<String, dynamic> m) =>
      BahanBakuMovementModel(
        id: m['id'] as String,
        bahanBakuId: m['bahan_baku_id'] as String,
        bahanBakuName: m['bahan_baku_name'] as String,
        bahanBakuEmoji: m['bahan_baku_emoji'] as String? ?? '\u{1F4E6}',
        type: m['type'] as String,
        quantity: (m['quantity'] as num).toDouble(),
        qtyBefore: (m['qty_before'] as num).toDouble(),
        qtyAfter: (m['qty_after'] as num).toDouble(),
        totalCost: (m['total_cost'] as num?)?.toDouble(),
        notes: m['notes'] as String? ?? '',
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'bahan_baku_id': bahanBakuId,
        'bahan_baku_name': bahanBakuName,
        'bahan_baku_emoji': bahanBakuEmoji,
        'type': type,
        'quantity': quantity,
        'qty_before': qtyBefore,
        'qty_after': qtyAfter,
        'total_cost': totalCost,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };
}
