import 'package:uuid/uuid.dart';
import 'price_level_model.dart';

const _uuid = Uuid();

/// Satu item (produk) yang termasuk dalam sebuah paket
class PackageItem {
  final String productId;
  String productName;
  String productEmoji;
  int quantity;

  PackageItem({
    required this.productId,
    required this.productName,
    this.productEmoji = '📦',
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'productEmoji': productEmoji,
        'quantity': quantity,
      };

  factory PackageItem.fromJson(Map<String, dynamic> json) => PackageItem(
        productId: json['productId'] as String,
        productName: json['productName'] as String,
        productEmoji: json['productEmoji'] as String? ?? '📦',
        quantity: json['quantity'] as int? ?? 1,
      );
}

/// Satu bahan baku yang digunakan dalam resep produk (recipe item)
class ProductBahanBakuEntry {
  final String bahanBakuId;
  String bahanBakuName;
  String bahanBakuEmoji;
  String bahanBakuUnit;
  double quantity; // jumlah bahan baku per 1 porsi produk
  double availableStock = 0; // di-set oleh storage_provider saat load

  ProductBahanBakuEntry({
    required this.bahanBakuId,
    required this.bahanBakuName,
    this.bahanBakuEmoji = '📦',
    this.bahanBakuUnit = '',
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
        'bahanBakuId': bahanBakuId,
        'bahanBakuName': bahanBakuName,
        'bahanBakuEmoji': bahanBakuEmoji,
        'bahanBakuUnit': bahanBakuUnit,
        'quantity': quantity,
      };

  factory ProductBahanBakuEntry.fromJson(Map<String, dynamic> json) =>
      ProductBahanBakuEntry(
        bahanBakuId: json['bahanBakuId'] as String,
        bahanBakuName: json['bahanBakuName'] as String,
        bahanBakuEmoji: json['bahanBakuEmoji'] as String? ?? '📦',
        bahanBakuUnit: json['bahanBakuUnit'] as String? ?? '',
        quantity: (json['quantity'] as num).toDouble(),
      );
}

class ProductModel {
  final String id;
  String name;
  String categoryId;
  double price; // harga dasar (fallback jika level tidak punya harga)
  int stock;
  String description;
  String emoji;
  String? imagePath; // path foto produk (null = pakai emoji)
  final DateTime createdAt;

  /// true jika produk ini adalah sebuah paket (bundle)
  bool isPackage;

  /// Item-item yang termasuk dalam paket — diisi oleh storage_provider saat load
  List<PackageItem> packageItems = [];

  /// Resep bahan baku — diisi oleh storage_provider saat load
  List<ProductBahanBakuEntry> bahanBakuItems = [];

  /// Harga per level — diisi oleh storage_provider saat load
  List<ProductPriceLevelEntry> priceLevels = [];

  /// Hitung stok produk berdasarkan ketersediaan bahan baku.
  /// Jika produk punya resep bahan baku, stok = floor(MIN(bb.stock / recipe.qty)).
  /// Jika tidak punya resep, gunakan field stock langsung (fallback).
  int get computedStock {
    if (bahanBakuItems.isEmpty) return stock;
    int minPortions = 999999;
    for (final item in bahanBakuItems) {
      if (item.quantity <= 0) continue;
      // bahanBakuStock di-set oleh storage_provider saat load
      final portions = (item.availableStock / item.quantity).floor();
      if (portions < minPortions) minPortions = portions;
    }
    return minPortions == 999999 ? 0 : minPortions;
  }

  /// Kembalikan harga untuk level tertentu; fallback ke harga dasar
  double getPriceForLevel(String? levelId) {
    if (levelId == null || levelId.isEmpty) return price;
    final entry = priceLevels.cast<ProductPriceLevelEntry?>()
        .firstWhere((e) => e?.priceLevelId == levelId, orElse: () => null);
    return entry?.price ?? price;
  }

  ProductModel({
    String? id,
    required this.name,
    required this.categoryId,
    required this.price,
    this.stock = 0,
    this.description = '',
    this.emoji = '📦',
    this.imagePath,
    DateTime? createdAt,
    this.isPackage = false,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        id: json['id'] as String,
        name: json['name'] as String,
        categoryId: json['categoryId'] as String,
        price: (json['price'] as num).toDouble(),
        stock: json['stock'] as int? ?? 0,
        description: json['description'] as String? ?? '',
        emoji: json['emoji'] as String? ?? '📦',
        imagePath: json['imagePath'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isPackage: json['isPackage'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'categoryId': categoryId,
        'price': price,
        'stock': stock,
        'description': description,
        'emoji': emoji,
        'imagePath': imagePath,
        'createdAt': createdAt.toIso8601String(),
        'isPackage': isPackage,
      };

  ProductModel copyWith({
    String? name,
    String? categoryId,
    double? price,
    int? stock,
    String? description,
    String? emoji,
    String? imagePath,
    bool clearImage = false,
    bool? isPackage,
  }) =>
      ProductModel(
        id: id,
        name: name ?? this.name,
        categoryId: categoryId ?? this.categoryId,
        price: price ?? this.price,
        stock: stock ?? this.stock,
        description: description ?? this.description,
        emoji: emoji ?? this.emoji,
        imagePath: clearImage ? null : (imagePath ?? this.imagePath),
        createdAt: createdAt,
        isPackage: isPackage ?? this.isPackage,
      );

  static List<ProductModel> get sampleProducts => [
        ProductModel(name: 'Nasi Goreng', categoryId: 'food', price: 15000, stock: 50, emoji: '🍳'),
        ProductModel(name: 'Mie Goreng', categoryId: 'food', price: 12000, stock: 30, emoji: '🍜'),
        ProductModel(name: 'Ayam Bakar', categoryId: 'food', price: 25000, stock: 20, emoji: '🍗'),
        ProductModel(name: 'Soto Ayam', categoryId: 'food', price: 18000, stock: 15, emoji: '🥣'),
        ProductModel(name: 'Es Teh Manis', categoryId: 'drink', price: 5000, stock: 100, emoji: '🧋'),
        ProductModel(name: 'Es Jeruk', categoryId: 'drink', price: 7000, stock: 80, emoji: '🍊'),
        ProductModel(name: 'Kopi Hitam', categoryId: 'drink', price: 8000, stock: 60, emoji: '☕'),
        ProductModel(name: 'Jus Alpukat', categoryId: 'drink', price: 15000, stock: 40, emoji: '🥑'),
        ProductModel(name: 'Keripik Singkong', categoryId: 'snack', price: 5000, stock: 200, emoji: '🥔'),
        ProductModel(name: 'Pisang Goreng', categoryId: 'snack', price: 3000, stock: 100, emoji: '🍌'),
        ProductModel(name: 'Tahu Goreng', categoryId: 'snack', price: 2000, stock: 150, emoji: '🟨'),
        ProductModel(name: 'Tissue', categoryId: 'other', price: 3000, stock: 50, emoji: '🧻'),
      ];
}
