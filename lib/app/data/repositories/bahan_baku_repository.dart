import 'package:get/get.dart';
import '../models/bahan_baku_model.dart';
import '../providers/storage_provider.dart';

class BahanBakuRepository {
  final DatabaseProvider _db = Get.find<DatabaseProvider>();

  Future<List<BahanBakuModel>> getAll() => _db.getBahanBakuList();

  Future<BahanBakuModel?> getById(String id) => _db.getBahanBakuById(id);

  Future<void> add(BahanBakuModel bb) => _db.insertBahanBaku(bb);

  Future<void> update(BahanBakuModel bb) => _db.updateBahanBaku(bb);

  Future<void> updateStock(String id, double newStock) =>
      _db.updateBahanBakuStock(id, newStock);

  Future<void> delete(String id) => _db.deleteBahanBaku(id);

  Future<void> addMovement(BahanBakuMovementModel m) =>
      _db.insertBahanBakuMovement(m);

  Future<List<BahanBakuMovementModel>> getMovements({
    String? bahanBakuId,
    int limit = 100,
  }) =>
      _db.getBahanBakuMovements(bahanBakuId: bahanBakuId, limit: limit);
}
