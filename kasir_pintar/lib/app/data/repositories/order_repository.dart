import 'package:get/get.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';
import '../models/payment_entry_model.dart';
import '../models/product_model.dart';
import '../models/split_transaction_model.dart';
import '../models/transaction_model.dart';
import '../providers/storage_provider.dart';
import 'transaction_repository.dart';

class OrderRepository {
  final DatabaseProvider _db = Get.find<DatabaseProvider>();

  Future<List<OrderModel>> getAll() => _db.getOrders();

  Future<List<OrderModel>> getActive() => _db.getActiveOrders();

  Future<OrderModel?> getById(String id) => _db.getOrderById(id);

  Future<void> save(OrderModel order) => _db.insertOrder(order);

  Future<void> updateKitchenStatus(String id, KitchenStatus status) =>
      _db.updateOrderKitchenStatus(id, status);

  Future<void> delete(String id) => _db.deleteOrder(id);

  /// Converts a paid OrderModel into a TransactionModel and saves to history.
  Future<TransactionModel> convertToTransaction(
    OrderModel order,
    List<PaymentEntry> payments, {
    List<SplitTransactionModel>? splitTransactions,
  }) async {
    final txRepo = Get.find<TransactionRepository>();

    // Primary payment method = first entry, or 'Multi-Payment'
    final paymentMethod = payments.length == 1
        ? payments.first.method
        : 'Multi-Payment';
    final totalPaid = payments.fold(0.0, (s, p) => s + p.amount);
    final change = (totalPaid - order.total).clamp(0.0, double.infinity);

    // Convert OrderItemModel → CartItemModel (product snapshot)
    final cartItems = order.items
        .map(
          (oi) => CartItemModel(
            product: ProductModel(
              id: oi.productId,
              name: oi.productName,
              categoryId: 'other',
              price: oi.productPrice,
              emoji: oi.productEmoji,
            ),
            quantity: oi.quantity,
            note: oi.note,
          ),
        )
        .toList();

    final transaction = TransactionModel(
      invoiceNumber: order.invoiceNumber,
      items: cartItems,
      subtotal: order.subtotal,
      discount: order.discount,
      total: order.total,
      paymentAmount: totalPaid,
      change: change,
      paymentMethod: paymentMethod,
      cashierName: order.cashierName,
      customerName: order.customerName,
      orderType: OrderModel.orderTypeToString(order.orderType),
      tableNumber: order.tableNumber,
      taxAmount: order.taxAmount,
      serviceChargeAmount: order.serviceChargeAmount,
      paymentEntries: payments,
      isSplitPayment: splitTransactions != null && splitTransactions.isNotEmpty,
      splitTotalCount: splitTransactions?.length,
    );

    await txRepo.save(transaction, payments);
    await _db.insertOrderPayments(order.id, payments);
    return transaction;
  }
}
