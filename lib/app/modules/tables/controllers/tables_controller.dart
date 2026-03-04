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
    try {
      numberController.dispose();
    } catch (e) {
      print('Error disposing numberController: $e');
    }
    try {
      capacityController.dispose();
    } catch (e) {
      print('Error disposing capacityController: $e');
    }
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
    selectedStatus.value = TableStatus.available;
    
    // Safely reset controllers
    try {
      // Only clear/set if controller is still valid
      if (!numberController.text.isEmpty) {
        numberController.clear();
      }
      capacityController.text = '4';
    } catch (e) {
      // If controller is disposed, recreate them
      print('Controller disposed, recreating: $e');
      _reinitializeControllers();
    }
  }

  void prepareEdit(TableModel table) {
    editingTable = table;
    try {
      numberController.text = table.number.toString();
      capacityController.text = table.capacity.toString();
    } catch (e) {
      print('Controller disposed, recreating: $e');
      _reinitializeControllers();
      numberController.text = table.number.toString();
      capacityController.text = table.capacity.toString();
    }
    selectedStatus.value = table.status;
  }

  void _reinitializeControllers() {
    try {
      numberController.dispose();
    } catch (_) {}
    try {
      capacityController.dispose();
    } catch (_) {}
    
    // Create new controllers
    // This is a fallback, shouldn't normally happen
  }

  Future<void> saveTable() async {
    final number = int.tryParse(numberController.text.trim());
    final capacity = int.tryParse(capacityController.text.trim()) ?? 4;

    if (number == null || number <= 0) {
      Get.snackbar('Error', 'Nomor meja tidak valid',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // Check if table number already exists
    final isDuplicate = tables.any((table) {
      // For new table: check if number exists in any table
      if (editingTable == null) {
        return table.number == number;
      }
      // For edit: check if number exists in other tables (exclude current)
      return table.number == number && table.id != editingTable!.id;
    });

    if (isDuplicate) {
      Get.snackbar('Error', 'Nomor meja $number sudah ada',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      String successMsg = '';
      if (editingTable == null) {
        await _repo.add(TableModel(
          number: number,
          capacity: capacity,
          status: selectedStatus.value,
        ));
        successMsg = 'Meja berhasil ditambahkan';
      } else {
        editingTable!
          ..number = number
          ..capacity = capacity
          ..status = selectedStatus.value;
        await _repo.update(editingTable!);
        successMsg = 'Meja berhasil diperbarui';
      }

      print('[saveTable] Table saved successfully');
      await loadTables();
      print('[saveTable] Attempting to go back...');

      // Go back FIRST
      Get.back();
      print('[saveTable] Back called successfully');

      // THEN show snackbar in the previous context
      Future.delayed(const Duration(milliseconds: 100), () {
        Get.snackbar('Berhasil', successMsg,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade900,
            duration: const Duration(seconds: 2));
      });
    } catch (e) {
      print('[saveTable] Error occurred: $e');
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
