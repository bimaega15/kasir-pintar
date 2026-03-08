import 'package:get/get.dart';
import '../models/category_model.dart';
import '../providers/storage_provider.dart';

class CategoryRepository {
  final DatabaseProvider _db = Get.find<DatabaseProvider>();

  Future<List<CategoryModel>> getAll() => _db.getCategories();

  Future<void> add(CategoryModel category, {int sortOrder = 999}) =>
      _db.insertCategory(category, sortOrder: sortOrder);

  Future<void> update(CategoryModel category) => _db.updateCategory(category);

  Future<void> delete(String id) => _db.deleteCategory(id);
}
