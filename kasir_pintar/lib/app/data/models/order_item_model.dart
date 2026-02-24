class OrderItemModel {
  final String productId;
  final String productName;
  final double productPrice;
  final String productEmoji;
  int quantity;
  String note;

  OrderItemModel({
    required this.productId,
    required this.productName,
    required this.productPrice,
    this.productEmoji = '📦',
    this.quantity = 1,
    this.note = '',
  });

  double get subtotal => productPrice * quantity;
}
