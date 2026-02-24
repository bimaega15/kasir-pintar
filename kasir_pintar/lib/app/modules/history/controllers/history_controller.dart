import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/transaction_repository.dart';

class HistoryController extends GetxController {
  final _transactionRepo = Get.find<TransactionRepository>();

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
      final list = await _transactionRepo.getAll();
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
}
