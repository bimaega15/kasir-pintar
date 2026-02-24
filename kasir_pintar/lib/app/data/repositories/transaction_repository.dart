import 'package:get/get.dart';
import '../models/transaction_model.dart';
import '../providers/storage_provider.dart';

class TransactionRepository {
  final DatabaseProvider _db = Get.find<DatabaseProvider>();

  Future<List<TransactionModel>> getAll() => _db.getTransactions();

  Future<void> save(TransactionModel transaction) =>
      _db.insertTransaction(transaction);

  Future<String> generateInvoiceNumber() => _db.generateInvoiceNumber();

  Future<List<TransactionModel>> getToday() => _db.getTransactionsToday();

  Future<double> getTodayRevenue() async {
    final today = await getToday();
    return today.fold<double>(0.0, (sum, t) => sum + t.total);
  }
}
