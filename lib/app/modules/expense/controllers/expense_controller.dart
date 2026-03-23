import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/helpers/currency_helper.dart';

class ExpenseController extends GetxController {
  final _repo = Get.find<ExpenseRepository>();

  final expenses = <ExpenseModel>[].obs;
  final totalExpense = 0.0.obs;
  final categoryTotals = <String, double>{}.obs;
  final isLoading = false.obs;

  // Filter
  final selectedPeriod = 'Hari Ini'.obs;
  late DateTime startDate;
  late DateTime endDate;

  // Form
  final formKey = GlobalKey<FormState>();
  final descController = TextEditingController();
  final amountController = TextEditingController();
  final notesController = TextEditingController();
  final selectedCategory = ''.obs;
  final selectedPaymentMethod = 'Tunai'.obs;
  final selectedDate = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    _setTodayPeriod();
    loadExpenses();
  }

  void _setTodayPeriod() {
    final now = DateTime.now();
    startDate = DateTime(now.year, now.month, now.day);
    endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  Future<void> loadExpenses() async {
    isLoading.value = true;
    try {
      final list = await _repo.getAll(startDate: startDate, endDate: endDate);
      expenses.assignAll(list);
      totalExpense.value = list.fold(0.0, (sum, e) => sum + e.amount);
      final cats = await _repo.getTotalByCategory(
          startDate: startDate, endDate: endDate);
      categoryTotals.assignAll(cats);
    } finally {
      isLoading.value = false;
    }
  }

  void setPeriod(String period) {
    selectedPeriod.value = period;
    final now = DateTime.now();
    switch (period) {
      case 'Hari Ini':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'Minggu Ini':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'Bulan Ini':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
    }
    loadExpenses();
  }

  void openAddForm() {
    _resetForm();
    Get.toNamed(AppRoutes.addEditExpense);
  }

  void openEditForm(ExpenseModel expense) {
    selectedCategory.value = expense.category;
    descController.text = expense.description;
    amountController.text = expense.amount.toStringAsFixed(0);
    selectedPaymentMethod.value = expense.paymentMethod;
    selectedDate.value = expense.date;
    notesController.text = expense.notes;
    Get.toNamed(AppRoutes.addEditExpense, arguments: expense);
  }

  Future<void> saveExpense() async {
    final existing = Get.arguments as ExpenseModel?;

    if (!formKey.currentState!.validate()) return;
    if (selectedCategory.value.isEmpty) {
      Get.snackbar(
        'Kategori Wajib Diisi',
        'Pilih kategori pengeluaran',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return;
    }

    final amount = CurrencyHelper.parseRupiah(amountController.text);
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

    if (existing != null) {
      await _repo.update(existing.copyWith(
        category: selectedCategory.value,
        description: descController.text.trim(),
        amount: amount,
        paymentMethod: selectedPaymentMethod.value,
        date: selectedDate.value,
        notes: notesController.text.trim(),
      ));
    } else {
      await _repo.add(ExpenseModel.create(
        category: selectedCategory.value,
        description: descController.text.trim(),
        amount: amount,
        paymentMethod: selectedPaymentMethod.value,
        date: selectedDate.value,
        notes: notesController.text.trim(),
      ));
    }

    Get.back();
    loadExpenses();
    Get.snackbar(
      existing != null ? 'Pengeluaran Diperbarui' : 'Pengeluaran Ditambahkan',
      existing != null
          ? 'Data pengeluaran berhasil diperbarui'
          : 'Pengeluaran operasional berhasil dicatat',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade900,
    );
  }

  Future<void> deleteExpense(ExpenseModel expense) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Pengeluaran'),
        content: Text(
          'Hapus pengeluaran "${expense.description.isNotEmpty ? expense.description : expense.category}" '
          'sebesar ${CurrencyHelper.formatRupiah(expense.amount)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _repo.delete(expense.id);
      loadExpenses();
      Get.snackbar(
        'Dihapus',
        'Pengeluaran berhasil dihapus',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _resetForm() {
    selectedCategory.value = '';
    descController.clear();
    amountController.clear();
    selectedPaymentMethod.value = 'Tunai';
    selectedDate.value = DateTime.now();
    notesController.clear();
  }

  @override
  void onClose() {
    descController.dispose();
    amountController.dispose();
    notesController.dispose();
    super.onClose();
  }
}
