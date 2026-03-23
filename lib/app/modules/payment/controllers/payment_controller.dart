import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/debt_model.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/payment_entry_model.dart';
import '../../../data/models/split_transaction_model.dart';
import '../../../data/providers/storage_provider.dart';
import '../../../data/repositories/debt_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/table_repository.dart';
import '../../../modules/debt/controllers/debt_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../services/printer_service.dart';
import '../../../utils/helpers/currency_helper.dart';

class PaymentController extends GetxController {
  final _orderRepo = Get.find<OrderRepository>();
  final _tableRepo = Get.find<TableRepository>();
  final _dbProvider = Get.find<DatabaseProvider>();

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

  final List<TextEditingController> amountControllers = [];

  // ── Split Bill (INDEPENDENT) ────────────────────────────────────────────────
  final isSplitMode = false.obs;
  final splitCount = 2.obs;
  final splitIndex = 0.obs;
  // NEW: Store completed split transactions (independent tracking)
  final completedSplits = <SplitTransactionModel>[].obs;
  // Fixed due amount per split (NOT changing between splits)
  late double currentSplitDueAmount;

  double get amountPerSplit {
    if (splitCount.value <= 0) return order.total;
    return (order.total / splitCount.value).ceilToDouble();
  }

  double get currentSplitAmount => currentSplitDueAmount;

  @override
  void onInit() {
    super.onInit();
    order = Get.arguments as OrderModel;
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

  void _clearEntries() {
    for (final c in amountControllers) {
      c.dispose();
    }
    amountControllers.clear();
    entries.clear();
  }

  void addEntry() {
    if (entries.length < 3) _addEntryInternal('Tunai', 0);
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

  /// Buka laci uang jika ada pembayaran Tunai dan fitur diaktifkan.
  void _tryOpenDrawer(List<PaymentEntry> paidEntries) {
    final hasCash = paidEntries.any((e) => e.method == 'Tunai');
    if (!hasCash) return;
    try {
      final printer = Get.find<PrinterService>();
      if (printer.cashDrawerEnabled.value && printer.cashDrawerAutoOpen.value) {
        printer.openCashDrawer(silent: true);
      }
    } catch (_) {}
  }

  double get totalPaid => entries.fold(0.0, (s, e) => s + e.amount);
  double get remaining =>
      (order.total - totalPaid).clamp(0.0, double.infinity);
  double get change => (totalPaid - order.total).clamp(0.0, double.infinity);
  bool get isPaid => totalPaid >= order.total;

  // Split mode aware checks
  bool get isSplitAmountPaid => totalPaid >= currentSplitAmount;
  double get splitRemaining =>
      (currentSplitAmount - totalPaid).clamp(0.0, double.infinity);
  double get splitChange => (totalPaid - currentSplitAmount).clamp(0.0, double.infinity);

  // ── Split Bill methods ─────────────────────────────────────────────────────

  void enterSplitMode(int count) {
    isSplitMode.value = true;
    splitCount.value = count;
    splitIndex.value = 0;
    completedSplits.clear();

    // FIXED: Calculate and lock due amount for ALL splits
    currentSplitDueAmount = amountPerSplit;

    _clearEntries();
    _addEntryInternal('Tunai', currentSplitDueAmount);
  }

  Future<void> processSplitPayment() async {
    if (!isSplitAmountPaid) {
      Get.snackbar(
        'Pembayaran Kurang',
        'Total dibayar belum mencukupi bagian ini. Tagihan: ${CurrencyHelper.formatRupiah(currentSplitAmount)}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return;
    }

    // INDEPENDENT: Calculate change for THIS split ONLY
    final totalPaidThisSplit = totalPaid;
    final changeThisSplit = totalPaidThisSplit - currentSplitDueAmount;

    // Determine primary payment method for this split
    final primaryMethod = entries.length == 1 ? entries.first.method : 'Multi-Payment';

    // Create split transaction record (INDEPENDENT)
    final splitTx = SplitTransactionModel(
      transactionId: order.id, // Will be updated to real transaction ID later
      splitNumber: splitIndex.value + 1,
      totalSplitAmount: currentSplitDueAmount,
      amountPaid: totalPaidThisSplit,
      changeAmount: changeThisSplit,
      paymentMethod: primaryMethod,
      notes: 'Split ${splitIndex.value + 1} of ${splitCount.value}',
    );

    // Store this split (INDEPENDENT, not accumulated)
    completedSplits.add(splitTx);

    final isLast = splitIndex.value == splitCount.value - 1;

    if (isLast) {
      await _finalizeOrder();
    } else {
      // Show confirmation and prepare for NEXT INDEPENDENT split
      Get.dialog(AlertDialog(
        title: Text('Bagian ${splitIndex.value + 1} Lunas'),
        content: Text(
          'Tagihan: ${CurrencyHelper.formatRupiah(currentSplitDueAmount)}\n'
          'Dibayar: ${CurrencyHelper.formatRupiah(totalPaidThisSplit)}\n'
          'Kembalian: ${CurrencyHelper.formatRupiah(changeThisSplit)}\n\n'
          'Serahkan struk ke pelanggan ${splitIndex.value + 1}.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Get.back();
              splitIndex.value++;
              _clearEntries();
              // IMPORTANT: Next split gets SAME fixed due amount
              _addEntryInternal('Tunai', currentSplitDueAmount);
            },
            child: const Text('Lanjut ke Bagian Berikutnya'),
          ),
        ],
      ));
    }
  }

  Future<void> _finalizeOrder() async {
    isProcessing.value = true;
    try {
      // INDEPENDENT: Aggregate payment methods from ALL completed splits
      final consolidatedPayments = <String, double>{};
      for (final split in completedSplits) {
        consolidatedPayments[split.paymentMethod] =
            (consolidatedPayments[split.paymentMethod] ?? 0) + split.amountPaid;
      }

      final consolidatedEntries = consolidatedPayments.entries
          .map((e) => PaymentEntry(method: e.key, amount: e.value))
          .toList();

      // Convert to transaction with split info
      final transaction = await _orderRepo.convertToTransaction(
        order,
        consolidatedEntries,
        splitTransactions: completedSplits,
      );

      // Save each split transaction to database
      for (final split in completedSplits) {
        await _dbProvider.insertSplitTransaction(
          split.copyWith(transactionId: transaction.id),
        );
      }

      await _orderRepo.delete(order.id);
      if (order.tableId != null) {
        await _tableRepo.setAvailable(order.tableId!);
      }
      _tryOpenDrawer(consolidatedEntries);
      Get.offAllNamed(AppRoutes.receipt, arguments: transaction);
    } catch (e) {
      Get.snackbar('Error', 'Gagal memproses pembayaran: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isProcessing.value = false;
    }
  }

  // ── Hutang / DP ───────────────────────────────────────────────────────────

  Future<void> processDebt({
    required double amountPaid,
    required String customerName,
  }) async {
    isProcessing.value = true;
    try {
      final total = order.total;
      // dp = actual amount credited toward the bill (capped at total)
      final dp = amountPaid.clamp(0.0, total);
      final remaining = total - dp;

      // Payment entry: records the actual cash handed over (for kembalian calc)
      final paymentEntries = amountPaid > 0
          ? [PaymentEntry(method: remaining > 0 ? 'DP/Hutang' : 'Tunai', amount: amountPaid)]
          : [PaymentEntry(method: 'Hutang', amount: 0)];

      final transaction = await _orderRepo.convertToTransaction(
        order,
        paymentEntries,
      );
      await _orderRepo.delete(order.id);
      if (order.tableId != null) {
        await _tableRepo.setAvailable(order.tableId!);
      }

      // Only create debt record if there is still remaining balance
      if (remaining > 0) {
        final debt = DebtModel(
          invoiceNumber: transaction.invoiceNumber,
          customerName: customerName.isNotEmpty
              ? customerName
              : order.customerName,
          totalAmount: total,
          dpAmount: dp,
          remainingAmount: remaining,
          status: dp > 0 ? 'partial' : 'unpaid',
        );
        await Get.find<DebtRepository>().save(debt);
        Get.find<DebtController>().loadDebts();
      }

      // Buka laci jika ada DP tunai
      if (amountPaid > 0) _tryOpenDrawer(paymentEntries);
      Get.offAllNamed(AppRoutes.receipt, arguments: transaction);
    } catch (e) {
      Get.snackbar('Error', 'Gagal memproses hutang: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isProcessing.value = false;
    }
  }

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
      final transaction =
          await _orderRepo.convertToTransaction(order, List.from(entries));
      await _orderRepo.delete(order.id);
      if (order.tableId != null) {
        await _tableRepo.setAvailable(order.tableId!);
      }
      _tryOpenDrawer(List.from(entries));
      Get.offAllNamed(AppRoutes.receipt, arguments: transaction);
    } catch (e) {
      Get.snackbar('Error', 'Gagal memproses pembayaran: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isProcessing.value = false;
    }
  }
}
