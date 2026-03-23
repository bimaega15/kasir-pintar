import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/debt_model.dart';
import '../../../data/repositories/debt_repository.dart';
import '../../../utils/helpers/currency_helper.dart';

class DebtReportStats {
  final int totalCount;
  final double totalAmount;
  final double totalRemaining;
  final int unpaidCount;
  final int partialCount;
  final int paidCount;
  final double unpaidAmount;
  final double partialAmount;
  final double paidAmount;
  // Aging
  final double age07;
  final double age730;
  final double ageOver30;
  final int age07Count;
  final int age730Count;
  final int ageOver30Count;
  // Top debtors
  final List<Map<String, dynamic>> topDebtors;

  const DebtReportStats({
    this.totalCount = 0,
    this.totalAmount = 0,
    this.totalRemaining = 0,
    this.unpaidCount = 0,
    this.partialCount = 0,
    this.paidCount = 0,
    this.unpaidAmount = 0,
    this.partialAmount = 0,
    this.paidAmount = 0,
    this.age07 = 0,
    this.age730 = 0,
    this.ageOver30 = 0,
    this.age07Count = 0,
    this.age730Count = 0,
    this.ageOver30Count = 0,
    this.topDebtors = const [],
  });
}

class DebtController extends GetxController {
  final _repo = Get.find<DebtRepository>();

  final debts = <DebtModel>[].obs;
  final totalOutstanding = 0.0.obs;
  final unpaidCount = 0.obs;
  final isLoading = false.obs;
  final showPaidDebts = false.obs;
  final reportStats = const DebtReportStats().obs;
  final isLoadingReport = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadDebts();
  }

  Future<void> loadDebts() async {
    isLoading.value = true;
    try {
      final list = showPaidDebts.value
          ? await _repo.getAll()
          : await _repo.getUnpaid();
      debts.assignAll(list);
      totalOutstanding.value = await _repo.getTotalOutstanding();
      unpaidCount.value =
          list.where((d) => d.status != 'paid').length;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> recordPayment({
    required DebtModel debt,
    required double amount,
    required String method,
    String notes = '',
  }) async {
    if (amount <= 0) {
      Get.snackbar(
        'Nominal Tidak Valid',
        'Masukkan nominal lebih dari 0',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return;
    }

    // Credit only up to remaining; excess is kembalian (change)
    final credited = amount.clamp(0.0, debt.remainingAmount);
    final kembalian = amount - credited;

    // Store both paid & kembalian in notes for display in history
    final paymentNotes = kembalian > 0
        ? 'Dibayar: ${CurrencyHelper.formatRupiah(amount)} · Kembalian: ${CurrencyHelper.formatRupiah(kembalian)}'
        : notes;

    final entry = DebtPaymentEntry(
      debtId: debt.id,
      amount: credited,
      method: method,
      notes: paymentNotes,
    );

    await _repo.recordPayment(entry);
    await loadDebts();

    final wasFullyPaid = credited >= debt.remainingAmount;
    final name = debt.customerName.isNotEmpty
        ? debt.customerName
        : debt.invoiceNumber;

    String message;
    if (wasFullyPaid && kembalian > 0) {
      message = '$name telah melunasi hutang\n'
          'Kembalian: ${CurrencyHelper.formatRupiah(kembalian)}';
    } else if (wasFullyPaid) {
      message = '$name telah melunasi hutang';
    } else {
      message = 'Sisa hutang: ${CurrencyHelper.formatRupiah(debt.remainingAmount - credited)}';
    }

    Get.snackbar(
      wasFullyPaid ? 'Hutang Lunas' : 'Pembayaran Dicatat',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor:
          wasFullyPaid ? Colors.green.shade100 : Colors.blue.shade100,
      colorText:
          wasFullyPaid ? Colors.green.shade900 : Colors.blue.shade900,
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> loadReport() async {
    isLoadingReport.value = true;
    try {
      final raw = await _repo.getStats();
      final s = raw['summary'] as Map<String, dynamic>;
      final a = raw['aging'] as Map<String, dynamic>;
      final t = raw['top_debtors'] as List<Map<String, dynamic>>;
      reportStats.value = DebtReportStats(
        totalCount: (s['total_count'] as num?)?.toInt() ?? 0,
        totalAmount: (s['total_amount'] as num?)?.toDouble() ?? 0,
        totalRemaining: (s['total_remaining'] as num?)?.toDouble() ?? 0,
        unpaidCount: (s['unpaid_count'] as num?)?.toInt() ?? 0,
        partialCount: (s['partial_count'] as num?)?.toInt() ?? 0,
        paidCount: (s['paid_count'] as num?)?.toInt() ?? 0,
        unpaidAmount: (s['unpaid_amount'] as num?)?.toDouble() ?? 0,
        partialAmount: (s['partial_amount'] as num?)?.toDouble() ?? 0,
        paidAmount: (s['paid_amount'] as num?)?.toDouble() ?? 0,
        age07: (a['age_0_7'] as num?)?.toDouble() ?? 0,
        age730: (a['age_7_30'] as num?)?.toDouble() ?? 0,
        ageOver30: (a['age_over_30'] as num?)?.toDouble() ?? 0,
        age07Count: (a['age_0_7_count'] as num?)?.toInt() ?? 0,
        age730Count: (a['age_7_30_count'] as num?)?.toInt() ?? 0,
        ageOver30Count: (a['age_over_30_count'] as num?)?.toInt() ?? 0,
        topDebtors: t,
      );
    } finally {
      isLoadingReport.value = false;
    }
  }

  Future<void> deleteDebt(String id) async {
    await _repo.delete(id);
    await loadDebts();
  }

  void showRecordPaymentDialog(BuildContext context, DebtModel debt) {
    final amountCtrl = TextEditingController();
    String selectedMethod = 'Tunai';
    double amountPaid = 0;
    final methods = ['Tunai', 'Transfer', 'QRIS', 'Kartu Debit', 'E-Wallet'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final kembalian = (amountPaid - debt.remainingAmount).clamp(0.0, double.infinity);
          final isOverpaid = amountPaid > debt.remainingAmount;

          return AlertDialog(
            title: Text(
              debt.customerName.isNotEmpty
                  ? 'Bayar Hutang – ${debt.customerName}'
                  : 'Bayar Hutang – ${debt.invoiceNumber}',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sisa hutang: ${CurrencyHelper.formatRupiah(debt.remainingAmount)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedMethod,
                  decoration: const InputDecoration(
                    labelText: 'Metode Pembayaran',
                    isDense: true,
                  ),
                  items: methods
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => selectedMethod = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Nominal Pembayaran',
                    prefixText: 'Rp ',
                    hintText: debt.remainingAmount.toStringAsFixed(0),
                    isDense: true,
                  ),
                  autofocus: true,
                  onChanged: (v) => setState(() {
                    amountPaid = double.tryParse(
                            v.replaceAll('.', '').trim()) ??
                        0;
                  }),
                ),
                if (amountPaid > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isOverpaid
                          ? Colors.green.shade50
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isOverpaid
                            ? Colors.green.shade200
                            : Colors.blue.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isOverpaid ? 'Kembalian' : 'Sisa Hutang',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isOverpaid
                                ? Colors.green.shade700
                                : Colors.blue.shade700,
                          ),
                        ),
                        Text(
                          CurrencyHelper.formatRupiah(isOverpaid
                              ? kembalian
                              : debt.remainingAmount - amountPaid),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isOverpaid
                                ? Colors.green.shade700
                                : Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(
                          amountCtrl.text.replaceAll('.', '').trim()) ??
                      0;
                  Navigator.pop(ctx);
                  recordPayment(
                    debt: debt,
                    amount: amount,
                    method: selectedMethod,
                  );
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }
}
