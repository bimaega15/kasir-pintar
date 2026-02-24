import 'package:uuid/uuid.dart';
import 'cart_item_model.dart';

const _uuid = Uuid();

class TransactionModel {
  final String id;
  final String invoiceNumber;
  final List<CartItemModel> items;
  final double subtotal;
  final double discount;
  final double total;
  final double paymentAmount;
  final double change;
  final String paymentMethod;
  final DateTime createdAt;
  final String cashierName;

  TransactionModel({
    String? id,
    required this.invoiceNumber,
    required this.items,
    required this.subtotal,
    this.discount = 0,
    required this.total,
    required this.paymentAmount,
    required this.change,
    this.paymentMethod = 'Tunai',
    DateTime? createdAt,
    this.cashierName = 'Kasir',
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id'] as String,
        invoiceNumber: json['invoiceNumber'] as String,
        items: (json['items'] as List)
            .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        subtotal: (json['subtotal'] as num).toDouble(),
        discount: (json['discount'] as num?)?.toDouble() ?? 0,
        total: (json['total'] as num).toDouble(),
        paymentAmount: (json['paymentAmount'] as num).toDouble(),
        change: (json['change'] as num).toDouble(),
        paymentMethod: json['paymentMethod'] as String? ?? 'Tunai',
        createdAt: DateTime.parse(json['createdAt'] as String),
        cashierName: json['cashierName'] as String? ?? 'Kasir',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'invoiceNumber': invoiceNumber,
        'items': items.map((e) => e.toJson()).toList(),
        'subtotal': subtotal,
        'discount': discount,
        'total': total,
        'paymentAmount': paymentAmount,
        'change': change,
        'paymentMethod': paymentMethod,
        'createdAt': createdAt.toIso8601String(),
        'cashierName': cashierName,
      };
}
