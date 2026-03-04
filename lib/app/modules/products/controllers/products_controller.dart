import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../routes/app_routes.dart';

class ProductsController extends GetxController {
  final _productRepo = Get.find<ProductRepository>();

  final products = <ProductModel>[].obs;
  final filterCategory = 'all'.obs;
  final searchQuery = ''.obs;
  final searchController = TextEditingController();

  final categories = CategoryModel.defaultCategories;

  // Form fields for add/edit
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  final descController = TextEditingController();
  final selectedCategoryId = 'food'.obs;
  final selectedEmoji = '📦'.obs;

  ProductModel? editingProduct;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
    searchController.addListener(() {
      searchQuery.value = searchController.text;
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    nameController.dispose();
    priceController.dispose();
    stockController.dispose();
    descController.dispose();
    super.onClose();
  }

  Future<void> loadProducts() async {
    try {
      final list = await _productRepo.getAll();
      products.assignAll(list);
      print('[loadProducts] Successfully loaded ${list.length} products');
    } catch (e) {
      print('[loadProducts] Error loading products: $e');
      Get.snackbar('Error', 'Gagal memuat produk: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900);
    }
  }

  List<ProductModel> get filteredProducts {
    var list = products.toList();
    if (filterCategory.value != 'all') {
      list = list.where((p) => p.categoryId == filterCategory.value).toList();
    }
    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      list = list.where((p) => p.name.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  // ── Form ──────────────────────────────────────────────────────────────────

  void prepareAdd() {
    editingProduct = null;
    nameController.clear();
    priceController.clear();
    stockController.clear();
    descController.clear();
    selectedCategoryId.value = 'food';
    selectedEmoji.value = '📦';
  }

  void prepareEdit(ProductModel product) {
    editingProduct = product;
    nameController.text = product.name;
    priceController.text = product.price.toStringAsFixed(0);
    stockController.text = product.stock.toString();
    descController.text = product.description;
    selectedCategoryId.value = product.categoryId;
    selectedEmoji.value = product.emoji;
  }

  Future<void> saveProduct() async {
    final name = nameController.text.trim();
    final price = double.tryParse(
            priceController.text.replaceAll('.', '').replaceAll(',', '')) ??
        0;
    final stock = int.tryParse(stockController.text) ?? 0;

    if (name.isEmpty) {
      Get.snackbar('Error', 'Nama produk tidak boleh kosong',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (price <= 0) {
      Get.snackbar('Error', 'Harga harus lebih dari 0',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      if (editingProduct == null) {
        final product = ProductModel(
          name: name,
          categoryId: selectedCategoryId.value,
          price: price,
          stock: stock,
          description: descController.text.trim(),
          emoji: selectedEmoji.value,
        );
        await _productRepo.add(product);
        Get.snackbar('Berhasil', 'Produk berhasil ditambahkan',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade900,
            duration: const Duration(seconds: 2));
      } else {
        editingProduct!
          ..name = name
          ..categoryId = selectedCategoryId.value
          ..price = price
          ..stock = stock
          ..description = descController.text.trim()
          ..emoji = selectedEmoji.value;
        await _productRepo.update(editingProduct!);
        Get.snackbar('Berhasil', 'Produk berhasil diperbarui',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade900,
            duration: const Duration(seconds: 2));
      }

      await loadProducts();
      // Back to previous page
      Get.back();
    } catch (e) {
      Get.snackbar('Error', 'Gagal menyimpan produk: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
          duration: const Duration(seconds: 3));
      print('Error saving product: $e');
    }
  }

  Future<void> deleteProduct(ProductModel product) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Hapus "${product.name}" dari daftar produk?'),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _productRepo.delete(product.id);
        await loadProducts();
        Get.snackbar('Berhasil', 'Produk berhasil dihapus',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade900,
            duration: const Duration(seconds: 2));
      } catch (e) {
        Get.snackbar('Error', 'Gagal menghapus produk: $e',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade900,
            duration: const Duration(seconds: 3));
        print('Error deleting product: $e');
      }
    }
  }
}
