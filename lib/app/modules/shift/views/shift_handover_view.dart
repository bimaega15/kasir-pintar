import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/shift_controller.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/helpers/currency_helper.dart';

class ShiftHandoverView extends GetView<ShiftController> {
  const ShiftHandoverView({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.prepareHandover();
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ganti Shift'),
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
              _buildCurrentShiftCard(shift),
              const SizedBox(height: 16),
              _buildCloseSection(),
              const SizedBox(height: 16),
              _buildOpenSection(),
              const SizedBox(height: 24),
              _buildHandoverButton(),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  // ── Current shift info ────────────────────────────────────────────────────

  Widget _buildCurrentShiftCard(shift) {
    return _card(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person_rounded,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Shift Aktif Sekarang',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                Text(shift.cashierName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                Text(
                  'Buka: ${CurrencyHelper.formatDateTime(shift.openedAt)}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Obx(() => Text(
                CurrencyHelper.formatRupiah(controller.expectedCash.value),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.success),
              )),
        ],
      ),
    );
  }

  // ── Close current shift section ───────────────────────────────────────────

  Widget _buildCloseSection() {
    return _card(
      label: '1',
      title: 'Tutup Shift Saat Ini',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            final exp = controller.expectedCash.value;
            final closing = controller.handoverClosingLive.value;
            final diff = closing - exp;
            final isPos = diff >= 0;
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _summaryRow('Ekspektasi Kas',
                      CurrencyHelper.formatRupiah(exp)),
                  if (closing > 0) ...[
                    _summaryRow('Saldo Akhir Aktual',
                        CurrencyHelper.formatRupiah(closing)),
                    const Divider(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Selisih',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isPos
                                    ? AppColors.success
                                    : AppColors.error)),
                        Text(
                          '${diff >= 0 ? '+' : ''}${CurrencyHelper.formatRupiah(diff)}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isPos
                                  ? AppColors.success
                                  : AppColors.error),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 14),
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Saldo Akhir Aktual',
              hintText: '0',
              prefixText: 'Rp ',
              prefixIcon:
                  Icon(Icons.account_balance_wallet_rounded),
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (v) {
              final val =
                  double.tryParse(v.replaceAll(',', '')) ?? 0.0;
              controller.handoverClosingLive.value = val;
              if (controller.useClosingAsOpening.value) {
                controller.handoverNewBalanceController.text =
                    val.toStringAsFixed(0);
              }
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller.handoverNotesController,
            decoration: const InputDecoration(
              labelText: 'Catatan Serah Terima (opsional)',
              prefixIcon: Icon(Icons.notes_rounded),
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  // ── Open new shift section ────────────────────────────────────────────────

  Widget _buildOpenSection() {
    return _card(
      label: '2',
      title: 'Buka Shift Baru',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller.handoverNewCashierController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nama Kasir Pengganti *',
              prefixIcon: Icon(Icons.person_add_rounded),
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),
          Obx(() => SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Gunakan saldo akhir sebagai saldo awal',
                    style: TextStyle(fontSize: 13)),
                subtitle: Text(
                  'Saldo awal = ${CurrencyHelper.formatRupiah(controller.handoverClosingLive.value)}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
                value: controller.useClosingAsOpening.value,
                activeTrackColor: AppColors.primary,
                onChanged: (v) {
                  controller.useClosingAsOpening.value = v;
                  if (v) {
                    controller.handoverNewBalanceController.text =
                        controller.handoverClosingLive.value
                            .toStringAsFixed(0);
                  } else {
                    controller.handoverNewBalanceController.clear();
                  }
                },
              )),
          Obx(() => AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: controller.useClosingAsOpening.value
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color:
                            AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.success, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Saldo awal: ${CurrencyHelper.formatRupiah(controller.handoverClosingLive.value)}',
                        style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w500,
                            fontSize: 13),
                      ),
                    ],
                  ),
                ),
                secondChild: TextField(
                  controller:
                      controller.handoverNewBalanceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Saldo Awal Shift Baru',
                    prefixText: 'Rp ',
                    prefixIcon: Icon(Icons.savings_rounded),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // ── Handover button ───────────────────────────────────────────────────────

  Widget _buildHandoverButton() {
    return Obx(() => SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: controller.isLoading.value ? null : _confirmHandover,
            icon: controller.isLoading.value
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.swap_horiz_rounded),
            label: Text(controller.isLoading.value
                ? 'Memproses Ganti Shift...'
                : 'Ganti Shift Sekarang'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ));
  }

  void _confirmHandover() {
    final newName =
        controller.handoverNewCashierController.text.trim();
    if (newName.isEmpty) {
      Get.snackbar(
        'Nama Kosong',
        'Masukkan nama kasir pengganti',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return;
    }

    Get.dialog(
      AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Konfirmasi Ganti Shift'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Shift akan diganti dengan:'),
            const SizedBox(height: 10),
            _dialogRow('Kasir Baru', newName),
            Obx(() => _dialogRow(
                  'Saldo Awal',
                  CurrencyHelper.formatRupiah(
                    controller.useClosingAsOpening.value
                        ? controller.handoverClosingLive.value
                        : (double.tryParse(controller
                                    .handoverNewBalanceController.text
                                    .replaceAll(',', '')) ??
                                0.0),
                  ),
                )),
          ],
        ),
        actions: [
          TextButton(
              onPressed: Get.back, child: const Text('Batal')),
          ElevatedButton.icon(
            onPressed: () {
              Get.back();
              controller.gantiShift();
            },
            icon: const Icon(Icons.swap_horiz_rounded),
            label: const Text('Ganti Shift'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _card({String? label, String? title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 6,
              offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (label != null) ...[
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
            Text(value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      );

  Widget _dialogRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      );
}
