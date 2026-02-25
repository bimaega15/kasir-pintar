import 'package:uuid/uuid.dart';
import 'order_item_model.dart';
import 'payment_entry_model.dart';

enum OrderType { dineIn, takeAway }

enum KitchenStatus { pending, inProgress, ready, paid }

class OrderModel {
  final String id;
  String invoiceNumber;
  OrderType orderType;
  String? tableId;
  int? tableNumber;
  int guestCount;
  String customerName;
  List<OrderItemModel> items;
  KitchenStatus kitchenStatus;
  double subtotal;
  double discount;
  double taxPercent;
  double taxAmount;
  double serviceChargePercent;
  double serviceChargeAmount;
  double total;
  List<PaymentEntry> payments;
  String cashierName;
  DateTime createdAt;
  DateTime? kitchenSentAt;
  DateTime? readyAt;

  OrderModel({
    String? id,
    required this.invoiceNumber,
    this.orderType = OrderType.dineIn,
    this.tableId,
    this.tableNumber,
    this.guestCount = 1,
    this.customerName = '',
    List<OrderItemModel>? items,
    this.kitchenStatus = KitchenStatus.pending,
    required this.subtotal,
    this.discount = 0,
    this.taxPercent = 0,
    this.taxAmount = 0,
    this.serviceChargePercent = 0,
    this.serviceChargeAmount = 0,
    required this.total,
    List<PaymentEntry>? payments,
    this.cashierName = 'Kasir',
    DateTime? createdAt,
    this.kitchenSentAt,
    this.readyAt,
  }) : id = id ?? const Uuid().v4(),
       items = items ?? [],
       payments = payments ?? [],
       createdAt = createdAt ?? DateTime.now();

  double get totalPaid => payments.fold(0.0, (s, p) => s + p.amount);
  double get change => totalPaid - total;
  int get totalItems => items.fold(0, (s, i) => s + i.quantity);

  String get orderTypeLabel =>
      orderType == OrderType.dineIn ? 'Dine In' : 'Take Away';

  String get kitchenStatusLabel {
    switch (kitchenStatus) {
      case KitchenStatus.pending:
        return 'Menunggu';
      case KitchenStatus.inProgress:
        return 'Diproses';
      case KitchenStatus.ready:
        return 'Siap';
      case KitchenStatus.paid:
        return 'Lunas';
    }
  }

  static OrderType orderTypeFromString(String s) =>
      s == 'take_away' ? OrderType.takeAway : OrderType.dineIn;

  static String orderTypeToString(OrderType t) =>
      t == OrderType.takeAway ? 'take_away' : 'dine_in';

  static KitchenStatus kitchenStatusFromString(String s) {
    switch (s) {
      case 'in_progress':
        return KitchenStatus.inProgress;
      case 'ready':
        return KitchenStatus.ready;
      case 'paid':
        return KitchenStatus.paid;
      default:
        return KitchenStatus.pending;
    }
  }

  static String kitchenStatusToString(KitchenStatus s) {
    switch (s) {
      case KitchenStatus.inProgress:
        return 'in_progress';
      case KitchenStatus.ready:
        return 'ready';
      case KitchenStatus.paid:
        return 'paid';
      case KitchenStatus.pending:
        return 'pending';
    }
  }
}
