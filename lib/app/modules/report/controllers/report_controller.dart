import 'package:get/get.dart';
import '../../../data/providers/storage_provider.dart';
import '../../../data/repositories/transaction_repository.dart';

class ReportController extends GetxController {
  final _transactionRepo = Get.find<TransactionRepository>();
  final _db = Get.find<DatabaseProvider>();

  final totalTransactions = 0.obs;
  final totalCancelled = 0.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadStats();
  }

  Future<void> loadStats() async {
    isLoading.value = true;
    try {
      final transactions = await _transactionRepo.getAll();
      totalTransactions.value = transactions.length;

      final voidLogs = await _db.getVoidLogs();
      totalCancelled.value = voidLogs.length;
    } finally {
      isLoading.value = false;
    }
  }
}
