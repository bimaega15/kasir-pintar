import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';

class ProductsController extends GetxController {
  final _productRepo = Get.find<ProductRepository>();

  final products = <ProductModel>[].obs;
  final filterCategory = 'all'.obs;
  final searchQuery = ''.obs;
  final searchController = TextEditingController();

  List<CategoryModel> get categories => CategoryModel.defaultCategories;

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
    try {
      searchController.dispose();
    } catch (e) {
      print('Error disposing searchController: $e');
    }
    try {
      nameController.dispose();
    } catch (e) {
      print('Error disposing nameController: $e');
    }
    try {
      priceController.dispose();
    } catch (e) {
      print('Error disposing priceController: $e');
    }
    try {
      stockController.dispose();
    } catch (e) {
      print('Error disposing stockController: $e');
    }
    try {
      descController.dispose();
    } catch (e) {
      print('Error disposing descController: $e');
    }
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
    selectedCategoryId.value = 'food';
    selectedEmoji.value = '📦';
    
    // Safely reset controllers
    try {
      if (!nameController.text.isEmpty) nameController.clear();
      if (!priceController.text.isEmpty) priceController.clear();
      if (!stockController.text.isEmpty) stockController.clear();
      if (!descController.text.isEmpty) descController.clear();
    } catch (e) {
      print('Controller disposed, recreating: $e');
      _reinitializeControllers();
    }
  }

  void prepareEdit(ProductModel product) {
    editingProduct = product;
    try {
      nameController.text = product.name;
      priceController.text = product.price.toStringAsFixed(0);
      stockController.text = product.stock.toString();
      descController.text = product.description;
    } catch (e) {
      print('Controller disposed, recreating: $e');
      _reinitializeControllers();
      nameController.text = product.name;
      priceController.text = product.price.toStringAsFixed(0);
      stockController.text = product.stock.toString();
      descController.text = product.description;
    }
    selectedCategoryId.value = product.categoryId;
    selectedEmoji.value = product.emoji;
  }

  void _reinitializeControllers() {
    try {
      nameController.dispose();
    } catch (_) {}
    try {
      priceController.dispose();
    } catch (_) {}
    try {
      stockController.dispose();
    } catch (_) {}
    try {
      descController.dispose();
    } catch (_) {}
    
    // Create new controllers
    // This is a fallback, shouldn't normally happen
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
      String successMsg = '';
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
        successMsg = 'Produk berhasil ditambahkan';
      } else {
        editingProduct!
          ..name = name
          ..categoryId = selectedCategoryId.value
          ..price = price
          ..stock = stock
          ..description = descController.text.trim()
          ..emoji = selectedEmoji.value;
        await _productRepo.update(editingProduct!);
        successMsg = 'Produk berhasil diperbarui';
      }

      print('[saveProduct] Product saved successfully');
      await loadProducts();
      print('[saveProduct] Attempting to go back...');

      // Go back FIRST
      Get.back();
      print('[saveProduct] Back called successfully');

      // THEN show snackbar in the previous context
      Future.delayed(const Duration(milliseconds: 100), () {
        Get.snackbar('Berhasil', successMsg,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade900,
            duration: const Duration(seconds: 2));
      });
    } catch (e) {
      print('[saveProduct] Error occurred: $e');
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
