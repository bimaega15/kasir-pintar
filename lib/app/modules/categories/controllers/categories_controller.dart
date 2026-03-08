import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/category_model.dart';
import '../../../data/repositories/category_repository.dart';

class CategoriesController extends GetxController {
  final _repo = Get.find<CategoryRepository>();

  final categories = <CategoryModel>[].obs;
  final isLoading = false.obs;

  // Form fields for add/edit
  final nameController = TextEditingController();
  final selectedIcon = '📦'.obs;

  CategoryModel? _editingCategory;
  bool get isEditing => _editingCategory != null;

  static const List<String> availableIcons = [
    '🍔', '🍕', '🍣', '🍜', '🍗', '🥩', '🥗', '🍱',
    '☕', '🧃', '🥤', '🍵', '🧋', '🍺', '🍹', '💧',
    '🍿', '🍰', '🍩', '🧁', '🍫', '🍬', '🍪', '🥐',
    '📦', '🛒', '🏪', '⭐', '🎁', '🔖', '💊', '🧴',
  ];

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  @override
  void onClose() {
    nameController.dispose();
    super.onClose();
  }

  Future<void> loadCategories() async {
    isLoading.value = true;
    try {
      final list = await _repo.getAll();
      categories.assignAll(list);
    } finally {
      isLoading.value = false;
    }
  }

  void prepareAdd() {
    _editingCategory = null;
    nameController.clear();
    selectedIcon.value = '📦';
  }

  void prepareEdit(CategoryModel category) {
    _editingCategory = category;
    nameController.text = category.name;
    selectedIcon.value = category.icon;
  }

  Future<void> saveCategory() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar('Error', 'Nama kategori tidak boleh kosong',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      if (_editingCategory == null) {
        final category = CategoryModel(
          id: const Uuid().v4(),
          name: name,
          icon: selectedIcon.value,
        );
        await _repo.add(category);
      } else {
        final updated = CategoryModel(
          id: _editingCategory!.id,
          name: name,
          icon: selectedIcon.value,
        );
        await _repo.update(updated);
      }

      await loadCategories();
      Get.back();
      Future.delayed(const Duration(milliseconds: 100), () {
        Get.snackbar(
          'Berhasil',
          _editingCategory == null
              ? 'Kategori berhasil ditambahkan'
              : 'Kategori berhasil diperbarui',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
          duration: const Duration(seconds: 2),
        );
      });
    } catch (e) {
      Get.snackbar('Error', 'Gagal menyimpan kategori: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900);
    }
  }

  Future<void> deleteCategory(CategoryModel category) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text('Hapus kategori "${category.name}"?\n\nProduk dalam kategori ini tidak akan terhapus.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _repo.delete(category.id);
        await loadCategories();
        Get.snackbar(
          'Berhasil',
          'Kategori berhasil dihapus',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
          duration: const Duration(seconds: 2),
        );
      } catch (e) {
        Get.snackbar('Error', 'Gagal menghapus kategori: $e',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade900);
      }
    }
  }
}
