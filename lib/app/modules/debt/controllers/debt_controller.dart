import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/debt_model.dart';
import '../../../data/repositories/debt_repository.dart';
import '../../../utils/helpers/currency_helper.dart';

class DebtController extends GetxController {
  final _repo = Get.find<DebtRepository>();

  final debts = <DebtModel>[].obs;
  final totalOutstanding = 0.0.obs;
  final unpaidCount = 0.obs;
  final isLoading = false.obs;
  final showPaidDebts = false.obs;

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
    if (amount <= 0 || amount > debt.remainingAmount) {
      Get.snackbar(
        'Nominal Tidak Valid',
        'Masukkan nominal antara Rp 1 – ${CurrencyHelper.formatRupiah(debt.remainingAmount)}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return;
    }

    final entry = DebtPaymentEntry(
      debtId: debt.id,
      amount: amount,
      method: method,
      notes: notes,
    );

    await _repo.recordPayment(entry);
    await loadDebts();

    final wasFullyPaid = amount >= debt.remainingAmount;
    Get.snackbar(
      wasFullyPaid ? 'Hutang Lunas' : 'Pembayaran Dicatat',
      wasFullyPaid
          ? '${debt.customerName.isNotEmpty ? debt.customerName : debt.invoiceNumber} telah melunasi hutang'
          : 'Sisa hutang: ${CurrencyHelper.formatRupiah(debt.remainingAmount - amount)}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor:
          wasFullyPaid ? Colors.green.shade100 : Colors.blue.shade100,
      colorText:
          wasFullyPaid ? Colors.green.shade900 : Colors.blue.shade900,
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> deleteDebt(String id) async {
    await _repo.delete(id);
    await loadDebts();
  }

  void showRecordPaymentDialog(BuildContext context, DebtModel debt) {
    final amountCtrl = TextEditingController();
    String selectedMethod = 'Tunai';
    final methods = ['Tunai', 'Transfer', 'QRIS', 'Kartu Debit', 'E-Wallet'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
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
                  hintText:
                      debt.remainingAmount.toStringAsFixed(0),
                  isDense: true,
                ),
                autofocus: true,
              ),
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
        ),
      ),
    );
  }
}
