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
  // v2 fields
  final String orderType;           // 'dine_in' | 'take_away'
  final int? tableNumber;
  final double taxAmount;
  final double serviceChargeAmount;

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
    this.orderType = 'dine_in',
    this.tableNumber,
    this.taxAmount = 0,
    this.serviceChargeAmount = 0,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  String get orderTypeLabel =>
      orderType == 'take_away' ? 'Take Away' : 'Dine In';
}
