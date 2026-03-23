import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../data/providers/storage_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../services/check_version_service.dart';
import '../../../services/user_session.dart';

class SettingsController extends GetxController {
  final _db = Get.find<DatabaseProvider>();

  final storeNameController = TextEditingController();
  final storeAddressController = TextEditingController();
  final storeFooterController = TextEditingController();
  final taxController = TextEditingController();
  final serviceChargeController = TextEditingController();

  final logoPath = ''.obs;
  final isLoading = false.obs;
  bool _disposed = false;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  @override
  void onClose() {
    _disposed = true;
    storeNameController.dispose();
    storeAddressController.dispose();
    storeFooterController.dispose();
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

      final address = await _db.getSetting('store_address') ?? '';
      final footer = await _db.getSetting('store_footer') ?? '';
      final logo = await _db.getSetting('store_logo_path') ?? '';

      if (_disposed) return;
      storeNameController.text = name;
      storeAddressController.text = address;
      storeFooterController.text = footer;
      taxController.text = tax;
      serviceChargeController.text = service;
      logoPath.value = logo;
    } finally {
      if (!_disposed) isLoading.value = false;
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
    await _db.setSetting('store_address', storeAddressController.text.trim());
    await _db.setSetting('store_footer', storeFooterController.text.trim());
    await _db.setSetting('tax_percent', taxVal.toString());
    await _db.setSetting('service_charge_percent', serviceVal.toString());


    Get.snackbar(
      'Tersimpan',
      'Pengaturan berhasil disimpan',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade900,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> pickLogo() async {
    String? sourcePath;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      sourcePath = result.files.single.path;
    } catch (_) {
      // FilePicker plugin not initialized (e.g. Windows before flutter clean).
      // Fallback: ask user to type the file path manually.
      sourcePath = await _showManualPathDialog();
    }

    if (sourcePath == null || sourcePath.trim().isEmpty) return;
    final src = File(sourcePath.trim());
    if (!src.existsSync()) {
      Get.snackbar('Error', 'File tidak ditemukan: $sourcePath',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900);
      return;
    }

    // Copy to app documents directory so it persists
    final appDir = await getApplicationDocumentsDirectory();
    final destPath = p.join(appDir.path, 'store_logo.png');
    await src.copy(destPath);

    logoPath.value = destPath;
    await _db.setSetting('store_logo_path', destPath);

    Get.snackbar(
      'Logo Disimpan',
      'Logo toko berhasil diperbarui',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade900,
    );
  }

  Future<String?> _showManualPathDialog() async {
    final ctrl = TextEditingController();
    final result = await Get.dialog<String>(
      AlertDialog(
        title: const Text('Pilih Logo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'File picker tidak tersedia.\nMasukkan path lengkap file gambar logo:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                hintText: 'C:\\Users\\...\\logo.png',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: ctrl.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return result;
  }

  Future<void> clearLogo() async {
    logoPath.value = '';
    await _db.setSetting('store_logo_path', '');
  }

  Future<void> checkForUpdates() async {
    final ctx = Get.context;
    if (ctx == null) return;
    await CheckVersionService.checkManual(ctx);
  }

  Future<void> logout() async {
    try {
      // Clear session role
      Get.find<UserSession>().clearSession();

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
