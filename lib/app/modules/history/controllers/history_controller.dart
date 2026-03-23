import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/void_log_model.dart';
import '../../../data/providers/storage_provider.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../services/user_session.dart';
import '../../shift/controllers/shift_controller.dart';

class HistoryController extends GetxController {
  final _transactionRepo = Get.find<TransactionRepository>();
  final _db = Get.find<DatabaseProvider>();

  final transactions = <TransactionModel>[].obs;
  final searchQuery = ''.obs;
  final searchController = TextEditingController();
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadTransactions();
    searchController.addListener(() {
      searchQuery.value = searchController.text;
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadTransactions() async {
    isLoading.value = true;
    try {
      final session = Get.find<UserSession>();
      final List<TransactionModel> list;
      if (session.isKasir) {
        final shiftCtrl = Get.isRegistered<ShiftController>()
            ? Get.find<ShiftController>()
            : null;
        list = await _transactionRepo.getFiltered(
          shiftStart: shiftCtrl?.activeShift.value?.openedAt,
        );
      } else {
        list = await _transactionRepo.getAll();
      }
      transactions.assignAll(list);
    } finally {
      isLoading.value = false;
    }
  }

  List<TransactionModel> get filteredTransactions {
    if (searchQuery.value.isEmpty) return transactions;
    final q = searchQuery.value.toLowerCase();
    return transactions
        .where((t) =>
            t.invoiceNumber.toLowerCase().contains(q) ||
            t.paymentMethod.toLowerCase().contains(q))
        .toList();
  }

  double get totalRevenue =>
      transactions.fold(0.0, (sum, t) => sum + t.total);

  Future<void> voidTransaction(TransactionModel tx, String reason) async {
    try {
      final log = VoidLogModel(
        orderId: tx.id,
        invoiceNumber: tx.invoiceNumber,
        orderTotal: tx.total,
        reason: reason,
        voidedBy: 'Kasir',
        voidedAt: DateTime.now(),
      );
      await _db.insertVoidLog(log);
      await _transactionRepo.delete(tx.id);
      await loadTransactions();
      Get.snackbar(
        'Transaksi Dibatalkan',
        '${tx.invoiceNumber} berhasil dibatalkan',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFFEBEE),
        colorText: const Color(0xFFC62828),
      );
    } catch (e) {
      Get.snackbar('Error', 'Gagal membatalkan transaksi: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}
