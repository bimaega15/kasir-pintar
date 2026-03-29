import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/shift_controller.dart';
import '../../../data/models/shift_model.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/helpers/currency_helper.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/responsive/responsive_helper.dart';

class ShiftReportView extends StatefulWidget {
  const ShiftReportView({super.key});

  @override
  State<ShiftReportView> createState() => _ShiftReportViewState();
}

class _ShiftReportViewState extends State<ShiftReportView> {
  final _ctrl = Get.find<ShiftController>();
  final _shifts = <ShiftModel>[].obs;
  final _isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _isLoading.value = true;
    try {
      final list = await _ctrl.getAllShifts();
      _shifts.assignAll(list);
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laporan Shift'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Obx(() {
        if (_isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_shifts.isEmpty) {
          return const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.history_rounded, size: 64, color: AppColors.textSecondary),
              SizedBox(height: 12),
              Text('Belum ada riwayat shift',
                  style: TextStyle(color: AppColors.textSecondary)),
            ]),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _shifts.length,
          itemBuilder: (_, i) => _buildShiftCard(_shifts[i]),
        );
      }),
    );
  }

  Widget _buildShiftCard(ShiftModel shift) {
    final isOpen = shift.isOpen;
    final diff = shift.difference;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isOpen
            ? Border.all(color: AppColors.success, width: 1.5)
            : null,
        boxShadow: const [
          BoxShadow(
              color: AppColors.cardShadow, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isOpen
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.textSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isOpen ? 'AKTIF' : 'SELESAI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isOpen ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                shift.cashierName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _row('Buka', CurrencyHelper.formatDateTime(shift.openedAt)),
          if (shift.closedAt != null)
            _row('Tutup', CurrencyHelper.formatDateTime(shift.closedAt!)),
          const Divider(height: 16),
          _row('Saldo Awal',
              CurrencyHelper.formatRupiah(shift.openingBalance)),
          if (shift.expectedCash != null)
            _row('Ekspektasi Kas',
                CurrencyHelper.formatRupiah(shift.expectedCash!)),
          if (shift.closingBalance != null)
            _row('Saldo Akhir',
                CurrencyHelper.formatRupiah(shift.closingBalance!)),
          if (diff != null) ...[
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Selisih',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  (diff >= 0 ? '+' : '') +
                      CurrencyHelper.formatRupiah(diff),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: diff >= 0 ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ],
          if (shift.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Catatan: ${shift.notes}',
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  Get.toNamed(AppRoutes.closingReport, arguments: shift),
              icon: const Icon(Icons.assessment_rounded, size: 16),
              label: const Text('Lihat Laporan Closing'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            Text(value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      );
}
