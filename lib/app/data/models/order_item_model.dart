import 'product_model.dart';

class OrderItemModel {
  final String productId;
  final String productName;
  final double productPrice;
  final String productEmoji;
  int quantity;
  String note;
  final bool isPackage;
  final List<PackageItem> packageItems;

  OrderItemModel({
    required this.productId,
    required this.productName,
    required this.productPrice,
    this.productEmoji = '📦',
    this.quantity = 1,
    this.note = '',
    this.isPackage = false,
    List<PackageItem>? packageItems,
  }) : packageItems = packageItems ?? [];

  double get subtotal => productPrice * quantity;

  OrderItemModel copyWith({double? productPrice}) => OrderItemModel(
        productId: productId,
        productName: productName,
        productPrice: productPrice ?? this.productPrice,
        productEmoji: productEmoji,
        quantity: quantity,
        note: note,
        isPackage: isPackage,
        packageItems: packageItems,
      );
}
