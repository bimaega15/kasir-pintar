import 'package:get/get.dart';
import '../models/product_model.dart';
import '../providers/storage_provider.dart';

class ProductRepository {
  final DatabaseProvider _db = Get.find<DatabaseProvider>();

  Future<List<ProductModel>> getAll() => _db.getProducts();

  Future<void> add(ProductModel product) => _db.insertProduct(product);

  Future<void> update(ProductModel product) => _db.updateProduct(product);

  Future<void> delete(String id) => _db.deleteProduct(id);
}
