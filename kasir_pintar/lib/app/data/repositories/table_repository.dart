import 'package:get/get.dart';
import '../models/table_model.dart';
import '../providers/storage_provider.dart';

class TableRepository {
  final DatabaseProvider _db = Get.find<DatabaseProvider>();

  Future<List<TableModel>> getAll() => _db.getTables();

  Future<void> add(TableModel table) => _db.insertTable(table);

  Future<void> update(TableModel table) => _db.updateTable(table);

  Future<void> delete(String id) => _db.deleteTable(id);

  Future<void> setOccupied(String tableId, String orderId) =>
      _db.setTableOccupied(tableId, orderId);

  Future<void> setAvailable(String tableId) =>
      _db.setTableAvailable(tableId);
}
