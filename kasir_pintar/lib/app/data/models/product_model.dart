import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class ProductModel {
  final String id;
  String name;
  String categoryId;
  double price;
  int stock;
  String description;
  String emoji;
  final DateTime createdAt;

  ProductModel({
    String? id,
    required this.name,
    required this.categoryId,
    required this.price,
    this.stock = 0,
    this.description = '',
    this.emoji = '📦',
    DateTime? createdAt,
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
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'categoryId': categoryId,
        'price': price,
        'stock': stock,
        'description': description,
        'emoji': emoji,
        'createdAt': createdAt.toIso8601String(),
      };

  ProductModel copyWith({
    String? name,
    String? categoryId,
    double? price,
    int? stock,
    String? description,
    String? emoji,
  }) =>
      ProductModel(
        id: id,
        name: name ?? this.name,
        categoryId: categoryId ?? this.categoryId,
        price: price ?? this.price,
        stock: stock ?? this.stock,
        description: description ?? this.description,
        emoji: emoji ?? this.emoji,
        createdAt: createdAt,
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
