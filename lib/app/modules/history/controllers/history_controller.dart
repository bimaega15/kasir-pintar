import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/cart_item_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/void_log_model.dart';
import '../../../data/providers/storage_provider.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../routes/app_routes.dart';
import '../../../services/user_session.dart';
import '../../shift/controllers/shift_controller.dart';

class HistoryController extends GetxController {
  final _transactionRepo = Get.find<TransactionRepository>();
  final _db = Get.find<DatabaseProvider>();

  final transactions = <TransactionModel>[].obs;
  final searchQuery = ''.obs;
  final searchController = TextEditingController();
  final isLoading = false.obs;

  // ── Merge Bill ────────────────────────────────────────────────────────────
  final isMergeMode = false.obs;
  final selectedForMerge = <String>{}.obs;

  void toggleMergeMode() {
    isMergeMode.value = !isMergeMode.value;
    if (!isMergeMode.value) selectedForMerge.clear();
  }

  void toggleMergeSelection(String txId) {
    if (selectedForMerge.contains(txId)) {
      selectedForMerge.remove(txId);
    } else {
      selectedForMerge.add(txId);
    }
  }

  double get mergeTotal => transactions
      .where((t) => selectedForMerge.contains(t.id))
      .fold(0.0, (sum, t) => sum + t.total);

  Future<void> mergeSelectedBills() async {
    if (selectedForMerge.length < 2) {
      Get.snackbar('Minimal 2 Transaksi',
          'Pilih minimal 2 transaksi untuk digabungkan',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    isLoading.value = true;
    try {
      final txs = transactions
          .where((t) => selectedForMerge.contains(t.id))
          .toList();

      // Gabungkan item — produk sama dijumlah qty-nya
      final merged = <String, CartItemModel>{};
      for (final tx in txs) {
        for (final item in tx.items) {
          final pid = item.product.id;
          if (merged.containsKey(pid)) {
            merged[pid]!.quantity += item.quantity;
          } else {
            merged[pid] = CartItemModel(
              product: item.product,
              quantity: item.quantity,
              note: item.note,
            );
          }
        }
      }

      final subtotal = txs.fold(0.0, (s, t) => s + t.subtotal);
      final discount = txs.fold(0.0, (s, t) => s + t.discount);
      final tax = txs.fold(0.0, (s, t) => s + t.taxAmount);
      final svc = txs.fold(0.0, (s, t) => s + t.serviceChargeAmount);
      final total = txs.fold(0.0, (s, t) => s + t.total);
      final customers = txs
          .map((t) => t.customerName)
          .where((n) => n.isNotEmpty)
          .toSet()
          .join(', ');
      final invoiceRefs = txs.map((t) => t.invoiceNumber).join(', ');

      final newInvoice = await _transactionRepo.generateInvoiceNumber();
      final mergedTx = TransactionModel(
        invoiceNumber: newInvoice,
        items: merged.values.toList(),
        subtotal: subtotal,
        discount: discount,
        total: total,
        paymentAmount: total,
        change: 0,
        paymentMethod: txs.first.paymentMethod,
        cashierName: txs.first.cashierName,
        customerName: customers,
        orderType: txs.first.orderType,
        tableNumber: txs.first.tableNumber,
        taxAmount: tax,
        serviceChargeAmount: svc,
      );

      await _transactionRepo.save(mergedTx);

      // Void semua transaksi asli
      for (final tx in txs) {
        final log = VoidLogModel(
          orderId: tx.id,
          invoiceNumber: tx.invoiceNumber,
          orderTotal: tx.total,
          reason: 'Digabungkan ke $newInvoice',
          voidedBy: 'Kasir',
          voidedAt: DateTime.now(),
        );
        await _db.insertVoidLog(log);
        await _transactionRepo.delete(tx.id);
      }

      toggleMergeMode();
      await loadTransactions();

      Get.snackbar(
        'Bill Digabungkan',
        '$newInvoice berhasil dibuat dari $invoiceRefs',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE8F5E9),
        colorText: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 4),
      );

      Get.toNamed(AppRoutes.transactionDetail, arguments: mergedTx);
    } catch (e) {
      Get.snackbar('Error', 'Gagal menggabungkan bill: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

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
