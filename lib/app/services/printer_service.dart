import 'dart:io';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/models/transaction_model.dart';
import '../data/providers/storage_provider.dart';
import '../utils/helpers/currency_helper.dart';
import '../utils/helpers/thermal_receipt_helper.dart';

class PrinterService extends GetxService {
  static const _printerMacKey = 'printer_mac';
  static const _printerNameKey = 'printer_name';
  static const _paperWidthKey = 'printer_paper_width';

  // Hanya diinisialisasi di Android — plugin tidak support platform lain
  BlueThermalPrinter? _printer;

  final isConnected = false.obs;
  final connectedDeviceName = ''.obs;
  final savedMac = ''.obs;
  final savedName = ''.obs;
  final isLoading = false.obs;
  final devices = <BluetoothDevice>[].obs;

  // Paper width setting
  PaperWidth _paperWidth = PaperWidth.mm80;
  PaperWidth get paperWidth => _paperWidth;

  @override
  void onInit() {
    super.onInit();
    if (!Platform.isAndroid) return;
    try {
      _printer = BlueThermalPrinter.instance;
      _loadSavedPrinter();
      _loadPaperWidth();
    } catch (e) {
      print('[PrinterService] Error initializing blue thermal printer: $e');
      _printer = null;
    }
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

  Future<void> _loadPaperWidth() async {
    try {
      final db = Get.find<DatabaseProvider>();
      final saved = await db.getSetting(_paperWidthKey);
      if (saved != null) {
        _paperWidth = PaperWidth.values.firstWhere(
          (e) => e.name == saved,
          orElse: () => PaperWidth.mm80,
        );
      }
    } catch (_) {
      _paperWidth = PaperWidth.mm80;
    }
  }

  Future<void> setPaperWidth(PaperWidth width) async {
    _paperWidth = width;
    try {
      final db = Get.find<DatabaseProvider>();
      await db.setSetting(_paperWidthKey, width.name);
    } catch (_) {}
  }

  // ── Permissions ────────────────────────────────────────────────────────────

  Future<bool> _requestPermissions() async {
    // Jangan request Permission.bluetooth — itu normal/install-time permission
    // (maxSdkVersion="30" di manifest), sehingga di Android 12+ selalu denied.
    // Cukup request runtime permissions yang benar-benar butuh persetujuan user.
    try {
      final results = await [
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
      ].request();

      // Jika user pernah pilih "Jangan tanyakan lagi", arahkan ke Pengaturan app
      if (results.values.any((s) => s.isPermanentlyDenied)) {
        Get.snackbar(
          'Izin Diperlukan',
          'Aktifkan izin Bluetooth di Pengaturan Aplikasi',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
          mainButton: TextButton(
            onPressed: openAppSettings,
            child: const Text('Buka Pengaturan',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
        return false;
      }

      return results.values.every((s) => s.isGranted || s.isLimited);
    } catch (e) {
      print('[PrinterService] Error requesting permissions: $e');
      return false;
    }
  }

  // ── Scan ───────────────────────────────────────────────────────────────────

  Future<void> scanDevices() async {
    if (!Platform.isAndroid || _printer == null) return;
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
    if (!Platform.isAndroid || _printer == null) return false;
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
    if (!Platform.isAndroid || _printer == null) return;
    try {
      await _printer!.disconnect();
    } catch (_) {}
    isConnected.value = false;
    connectedDeviceName.value = '';
  }

  Future<void> checkConnection() async {
    if (!Platform.isAndroid || _printer == null) return;
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
    if (!Platform.isAndroid || _printer == null) {
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
      final formatter = ThermalReceiptFormatter(paperWidth: _paperWidth);

      // ── Header ──
      await _printer!.printCustom(formatter.line(char: '='), 1, 1);
      await _printer!.printCustom(formatter.center('🏪 KASIR PINTAR'), 2, 1);
      await _printer!.printCustom(formatter.line(char: '='), 1, 1);

      // Invoice & DateTime
      await _printer!.printCustom(
        formatter.center(transaction.invoiceNumber),
        1,
        1,
      );
      await _printer!.printCustom(
        formatter.center(CurrencyHelper.formatDateTime(transaction.createdAt)),
        1,
        1,
      );

      // Order type & table
      final orderLabel =
          transaction.orderTypeLabel +
          (transaction.tableNumber != null
              ? ' - Meja ${transaction.tableNumber}'
              : '');
      await _printer!.printCustom(formatter.center(orderLabel), 1, 1);

      if (transaction.cashierName.isNotEmpty) {
        await _printer!.printCustom('Kasir: ${transaction.cashierName}', 1, 0);
      }

      await _printer!.printCustom(formatter.line(char: '-'), 1, 1);

      // ── Items ──
      for (final item in transaction.items) {
        // Item name
        final name = item.product.emoji + ' ' + item.product.name;
        final itemLines = formatter.wrapText(name);
        for (final line in itemLines) {
          await _printer!.printCustom(line, 1, 0);
        }

        // Quantity x Price = Subtotal
        final qtyPrice = formatter.leftRight(
          '  ${item.quantity}x ${CurrencyHelper.formatRupiah(item.product.price)}',
          CurrencyHelper.formatRupiah(item.subtotal),
        );
        await _printer!.printCustom(qtyPrice, 1, 0);
      }

      // ── Totals ──
      await _printer!.printCustom(formatter.line(char: '-'), 1, 1);

      // Subtotal
      await _printer!.printCustom(
        formatter.leftRight(
          'Subtotal',
          CurrencyHelper.formatRupiah(transaction.subtotal),
        ),
        1,
        0,
      );

      // Discount
      if (transaction.discount > 0) {
        await _printer!.printCustom(
          formatter.leftRight(
            'Diskon',
            '- ${CurrencyHelper.formatRupiah(transaction.discount)}',
          ),
          1,
          0,
        );
      }

      // Tax
      if (transaction.taxAmount > 0) {
        await _printer!.printCustom(
          formatter.leftRight(
            'Pajak',
            CurrencyHelper.formatRupiah(transaction.taxAmount),
          ),
          1,
          0,
        );
      }

      // Service Charge
      if (transaction.serviceChargeAmount > 0) {
        await _printer!.printCustom(
          formatter.leftRight(
            'Service Charge',
            CurrencyHelper.formatRupiah(transaction.serviceChargeAmount),
          ),
          1,
          0,
        );
      }

      // Total separator & amount
      await _printer!.printCustom(formatter.line(char: '='), 1, 1);
      await _printer!.printCustom(
        formatter.leftRight(
          'TOTAL',
          CurrencyHelper.formatRupiah(transaction.total),
        ),
        2,
        0,
      );
      await _printer!.printCustom(formatter.line(char: '='), 1, 1);

      // Payment details
      await _printer!.printCustom(
        formatter.leftRight('Metode', transaction.paymentMethod),
        1,
        0,
      );

      await _printer!.printCustom(
        formatter.leftRight(
          'Dibayar',
          CurrencyHelper.formatRupiah(transaction.paymentAmount),
        ),
        1,
        0,
      );

      // Change
      if (transaction.change > 0) {
        await _printer!.printCustom(
          formatter.leftRight(
            'Kembalian',
            CurrencyHelper.formatRupiah(transaction.change),
          ),
          1,
          0,
        );
      }

      // ── Footer ──
      await _printer!.printCustom(formatter.line(char: '-'), 1, 1);
      await _printer!.printCustom(formatter.center('Terima kasih!'), 2, 1);
      await _printer!.printCustom(
        formatter.center('Silakan kunjungi kami kembali.'),
        1,
        1,
      );

      // Additional spacing
      await _printer!.printNewLine();
      await _printer!.printNewLine();

      // Cut paper
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
