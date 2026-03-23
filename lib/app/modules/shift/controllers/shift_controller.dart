import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/shift_model.dart';
import '../../../data/repositories/shift_repository.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/helpers/currency_helper.dart';

// ── Data classes for closing report ──────────────────────────────────────────

class ShiftPaymentEntry {
  final String method;
  double total;
  int count;
  ShiftPaymentEntry(
      {required this.method, required this.total, required this.count});
}

class ShiftProductEntry {
  final String name;
  final String emoji;
  int qty;
  double total;
  ShiftProductEntry(
      {required this.name,
      required this.emoji,
      required this.qty,
      required this.total});
}

class ShiftStats {
  final int txCount;
  final double revenue;
  final double subtotal;
  final double discount;
  final double tax;
  final double serviceCharge;
  final List<ShiftPaymentEntry> payments;
  final List<ShiftProductEntry> products;

  const ShiftStats({
    required this.txCount,
    required this.revenue,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.serviceCharge,
    required this.payments,
    required this.products,
  });
}

// ── Controller ────────────────────────────────────────────────────────────────

class ShiftController extends GetxController {
  final _repo = Get.find<ShiftRepository>();

  final activeShift = Rx<ShiftModel?>(null);
  final isLoading = false.obs;

  // Open shift form
  final cashierNameController = TextEditingController();
  final openingBalanceController = TextEditingController();

  // Close shift form
  final closingBalanceController = TextEditingController();
  final notesController = TextEditingController();

  // Handover (ganti shift) form
  final handoverNewCashierController = TextEditingController();
  final handoverNewBalanceController = TextEditingController();
  final handoverNotesController = TextEditingController();
  final useClosingAsOpening = true.obs;
  final handoverClosingLive = 0.0.obs;

  // Expected cash shown on close shift view
  final expectedCash = 0.0.obs;
  // Live closing balance input (for difference preview)
  final closingBalanceLive = 0.0.obs;

  // Closing report
  final shiftStats = Rx<ShiftStats?>(null);
  final isLoadingReport = false.obs;

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
    handoverNewCashierController.dispose();
    handoverNewBalanceController.dispose();
    handoverNotesController.dispose();
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

      Get.offAllNamed(AppRoutes.main);
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

      Get.offAllNamed(AppRoutes.main);
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

  // ── Closing Report ────────────────────────────────────────────────────────

  Future<void> loadClosingReport(ShiftModel shift) async {
    isLoadingReport.value = true;
    shiftStats.value = null;
    try {
      final raw = await _repo.getShiftStats(
        openedAt: shift.openedAt,
        closedAt: shift.closedAt,
      );
      shiftStats.value = ShiftStats(
        txCount: raw['tx_count'] as int,
        revenue: raw['revenue'] as double,
        subtotal: raw['subtotal'] as double,
        discount: raw['discount'] as double,
        tax: raw['tax'] as double,
        serviceCharge: raw['service_charge'] as double,
        payments: (raw['payments'] as List)
            .map((p) => ShiftPaymentEntry(
                  method: p['method'] as String,
                  total: p['total'] as double,
                  count: p['count'] as int,
                ))
            .toList(),
        products: (raw['products'] as List)
            .map((p) => ShiftProductEntry(
                  name: p['name'] as String,
                  emoji: p['emoji'] as String,
                  qty: p['qty'] as int,
                  total: p['total'] as double,
                ))
            .toList(),
      );
    } finally {
      isLoadingReport.value = false;
    }
  }

  void openClosingReport(ShiftModel shift) {
    Get.toNamed(AppRoutes.closingReport, arguments: shift);
  }

  // ── Ganti Shift (Handover) ────────────────────────────────────────────────

  Future<void> prepareHandover() async {
    await loadExpectedCash();
    handoverNewCashierController.clear();
    handoverNotesController.clear();
    useClosingAsOpening.value = true;
    handoverClosingLive.value = 0.0;
    handoverNewBalanceController.clear();
  }

  Future<void> gantiShift() async {
    final shift = activeShift.value;
    if (shift == null) return;

    final newName = handoverNewCashierController.text.trim();
    if (newName.isEmpty) {
      Get.snackbar(
        'Nama Kasir Baru Kosong',
        'Masukkan nama kasir pengganti',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return;
    }

    final closing = handoverClosingLive.value;
    final notes = handoverNotesController.text.trim();
    final newBalance = useClosingAsOpening.value
        ? closing
        : (double.tryParse(
                handoverNewBalanceController.text.replaceAll(',', '')) ??
            0.0);

    isLoading.value = true;
    try {
      // 1. Close current shift
      await _repo.close(shift.id, closing, expectedCash.value, notes);

      // 2. Open new shift
      final newShift = ShiftModel(
        cashierName: newName,
        openingBalance: newBalance,
      );
      await _repo.open(newShift);
      activeShift.value = newShift;

      // 3. Reset form
      handoverNewCashierController.clear();
      handoverNewBalanceController.clear();
      handoverNotesController.clear();
      expectedCash.value = 0;
      handoverClosingLive.value = 0;

      Get.snackbar(
        'Shift Berhasil Diganti',
        'Selamat bekerja, $newName! '
            '(Saldo Awal: ${CurrencyHelper.formatRupiah(newBalance)})',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE8F5E9),
        colorText: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 3),
      );

      Get.offAllNamed(AppRoutes.main);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal mengganti shift: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
