import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/table_model.dart';
import '../../../data/repositories/table_repository.dart';
import '../../../routes/app_routes.dart';

class TablesController extends GetxController {
  final _repo = Get.find<TableRepository>();

  final tables = <TableModel>[].obs;

  // Form fields
  final numberController = TextEditingController();
  final capacityController = TextEditingController();
  final selectedStatus = TableStatus.available.obs;
  TableModel? editingTable;

  @override
  void onInit() {
    super.onInit();
    loadTables();
  }

  @override
  void onClose() {
    numberController.dispose();
    capacityController.dispose();
    super.onClose();
  }

  Future<void> loadTables() async {
    try {
      final list = await _repo.getAll();
      tables.assignAll(list);
      print('[loadTables] Successfully loaded ${list.length} tables');
    } catch (e) {
      print('[loadTables] Error loading tables: $e');
      Get.snackbar('Error', 'Gagal memuat meja: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900);
    }
  }

  void prepareAdd() {
    editingTable = null;
    numberController.clear();
    capacityController.text = '4';
    selectedStatus.value = TableStatus.available;
  }

  void prepareEdit(TableModel table) {
    editingTable = table;
    numberController.text = table.number.toString();
    capacityController.text = table.capacity.toString();
    selectedStatus.value = table.status;
  }

  Future<void> saveTable() async {
    final number = int.tryParse(numberController.text.trim());
    final capacity = int.tryParse(capacityController.text.trim()) ?? 4;

    if (number == null || number <= 0) {
      Get.snackbar('Error', 'Nomor meja tidak valid',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      if (editingTable == null) {
        await _repo.add(TableModel(
          number: number,
          capacity: capacity,
          status: selectedStatus.value,
        ));
        Get.snackbar('Berhasil', 'Meja berhasil ditambahkan',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade900,
            duration: const Duration(seconds: 2));
      } else {
        editingTable!
          ..number = number
          ..capacity = capacity
          ..status = selectedStatus.value;
        await _repo.update(editingTable!);
        Get.snackbar('Berhasil', 'Meja berhasil diperbarui',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade900,
            duration: const Duration(seconds: 2));
      }

      await loadTables();
      // Wait for snackbar to show before navigating
      await Future.delayed(const Duration(milliseconds: 500));
      Get.back();
    } catch (e) {
      Get.snackbar('Error', 'Gagal menyimpan meja: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
          duration: const Duration(seconds: 3));
      print('Error saving table: $e');
    }
  }

  Future<void> deleteTable(TableModel table) async {
    if (table.status == TableStatus.occupied) {
      Get.snackbar('Tidak Bisa', 'Meja sedang terisi, tidak bisa dihapus',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade900);
      return;
    }
    final confirm = await Get.dialog<bool>(AlertDialog(
      title: const Text('Hapus Meja'),
      content: Text('Hapus Meja ${table.number}?'),
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
      try {
        await _repo.delete(table.id);
        await loadTables();
        Get.snackbar('Berhasil', 'Meja berhasil dihapus',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade900,
            duration: const Duration(seconds: 2));
      } catch (e) {
        Get.snackbar('Error', 'Gagal menghapus meja: $e',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade900,
            duration: const Duration(seconds: 3));
        print('Error deleting table: $e');
      }
    }
  }
}
