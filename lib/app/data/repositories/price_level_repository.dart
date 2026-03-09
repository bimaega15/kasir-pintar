import 'package:get/get.dart';
import '../models/price_level_model.dart';
import '../providers/storage_provider.dart';

class PriceLevelRepository {
  final DatabaseProvider _db = Get.find<DatabaseProvider>();

  Future<List<PriceLevelModel>> getAll() => _db.getPriceLevels();

  Future<void> add(PriceLevelModel level, {int sortOrder = 99}) =>
      _db.insertPriceLevel(level, sortOrder: sortOrder);

  Future<void> update(PriceLevelModel level) => _db.updatePriceLevel(level);

  Future<void> setDefault(String id) => _db.setDefaultPriceLevel(id);

  Future<void> delete(String id) => _db.deletePriceLevel(id);

  Future<void> saveProductPriceLevels(
          String productId, List<ProductPriceLevelEntry> entries) =>
      _db.saveProductPriceLevels(productId, entries);
}
