import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/price_level_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/price_level_repository.dart';
import '../../../data/repositories/product_repository.dart';

class ProductsController extends GetxController {
  final _productRepo = Get.find<ProductRepository>();
  final _categoryRepo = Get.find<CategoryRepository>();
  final _priceLevelRepo = Get.find<PriceLevelRepository>();

  final products = <ProductModel>[].obs;
  final categories = <CategoryModel>[].obs;
  final filterCategory = 'all'.obs;
  final searchQuery = ''.obs;
  final searchController = TextEditingController();

  // Form fields for add/edit
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  final descController = TextEditingController();
  final selectedCategoryId = 'food'.obs;
  final selectedEmoji = '📦'.obs;
  final selectedImagePath = Rxn<String>(); // null = no image selected

  /// Level harga yang tersedia (dimuat sekali)
  final availablePriceLevels = <PriceLevelModel>[].obs;

  /// TextEditingController per level: levelId → controller harga
  final Map<String, TextEditingController> levelPriceControllers = {};

  ProductModel? editingProduct;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
    loadCategories();
    loadPriceLevels();
    searchController.addListener(() {
      searchQuery.value = searchController.text;
    });
  }

  Future<void> loadPriceLevels() async {
    try {
      final levels = await _priceLevelRepo.getAll();
      availablePriceLevels.assignAll(levels);
      _rebuildLevelControllers();
    } catch (e) {
      print('[loadPriceLevels] Error: $e');
    }
  }

  void _rebuildLevelControllers() {
    // Dispose controllers for levels that no longer exist
    final currentIds = availablePriceLevels.map((l) => l.id).toSet();
    final toRemove = levelPriceControllers.keys
        .where((k) => !currentIds.contains(k))
        .toList();
    for (final k in toRemove) {
      levelPriceControllers[k]?.dispose();
      levelPriceControllers.remove(k);
    }
    // Add controllers for new levels
    for (final level in availablePriceLevels) {
      levelPriceControllers.putIfAbsent(
          level.id, () => TextEditingController());
    }
  }

  Future<void> loadCategories() async {
    try {
      final list = await _categoryRepo.getAll();
      // Prepend "Semua" for the filter tab; exclude from form dropdown
      categories.assignAll([
        const CategoryModel(id: 'all', name: 'Semua', icon: '🏪'),
        ...list,
      ]);
      // If editing a product whose categoryId no longer exists, fallback
      if (!categories.any((c) => c.id == selectedCategoryId.value)) {
        selectedCategoryId.value = list.isNotEmpty ? list.first.id : 'other';
      }
    } catch (e) {
      // Fallback to hardcoded defaults if DB fails
      categories.assignAll(CategoryModel.defaultCategories);
    }
  }

  /// Categories excluding "Semua" — used in add/edit product form
  List<CategoryModel> get formCategories =>
      categories.where((c) => c.id != 'all').toList();

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
    for (final ctrl in levelPriceControllers.values) {
      try {
        ctrl.dispose();
      } catch (_) {}
    }
    levelPriceControllers.clear();
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
    final firstReal = formCategories.isNotEmpty ? formCategories.first.id : 'other';
    selectedCategoryId.value = firstReal;
    selectedEmoji.value = '📦';
    selectedImagePath.value = null;

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

    // Clear all level price controllers
    for (final ctrl in levelPriceControllers.values) {
      ctrl.clear();
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
    selectedImagePath.value = product.imagePath;

    // Populate level price controllers for non-default levels only
    // (default level price = product.price, shown in the main Harga field)
    final defaultIds = availablePriceLevels
        .where((l) => l.isDefault)
        .map((l) => l.id)
        .toSet();
    for (final entry in product.priceLevels) {
      if (defaultIds.contains(entry.priceLevelId)) continue;
      final ctrl = levelPriceControllers[entry.priceLevelId];
      if (ctrl != null) {
        ctrl.text = entry.price.toStringAsFixed(0);
      }
    }
    // Clear controllers for levels not in the product (or default)
    final productLevelIds = product.priceLevels.map((e) => e.priceLevelId).toSet();
    for (final id in levelPriceControllers.keys) {
      if (defaultIds.contains(id)) continue;
      if (!productLevelIds.contains(id)) {
        levelPriceControllers[id]?.clear();
      }
    }
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

  // ── Image Picking ──────────────────────────────────────────────────────

  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final sourcePath = result.files.single.path;
    if (sourcePath == null) return;

    // Copy image to app's persistent directory
    final appDir = await getApplicationDocumentsDirectory();
    final imgDir = Directory(p.join(appDir.path, 'product_images'));
    if (!await imgDir.exists()) await imgDir.create(recursive: true);

    final ext = p.extension(sourcePath);
    final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}$ext';
    final destPath = p.join(imgDir.path, fileName);
    await File(sourcePath).copy(destPath);

    selectedImagePath.value = destPath;
  }

  void removeImage() {
    selectedImagePath.value = null;
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

    // Build price level entries:
    // - Default level → always uses the main price field
    // - Non-default levels → use their controller if filled, otherwise skip (fallback to base price)
    final levelEntries = <ProductPriceLevelEntry>[];
    for (final level in availablePriceLevels) {
      if (level.isDefault) {
        // Always store the base price for the default level
        levelEntries.add(ProductPriceLevelEntry(
          priceLevelId: level.id,
          priceLevelName: level.name,
          price: price,
        ));
      } else {
        final ctrl = levelPriceControllers[level.id];
        final levelPrice = double.tryParse(
                ctrl?.text.replaceAll('.', '').replaceAll(',', '') ?? '') ??
            0;
        if (levelPrice > 0) {
          levelEntries.add(ProductPriceLevelEntry(
            priceLevelId: level.id,
            priceLevelName: level.name,
            price: levelPrice,
          ));
        }
      }
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
          imagePath: selectedImagePath.value,
        );
        await _productRepo.add(product);
        await _priceLevelRepo.saveProductPriceLevels(product.id, levelEntries);
        successMsg = 'Produk berhasil ditambahkan';
      } else {
        editingProduct!
          ..name = name
          ..categoryId = selectedCategoryId.value
          ..price = price
          ..stock = stock
          ..description = descController.text.trim()
          ..emoji = selectedEmoji.value
          ..imagePath = selectedImagePath.value;
        await _productRepo.update(editingProduct!);
        await _priceLevelRepo.saveProductPriceLevels(
            editingProduct!.id, levelEntries);
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
