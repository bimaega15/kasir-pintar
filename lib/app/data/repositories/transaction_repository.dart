import 'package:get/get.dart';
import '../models/payment_entry_model.dart';
import '../models/split_transaction_model.dart';
import '../models/transaction_model.dart';
import '../providers/storage_provider.dart';

class TransactionRepository {
  final DatabaseProvider _db = Get.find<DatabaseProvider>();

  Future<List<TransactionModel>> getAll() => _db.getTransactions();

  Future<void> save(TransactionModel transaction,
          [List<PaymentEntry> paymentEntries = const []]) =>
      _db.insertTransaction(transaction, paymentEntries);

  Future<String> generateInvoiceNumber() => _db.generateInvoiceNumber();

  Future<List<TransactionModel>> getToday() => _db.getTransactionsToday();

  Future<List<PaymentEntry>> getPayments(String transactionId) =>
      _db.getTransactionPayments(transactionId);

  Future<List<SplitTransactionModel>> getSplits(String transactionId) =>
      _db.getSplitTransactionsByTransactionId(transactionId);

  Future<double> getTodayRevenue() async {
    final today = await getToday();
    return today.fold<double>(0.0, (sum, t) => sum + t.total);
  }

  Future<void> delete(String id) => _db.deleteTransaction(id);
}
