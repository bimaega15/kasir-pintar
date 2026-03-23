import 'package:get/get.dart';
import '../models/debt_model.dart';
import '../providers/storage_provider.dart';

class DebtRepository {
  final DatabaseProvider _db = Get.find<DatabaseProvider>();

  Future<void> save(DebtModel debt) => _db.insertDebt(debt);

  Future<List<DebtModel>> getAll() => _db.getDebts();

  Future<List<DebtModel>> getUnpaid() => _db.getDebts(unpaidOnly: true);

  Future<DebtModel?> getById(String id) => _db.getDebtById(id);

  Future<DebtModel?> getByInvoice(String invoiceNumber) =>
      _db.getDebtByInvoice(invoiceNumber);

  Future<void> recordPayment(DebtPaymentEntry payment) =>
      _db.insertDebtPayment(payment);

  Future<void> delete(String id) => _db.deleteDebt(id);

  Future<double> getTotalOutstanding() => _db.getTotalOutstandingDebt();

  Future<Map<String, dynamic>> getStats() => _db.getDebtStats();
}
