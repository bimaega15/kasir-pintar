import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/storage_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../services/check_version_service.dart';

class SettingsController extends GetxController {
  final _db = Get.find<DatabaseProvider>();

  final storeNameController = TextEditingController();
  final taxController = TextEditingController();
  final serviceChargeController = TextEditingController();

  final isLoading = false.obs;
  final selectedPosType = 'restaurant'.obs;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  @override
  void onClose() {
    storeNameController.dispose();
    taxController.dispose();
    serviceChargeController.dispose();
    super.onClose();
  }

  Future<void> loadSettings() async {
    isLoading.value = true;
    try {
      final name = await _db.getSetting('store_name') ?? 'Kasir Pintar';
      final tax = await _db.getSetting('tax_percent') ?? '0';
      final service = await _db.getSetting('service_charge_percent') ?? '0';

      storeNameController.text = name;
      taxController.text = tax;
      serviceChargeController.text = service;
      selectedPosType.value = await _db.getSetting('pos_type') ?? 'restaurant';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveSettings() async {
    final taxText = taxController.text.trim();
    final serviceText = serviceChargeController.text.trim();
    final taxVal = double.tryParse(taxText) ?? 0;
    final serviceVal = double.tryParse(serviceText) ?? 0;

    if (taxVal < 0 || taxVal > 100) {
      Get.snackbar('Error', 'Persentase pajak harus antara 0-100',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (serviceVal < 0 || serviceVal > 100) {
      Get.snackbar('Error', 'Persentase service charge harus antara 0-100',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final name = storeNameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar('Error', 'Nama toko tidak boleh kosong',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    await _db.setSetting('store_name', name);
    await _db.setSetting('tax_percent', taxVal.toString());
    await _db.setSetting('service_charge_percent', serviceVal.toString());
    await _db.setSetting('pos_type', selectedPosType.value);

    Get.snackbar(
      'Tersimpan',
      'Pengaturan berhasil disimpan',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade900,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> checkForUpdates() async {
    final ctx = Get.context;
    if (ctx == null) return;
    await CheckVersionService.checkManual(ctx);
  }

  Future<void> logout() async {
    try {
      // Clear saved local credentials
      await _db.setSetting('app_username', '');
      await _db.setSetting('app_password', '');

      // Sign out from Firebase if logged in via Google
      try {
        if (FirebaseAuth.instance.currentUser != null) {
          await FirebaseAuth.instance.signOut();
        }
      } catch (firebaseError) {
        // Firebase not initialized, skip Firebase logout
        print('Firebase signOut skipped: $firebaseError');
      }

      // Navigate to login screen
      Get.offAllNamed(AppRoutes.login);

      Get.snackbar(
        'Berhasil',
        'Anda telah keluar dari aplikasi',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue.shade100,
        colorText: Colors.blue.shade900,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal keluar: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    }
  }
}
