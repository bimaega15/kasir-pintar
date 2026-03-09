import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class PriceLevelModel {
  final String id;
  String name;
  String description;
  int sortOrder;
  bool isDefault;

  PriceLevelModel({
    String? id,
    required this.name,
    this.description = '',
    this.sortOrder = 0,
    this.isDefault = false,
  }) : id = id ?? _uuid.v4();

  static List<PriceLevelModel> get defaultLevels => [
        PriceLevelModel(id: 'retail', name: 'Ecer', sortOrder: 0, isDefault: true),
        PriceLevelModel(id: 'wholesale', name: 'Grosir', sortOrder: 1),
        PriceLevelModel(id: 'special', name: 'Khusus', sortOrder: 2),
      ];
}

/// Harga produk untuk satu level tertentu
class ProductPriceLevelEntry {
  final String priceLevelId;
  String priceLevelName;
  double price;

  ProductPriceLevelEntry({
    required this.priceLevelId,
    required this.priceLevelName,
    required this.price,
  });
}
