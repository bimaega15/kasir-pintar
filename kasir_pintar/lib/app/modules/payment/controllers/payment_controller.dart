import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/payment_entry_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/table_repository.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/helpers/currency_helper.dart';

class PaymentController extends GetxController {
  final _orderRepo = Get.find<OrderRepository>();
  final _tableRepo = Get.find<TableRepository>();

  late OrderModel order;

  final entries = <PaymentEntry>[].obs;
  final isProcessing = false.obs;

  final paymentMethods = [
    'Tunai',
    'Transfer',
    'QRIS',
    'Kartu Debit',
    'E-Wallet',
  ];

  // Text controllers for each entry amount field (managed separately)
  final List<TextEditingController> amountControllers = [];

  @override
  void onInit() {
    super.onInit();
    order = Get.arguments as OrderModel;
    // Start with one cash entry equal to the full amount
    _addEntryInternal('Tunai', order.total);
  }

  @override
  void onClose() {
    for (final c in amountControllers) {
      c.dispose();
    }
    super.onClose();
  }

  void _addEntryInternal(String method, double amount) {
    entries.add(PaymentEntry(method: method, amount: amount));
    final ctrl = TextEditingController(
        text: amount > 0 ? amount.toStringAsFixed(0) : '');
    amountControllers.add(ctrl);
  }

  void addEntry() {
    _addEntryInternal('Tunai', 0);
  }

  void removeEntry(int index) {
    if (entries.length > 1) {
      amountControllers[index].dispose();
      amountControllers.removeAt(index);
      entries.removeAt(index);
    }
  }

  void updateEntryMethod(int index, String method) {
    entries[index].method = method;
    entries.refresh();
  }

  void updateEntryAmount(int index, String value) {
    entries[index].amount = CurrencyHelper.parseRupiah(value);
    entries.refresh();
  }

  double get totalPaid => entries.fold(0.0, (s, e) => s + e.amount);
  double get remaining =>
      (order.total - totalPaid).clamp(0.0, double.infinity);
  double get change => (totalPaid - order.total).clamp(0.0, double.infinity);
  bool get isPaid => totalPaid >= order.total;

  Future<void> processPayment() async {
    if (!isPaid) {
      Get.snackbar(
        'Pembayaran Kurang',
        'Total dibayar belum mencukupi tagihan',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return;
    }

    isProcessing.value = true;
    try {
      final transaction = await _orderRepo.convertToTransaction(
          order, List.from(entries));
      await _orderRepo.delete(order.id);

      // Free the table
      if (order.tableId != null) {
        await _tableRepo.setAvailable(order.tableId!);
      }

      Get.offAllNamed(AppRoutes.receipt, arguments: transaction);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memproses pembayaran: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isProcessing.value = false;
    }
  }
}
