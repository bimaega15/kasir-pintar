import 'package:get/get.dart';
import '../models/expense_model.dart';
import '../providers/storage_provider.dart';

class ExpenseRepository {
  final DatabaseProvider _db = Get.find<DatabaseProvider>();

  Future<List<ExpenseModel>> getAll({
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      _db.getExpenses(startDate: startDate, endDate: endDate);

  Future<void> add(ExpenseModel expense) => _db.insertExpense(expense);

  Future<void> update(ExpenseModel expense) => _db.updateExpense(expense);

  Future<void> delete(String id) => _db.deleteExpense(id);

  Future<double> getTotal({DateTime? startDate, DateTime? endDate}) =>
      _db.getTotalExpenses(startDate: startDate, endDate: endDate);

  Future<Map<String, double>> getTotalByCategory({
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      _db.getExpensesByCategory(startDate: startDate, endDate: endDate);
}
