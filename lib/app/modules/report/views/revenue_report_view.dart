import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/report_controller.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/responsive/responsive_helper.dart';

class RevenueReportView extends StatelessWidget {
  const RevenueReportView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ReportController>();
    final currencyFmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laporan Omset'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: Res.padding(context),
        child: Obx(() {
          if (ctrl.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period Selector
              _buildPeriodSelector(ctrl),
              const SizedBox(height: 24),

              // Summary Stats
              _buildSummaryStats(ctrl, currencyFmt),
              const SizedBox(height: 24),

              // Revenue Breakdown
              const Text(
                'Rincian Pendapatan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildRevenueBreakdown(ctrl, currencyFmt),
              const SizedBox(height: 24),

              // Daily Revenue Chart
              if (ctrl.dailyRevenue.isNotEmpty) ...[
                const Text(
                  'Pendapatan Harian',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDailyRevenueList(ctrl, currencyFmt),
              ],
            ],
          );
        }),
      ),
    );
  }

  Widget _buildPeriodSelector(ReportController ctrl) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 8)
        ],
      ),
      child: Obx(() {
        final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
        final startDate = ctrl.dateRange.value?.start;
        final endDate = ctrl.dateRange.value?.end;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Periode',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(ctrl.periodLabel,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _showDateRangePicker(ctrl),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        startDate != null && endDate != null
                            ? '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}'
                            : 'Pilih Tanggal Mulai dan Akhir',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: startDate != null && endDate != null
                                ? AppColors.textPrimary
                                : AppColors.textSecondary),
                      ),
                    ),
                    Icon(Icons.arrow_drop_down,
                        color: AppColors.primary.withValues(alpha: 0.6),
                        size: 24),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _periodButton('Hari Ini', 'today', ctrl),
                  const SizedBox(width: 8),
                  _periodButton('Minggu', 'week', ctrl),
                  const SizedBox(width: 8),
                  _periodButton('Bulan', 'month', ctrl),
                  const SizedBox(width: 8),
                  _customDateRangeButton(ctrl),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _periodButton(String label, String period, ReportController ctrl) {
    return Obx(() {
      final isSelected = ctrl.selectedPeriod.value == period;
      return ElevatedButton(
        onPressed: () => ctrl.setPeriod(period),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.primary : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : AppColors.textPrimary,
        ),
        child: Text(label),
      );
    });
  }

  Widget _customDateRangeButton(ReportController ctrl) {
    return Obx(() {
      final isSelected = ctrl.selectedPeriod.value == 'custom';
      return ElevatedButton.icon(
        onPressed: () => _showDateRangePicker(ctrl),
        icon: const Icon(Icons.calendar_today, size: 16),
        label: const Text('Kustom'),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.primary : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : AppColors.textPrimary,
        ),
      );
    });
  }

  void _showDateRangePicker(ReportController ctrl) async {
    final context = Get.context;
    if (context == null) return;
    final now = DateTime.now();
    try {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(now.year - 1),
        lastDate: now,
        initialDateRange:
            ctrl.dateRange.value ?? DateTimeRange(start: now, end: now),
        locale: const Locale('id', 'ID'),
        confirmText: 'Terapkan',
        cancelText: 'Batal',
        fieldStartLabelText: 'Tanggal Mulai',
        fieldEndLabelText: 'Tanggal Akhir',
      );
      if (picked != null) ctrl.setCustomRange(picked);
    } catch (e) {
      debugPrint('Error showing date range picker: $e');
    }
  }

  Widget _buildSummaryStats(
    ReportController ctrl,
    NumberFormat currencyFmt,
  ) {
    return Obx(() {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  label: 'Total Omset',
                  value: currencyFmt.format(ctrl.totalRevenue.value),
                  icon: Icons.trending_up_rounded,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox(
                  label: 'Total Diskon',
                  value: currencyFmt.format(ctrl.totalDiscount.value),
                  icon: Icons.local_offer_rounded,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  label: 'Total Pajak',
                  value: currencyFmt.format(ctrl.totalTax.value),
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox(
                  label: 'Service Charge',
                  value: currencyFmt.format(ctrl.totalServiceCharge.value),
                  icon: Icons.local_dining_rounded,
                  color: AppColors.primaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.1),
                  blurRadius: 8,
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  currencyFmt.format(ctrl.netRevenue.value),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pendapatan Bersih',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildStatBox({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueBreakdown(
    ReportController ctrl,
    NumberFormat currencyFmt,
  ) {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8,
            )
          ],
        ),
        child: Column(
          children: [
            _buildBreakdownItem(
              label: 'Total Pendapatan',
              value: currencyFmt.format(ctrl.totalRevenue.value),
              color: AppColors.success,
            ),
            Divider(height: 24),
            _buildBreakdownItem(
              label: 'Dikurangi: Diskon',
              value: '- ${currencyFmt.format(ctrl.totalDiscount.value)}',
              color: AppColors.warning,
            ),
            const SizedBox(height: 16),
            Divider(height: 24),
            _buildBreakdownItem(
              label: 'Pendapatan Bersih',
              value: currencyFmt.format(ctrl.netRevenue.value),
              color: AppColors.success,
              isBold: true,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBreakdownItem({
    required String label,
    required String value,
    required Color color,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyRevenueList(
    ReportController ctrl,
    NumberFormat currencyFmt,
  ) {
    return Obx(() {
      if (ctrl.dailyRevenue.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              'Tidak ada data pendapatan harian',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        );
      }

      final dateFmt = DateFormat('d MMM', 'id_ID');

      return Column(
        children: List.generate(
          ctrl.dailyRevenue.length,
          (index) {
            final daily = ctrl.dailyRevenue[index];
            final maxRevenue = ctrl.dailyRevenue
                .fold<double>(0, (max, item) => item.amount > max ? item.amount : max);
            final percentage = maxRevenue > 0 ? (daily.amount / maxRevenue) * 100 : 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateFmt.format(daily.date),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFmt.format(daily.amount),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                          Text(
                            '${daily.transactionCount} transaksi',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 6,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }
}
