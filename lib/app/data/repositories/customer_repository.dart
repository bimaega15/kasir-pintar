import 'package:get/get.dart';
import '../models/customer_model.dart';
import '../models/transaction_model.dart';
import '../providers/storage_provider.dart';

class CustomerRepository {
  final DatabaseProvider _db = Get.find<DatabaseProvider>();

  Future<List<CustomerModel>> getAll() => _db.getCustomers();
  Future<void> save(CustomerModel c) => _db.insertCustomer(c);
  Future<void> update(CustomerModel c) => _db.updateCustomer(c);
  Future<void> delete(String id) => _db.deleteCustomer(id);
  Future<List<TransactionModel>> getTransactions(String customerId) =>
      _db.getTransactionsByCustomerId(customerId);
}
