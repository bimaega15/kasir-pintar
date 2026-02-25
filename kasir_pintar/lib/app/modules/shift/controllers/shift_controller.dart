import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/shift_model.dart';
import '../../../data/repositories/shift_repository.dart';
import '../../../routes/app_routes.dart';

class ShiftController extends GetxController {
  final _repo = Get.find<ShiftRepository>();

  final activeShift = Rx<ShiftModel?>(null);
  final isLoading = false.obs;

  final cashierNameController = TextEditingController();
  final openingBalanceController = TextEditingController();
  final closingBalanceController = TextEditingController();
  final notesController = TextEditingController();

  // Expected cash shown on close shift view
  final expectedCash = 0.0.obs;
  // Live closing balance input (for difference preview)
  final closingBalanceLive = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    loadActiveShift();
  }

  @override
  void onClose() {
    cashierNameController.dispose();
    openingBalanceController.dispose();
    closingBalanceController.dispose();
    notesController.dispose();
    super.onClose();
  }

  Future<void> loadActiveShift() async {
    isLoading.value = true;
    try {
      activeShift.value = await _repo.getActive();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> openShift() async {
    final name = cashierNameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar(
        'Nama Kosong',
        'Masukkan nama kasir terlebih dahulu',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final balance =
        double.tryParse(openingBalanceController.text.replaceAll(',', '')) ??
            0.0;

    isLoading.value = true;
    try {
      final shift = ShiftModel(
        cashierName: name,
        openingBalance: balance,
      );
      await _repo.open(shift);
      activeShift.value = shift;

      cashierNameController.clear();
      openingBalanceController.clear();

      Get.snackbar(
        'Shift Dibuka',
        'Selamat bekerja, $name!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE8F5E9),
        colorText: const Color(0xFF2E7D32),
      );

      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal membuka shift: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<ShiftModel>> getAllShifts() => _repo.getAll();

  Future<void> loadExpectedCash() async {
    final shift = activeShift.value;
    if (shift == null) return;
    final tunai = await _repo.getTunaiRevenueSince(shift.openedAt);
    expectedCash.value = shift.openingBalance + tunai;
  }

  Future<void> closeShift() async {
    final shift = activeShift.value;
    if (shift == null) return;

    final closing =
        double.tryParse(closingBalanceController.text.replaceAll(',', '')) ??
            0.0;
    final notes = notesController.text.trim();

    isLoading.value = true;
    try {
      await _repo.close(shift.id, closing, expectedCash.value, notes);
      activeShift.value = null;

      closingBalanceController.clear();
      notesController.clear();
      expectedCash.value = 0;

      Get.snackbar(
        'Shift Ditutup',
        'Shift berhasil ditutup',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE8F5E9),
        colorText: const Color(0xFF2E7D32),
      );

      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menutup shift: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
