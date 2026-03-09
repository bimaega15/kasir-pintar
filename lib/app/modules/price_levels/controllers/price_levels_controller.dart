import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/price_level_model.dart';
import '../../../data/repositories/price_level_repository.dart';

class PriceLevelsController extends GetxController {
  final _repo = Get.find<PriceLevelRepository>();

  final priceLevels = <PriceLevelModel>[].obs;
  final isLoading = false.obs;

  final nameController = TextEditingController();
  final descController = TextEditingController();

  PriceLevelModel? _editing;
  bool get isEditing => _editing != null;

  @override
  void onInit() {
    super.onInit();
    loadPriceLevels();
  }

  @override
  void onClose() {
    nameController.dispose();
    descController.dispose();
    super.onClose();
  }

  Future<void> loadPriceLevels() async {
    isLoading.value = true;
    try {
      priceLevels.assignAll(await _repo.getAll());
    } finally {
      isLoading.value = false;
    }
  }

  void prepareAdd() {
    _editing = null;
    nameController.clear();
    descController.clear();
  }

  void prepareEdit(PriceLevelModel level) {
    _editing = level;
    nameController.text = level.name;
    descController.text = level.description;
  }

  Future<void> savePriceLevel() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar('Error', 'Nama level tidak boleh kosong',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    try {
      if (_editing == null) {
        final level = PriceLevelModel(
          name: name,
          description: descController.text.trim(),
          sortOrder: priceLevels.length,
        );
        await _repo.add(level, sortOrder: priceLevels.length);
      } else {
        _editing!.name = name;
        _editing!.description = descController.text.trim();
        await _repo.update(_editing!);
      }
      await loadPriceLevels();
      Get.back();
      Future.delayed(const Duration(milliseconds: 100), () {
        Get.snackbar(
          'Berhasil',
          _editing == null ? 'Level harga ditambahkan' : 'Level harga diperbarui',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
          duration: const Duration(seconds: 2),
        );
      });
    } catch (e) {
      Get.snackbar('Error', 'Gagal menyimpan: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> setDefault(PriceLevelModel level) async {
    try {
      await _repo.setDefault(level.id);
      await loadPriceLevels();
      Get.snackbar(
        'Berhasil',
        '"${level.name}" dijadikan level default',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar('Error', 'Gagal: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> deletePriceLevel(PriceLevelModel level) async {
    if (level.isDefault) {
      Get.snackbar('Tidak Bisa Hapus', 'Level default tidak bisa dihapus',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade900);
      return;
    }
    final confirm = await Get.dialog<bool>(AlertDialog(
      title: const Text('Hapus Level Harga'),
      content: Text(
          'Hapus "${level.name}"?\nHarga produk untuk level ini juga akan dihapus.'),
      actions: [
        TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal')),
        TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus')),
      ],
    ));
    if (confirm == true) {
      await _repo.delete(level.id);
      await loadPriceLevels();
      Get.snackbar('Berhasil', 'Level harga dihapus',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
          duration: const Duration(seconds: 2));
    }
  }
}
