import 'package:get/get.dart';
import '../models/employee_model.dart';
import '../providers/storage_provider.dart';

class EmployeeRepository {
  final DatabaseProvider _db = Get.find<DatabaseProvider>();

  Future<List<EmployeeModel>> getAll({bool activeOnly = false}) =>
      _db.getEmployees(activeOnly: activeOnly);

  Future<void> add(EmployeeModel employee) => _db.insertEmployee(employee);

  Future<void> update(EmployeeModel employee) => _db.updateEmployee(employee);

  Future<void> delete(String id) => _db.deleteEmployee(id);
}
