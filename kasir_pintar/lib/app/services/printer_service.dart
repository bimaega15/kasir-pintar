import 'dart:io';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/models/transaction_model.dart';
import '../data/providers/storage_provider.dart';
import '../utils/helpers/currency_helper.dart';

class PrinterService extends GetxService {
  static const _printerMacKey = 'printer_mac';
  static const _printerNameKey = 'printer_name';

  // Hanya diinisialisasi di Android — plugin tidak support platform lain
  BlueThermalPrinter? _printer;

  final isConnected = false.obs;
  final connectedDeviceName = ''.obs;
  final savedMac = ''.obs;
  final savedName = ''.obs;
  final isLoading = false.obs;
  final devices = <BluetoothDevice>[].obs;

  @override
  void onInit() {
    super.onInit();
    if (!Platform.isAndroid) return;
    _printer = BlueThermalPrinter.instance;
    _loadSavedPrinter();
  }

  Future<void> _loadSavedPrinter() async {
    try {
      final db = Get.find<DatabaseProvider>();
      final mac = await db.getSetting(_printerMacKey);
      final name = await db.getSetting(_printerNameKey);
      if (mac != null) savedMac.value = mac;
      if (name != null) savedName.value = name;
    } catch (_) {}
  }

  // ── Permissions ────────────────────────────────────────────────────────────

  Future<bool> _requestPermissions() async {
    final permissions = <Permission>[
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ];
    final results = await permissions.request();
    return results.values.every((s) => s.isGranted || s.isLimited);
  }

  // ── Scan ───────────────────────────────────────────────────────────────────

  Future<void> scanDevices() async {
    if (!Platform.isAndroid) return;
    isLoading.value = true;
    devices.clear();
    try {
      final granted = await _requestPermissions();
      if (!granted) {
        Get.snackbar(
          'Izin Ditolak',
          'Izin Bluetooth diperlukan untuk memindai printer',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      final bonded = await _printer!.getBondedDevices();
      devices.assignAll(bonded);
      if (devices.isEmpty) {
        Get.snackbar(
          'Tidak Ada Perangkat',
          'Tidak ada printer Bluetooth yang dipasangkan. Pasangkan printer di pengaturan Bluetooth Android terlebih dahulu.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memindai perangkat: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ── Connect / Disconnect ───────────────────────────────────────────────────

  Future<bool> connect(BluetoothDevice device) async {
    if (!Platform.isAndroid) return false;
    isLoading.value = true;
    try {
      await _printer!.connect(device);
      isConnected.value = true;
      connectedDeviceName.value = device.name ?? 'Unknown';

      // Simpan MAC & name ke database
      final db = Get.find<DatabaseProvider>();
      if (device.address != null) {
        savedMac.value = device.address!;
        savedName.value = device.name ?? '';
        await db.setSetting(_printerMacKey, device.address!);
        await db.setSetting(_printerNameKey, device.name ?? '');
      }

      Get.snackbar(
        'Terhubung',
        'Printer ${device.name} berhasil terhubung',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
      );
      return true;
    } catch (e) {
      isConnected.value = false;
      Get.snackbar(
        'Gagal Terhubung',
        'Tidak dapat terhubung ke printer: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> disconnect() async {
    if (!Platform.isAndroid) return;
    try {
      await _printer!.disconnect();
    } catch (_) {}
    isConnected.value = false;
    connectedDeviceName.value = '';
  }

  Future<void> checkConnection() async {
    if (!Platform.isAndroid) return;
    try {
      final connected = await _printer!.isConnected ?? false;
      isConnected.value = connected;
      if (!connected) connectedDeviceName.value = '';
    } catch (_) {
      isConnected.value = false;
    }
  }

  // ── Print Receipt ──────────────────────────────────────────────────────────

  Future<void> printReceipt(TransactionModel transaction) async {
    if (!Platform.isAndroid) {
      Get.snackbar(
        'Tidak Didukung',
        'Fitur cetak hanya tersedia di Android',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await checkConnection();
    if (!isConnected.value) {
      Get.snackbar(
        'Printer Tidak Terhubung',
        'Hubungkan printer Bluetooth terlebih dahulu di menu Printer',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    isLoading.value = true;
    try {
      // ── Header ──
      await _printer!.printCustom('================================', 1, 1);
      await _printer!.printCustom('KASIR PINTAR', 3, 1);
      await _printer!.printCustom('================================', 1, 1);
      await _printer!.printCustom(transaction.invoiceNumber, 1, 1);
      await _printer!.printCustom(
          CurrencyHelper.formatDateTime(transaction.createdAt), 1, 1);
      await _printer!.printCustom('Kasir: ${transaction.cashierName}', 1, 1);
      await _printer!.printCustom('--------------------------------', 1, 1);

      // ── Items ──
      for (final item in transaction.items) {
        await _printer!.printCustom(item.product.name, 1, 0);
        await _printer!.printLeftRight(
          '  ${item.quantity} x ${CurrencyHelper.formatRupiah(item.product.price)}',
          CurrencyHelper.formatRupiah(item.subtotal),
          1,
        );
      }

      // ── Totals ──
      await _printer!.printCustom('--------------------------------', 1, 1);
      await _printer!.printLeftRight(
          'Subtotal', CurrencyHelper.formatRupiah(transaction.subtotal), 1);
      if (transaction.discount > 0) {
        await _printer!.printLeftRight(
          'Diskon',
          '- ${CurrencyHelper.formatRupiah(transaction.discount)}',
          1,
        );
      }
      await _printer!.printCustom('================================', 1, 1);
      await _printer!.printLeftRight(
          'TOTAL', CurrencyHelper.formatRupiah(transaction.total), 2);
      await _printer!.printCustom('================================', 1, 1);
      await _printer!.printLeftRight(
          'Metode', transaction.paymentMethod, 1);
      await _printer!.printLeftRight(
          'Dibayar', CurrencyHelper.formatRupiah(transaction.paymentAmount), 1);
      if (transaction.change > 0) {
        await _printer!.printLeftRight(
          'Kembalian',
          CurrencyHelper.formatRupiah(transaction.change),
          1,
        );
      }

      // ── Footer ──
      await _printer!.printCustom('--------------------------------', 1, 1);
      await _printer!.printCustom('Terima kasih!', 2, 1);
      await _printer!.printCustom('Silakan kunjungi kami kembali.', 1, 1);
      await _printer!.printNewLine();
      await _printer!.printNewLine();
      await _printer!.paperCut();

      Get.snackbar(
        'Cetak Berhasil',
        'Struk berhasil dicetak',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
      );
    } catch (e) {
      Get.snackbar(
        'Gagal Cetak',
        'Error: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ── Test Print ─────────────────────────────────────────────────────────────

  Future<void> testPrint() async {
    if (!Platform.isAndroid) return;
    await checkConnection();
    if (!isConnected.value) {
      Get.snackbar(
        'Printer Tidak Terhubung',
        'Hubungkan printer terlebih dahulu',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    isLoading.value = true;
    try {
      await _printer!.printCustom('================================', 1, 1);
      await _printer!.printCustom('TEST PRINT', 3, 1);
      await _printer!.printCustom('KASIR PINTAR', 2, 1);
      await _printer!.printCustom('================================', 1, 1);
      await _printer!.printCustom('Printer berfungsi dengan baik!', 1, 1);
      await _printer!.printCustom('Siap untuk mencetak struk.', 1, 1);
      await _printer!.printCustom('================================', 1, 1);
      await _printer!.printNewLine();
      await _printer!.printNewLine();
      await _printer!.paperCut();

      Get.snackbar(
        'Test Berhasil',
        'Printer berfungsi dengan baik',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
      );
    } catch (e) {
      Get.snackbar(
        'Gagal Test',
        'Error: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
