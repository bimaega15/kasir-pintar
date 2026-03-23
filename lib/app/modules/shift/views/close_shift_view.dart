import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/shift_controller.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/helpers/currency_helper.dart';
import '../../../routes/app_routes.dart';

class CloseShiftView extends GetView<ShiftController> {
  const CloseShiftView({super.key});

  @override
  Widget build(BuildContext context) {
    // Load expected cash when view opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadExpectedCash();
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tutup Shift Kasir'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        final shift = controller.activeShift.value;
        if (shift == null) {
          return const Center(child: Text('Tidak ada shift aktif'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shift info card
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.person_rounded,
                              color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shift.cashierName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              'Buka: ${CurrencyHelper.formatDateTime(shift.openedAt)}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _summaryRow(
                      'Saldo Awal',
                      CurrencyHelper.formatRupiah(shift.openingBalance),
                    ),
                    _summaryRow(
                      'Pendapatan Tunai',
                      CurrencyHelper.formatRupiah(
                          controller.expectedCash.value - shift.openingBalance),
                      valueColor: AppColors.success,
                    ),
                    const Divider(height: 16),
                    _summaryRow(
                      'Ekspektasi Kas',
                      CurrencyHelper.formatRupiah(controller.expectedCash.value),
                      isBold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Input saldo aktual
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hitung Kas Aktual',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Hitung uang di laci dan masukkan jumlahnya',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller.closingBalanceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Saldo Akhir (Aktual)',
                        prefixText: 'Rp ',
                        prefixIcon: Icon(Icons.account_balance_wallet_rounded),
                        hintText: '0',
                      ),
                      onChanged: (v) => controller.closingBalanceLive.value =
                          double.tryParse(v.replaceAll(',', '')) ?? 0.0,
                    ),
                    const SizedBox(height: 16),

                    // Live difference
                    Obx(() {
                      final closing = controller.closingBalanceLive.value;
                      final expected = controller.expectedCash.value;
                      final diff = closing - expected;
                      final isPositive = diff >= 0;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isPositive
                              ? AppColors.success.withValues(alpha: 0.08)
                              : AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isPositive
                                ? AppColors.success.withValues(alpha: 0.3)
                                : AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isPositive ? 'Lebih' : 'Kurang',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isPositive
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                            Text(
                              CurrencyHelper.formatRupiah(diff.abs()),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isPositive
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller.notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Catatan (opsional)',
                        prefixIcon: Icon(Icons.notes_rounded),
                        hintText: 'Keterangan selisih, dll.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Obx(() => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: controller.isLoading.value
                          ? null
                          : _confirmClose,
                      icon: controller.isLoading.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.lock_rounded),
                      label: Text(controller.isLoading.value
                          ? 'Menutup Shift...'
                          : 'Tutup Shift'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.shiftHandover),
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text('Ganti Shift (Serah Terima)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _confirmClose() {
    Get.dialog(
      AlertDialog(
        title: const Text('Tutup Shift?'),
        content: const Text(
            'Pastikan semua transaksi sudah selesai sebelum menutup shift.'),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.closeShift();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Tutup Shift',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: isBold ? AppColors.textPrimary : AppColors.textSecondary)),
          Text(value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: valueColor ?? AppColors.textPrimary,
              )),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 6,
                offset: Offset(0, 2))
          ],
        ),
        child: child,
      );
}
