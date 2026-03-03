import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/table_model.dart';
import '../../../data/repositories/table_repository.dart';

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
    final list = await _repo.getAll();
    tables.assignAll(list);
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

    if (editingTable == null) {
      await _repo.add(TableModel(
        number: number,
        capacity: capacity,
        status: selectedStatus.value,
      ));
      Get.snackbar('Berhasil', 'Meja berhasil ditambahkan',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900);
    } else {
      editingTable!
        ..number = number
        ..capacity = capacity
        ..status = selectedStatus.value;
      await _repo.update(editingTable!);
      Get.snackbar('Berhasil', 'Meja berhasil diperbarui',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900);
    }

    await loadTables();
    Get.back();
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
      await _repo.delete(table.id);
      await loadTables();
    }
  }
}
