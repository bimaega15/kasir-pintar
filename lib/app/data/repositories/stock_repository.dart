import 'package:get/get.dart';
import '../models/stock_movement_model.dart';
import '../providers/storage_provider.dart';

class StockRepository {
  final DatabaseProvider _db = Get.find<DatabaseProvider>();

  Future<void> addMovement(StockMovementModel m) =>
      _db.insertStockMovement(m);

  Future<List<StockMovementModel>> getMovements(
          {String? productId, int limit = 100}) =>
      _db.getStockMovements(productId: productId, limit: limit);

  Future<void> createOpname(StockOpnameModel opname) =>
      _db.insertStockOpname(opname);

  Future<void> updateOpname(StockOpnameModel opname) =>
      _db.updateStockOpname(opname);

  Future<List<StockOpnameModel>> getOpnames() => _db.getStockOpnames();

  Future<List<StockOpnameItemModel>> getOpnameItems(String opnameId) =>
      _db.getStockOpnameItems(opnameId);

  Future<void> saveOpnameItem(StockOpnameItemModel item) =>
      _db.upsertStockOpnameItem(item);

  Future<void> deleteOpname(String id) => _db.deleteStockOpname(id);
}
