import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  int quantity;
  String note;

  CartItemModel({
    required this.product,
    this.quantity = 1,
    this.note = '',
  });

  double get subtotal => product.price * quantity;

  Map<String, dynamic> toJson() => {
        'product': product.toJson(),
        'quantity': quantity,
        'note': note,
      };

  factory CartItemModel.fromJson(Map<String, dynamic> json) => CartItemModel(
        product: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
        quantity: json['quantity'] as int,
        note: json['note'] as String? ?? '',
      );
}
