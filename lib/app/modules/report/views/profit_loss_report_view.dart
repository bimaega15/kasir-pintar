import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/report_controller.dart';
import '../../../utils/constants/app_colors.dart';

class ProfitLossReportView extends StatelessWidget {
  const ProfitLossReportView({super.key});

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
        title: const Text('Laporan Laba Rugi'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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

              // P&L Summary
              _buildProfitLossSummary(ctrl, currencyFmt),
              const SizedBox(height: 24),

              // Detailed P&L Statement
              const Text(
                'Laporan Keuangan Detail',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildDetailedPLStatement(ctrl, currencyFmt),
              const SizedBox(height: 24),

              // Analysis Card
              _buildAnalysisCard(ctrl),
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
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
          )
        ],
      ),
      child: Obx(() {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Periode',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              ctrl.periodLabel,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _periodButton('Hari Ini', 'today', ctrl),
                  const SizedBox(width: 8),
                  _periodButton('Minggu', 'week', ctrl),
                  const SizedBox(width: 8),
                  _periodButton('Bulan', 'month', ctrl),
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

  Widget _buildProfitLossSummary(
    ReportController ctrl,
    NumberFormat currencyFmt,
  ) {
    return Obx(() {
      final isProfitable = ctrl.grossProfit.value >= 0;

      return Column(
        children: [
          // Revenue Box
          _buildSectionBox(
            title: 'Pendapatan',
            amount: ctrl.totalRevenue.value,
            icon: Icons.trending_up_rounded,
            color: AppColors.success,
            currencyFmt: currencyFmt,
          ),
          const SizedBox(height: 12),

          // COGS Box
          _buildSectionBox(
            title: 'Biaya Produksi (COGS)',
            amount: ctrl.totalCOGS.value,
            icon: Icons.shopping_bag_rounded,
            color: AppColors.warning,
            currencyFmt: currencyFmt,
            isNegative: true,
          ),
          const SizedBox(height: 12),

          // Gross Profit Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isProfitable
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.error.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isProfitable ? AppColors.success : AppColors.error)
                      .withValues(alpha: 0.1),
                  blurRadius: 8,
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isProfitable
                                ? AppColors.success
                                : AppColors.error)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isProfitable
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: isProfitable
                            ? AppColors.success
                            : AppColors.error,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Laba Kotor',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  currencyFmt.format(ctrl.grossProfit.value),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isProfitable
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Margin Laba',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${ctrl.profitMargin.value.toStringAsFixed(2)}%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSectionBox({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required NumberFormat currencyFmt,
    bool isNegative = false,
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isNegative
                      ? '- ${currencyFmt.format(amount)}'
                      : currencyFmt.format(amount),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedPLStatement(
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
            // Pendapatan
            _buildStatementRow(
              label: 'Pendapatan Penjualan',
              value: currencyFmt.format(ctrl.totalRevenue.value),
              isBold: true,
              color: AppColors.success,
            ),
            Divider(height: 24),

            // Beban
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Beban Operasional:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatementRow(
                    label: '  Biaya Bahan Baku (COGS)',
                    value: currencyFmt.format(ctrl.totalCOGS.value),
                    isIndented: true,
                    color: AppColors.warning,
                  ),
                  const SizedBox(height: 10),
                  _buildStatementRow(
                    label: '  - Diskon Diberikan',
                    value: currencyFmt.format(ctrl.totalDiscount.value),
                    isIndented: true,
                    color: AppColors.warning,
                  ),
                ],
              ),
            ),
            Divider(height: 24),

            // Laba Kotor
            _buildStatementRow(
              label: 'Laba Kotor',
              value: currencyFmt.format(ctrl.grossProfit.value),
              isBold: true,
              color: ctrl.grossProfit.value >= 0
                  ? AppColors.success
                  : AppColors.error,
            ),
            const SizedBox(height: 16),

            // Margin Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Profit Margin Kotor',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${ctrl.profitMargin.value.toStringAsFixed(2)}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatementRow({
    required String label,
    required String value,
    bool isBold = false,
    bool isIndented = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 13 : 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 13 : 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisCard(ReportController ctrl) {
    return Obx(() {
      final profitMargin = ctrl.profitMargin.value;
      String analysis;
      Color analysisColor;

      if (profitMargin >= 30) {
        analysis = 'Margin laba sangat sehat ✓';
        analysisColor = AppColors.success;
      } else if (profitMargin >= 20) {
        analysis = 'Margin laba baik';
        analysisColor = AppColors.accent;
      } else if (profitMargin >= 10) {
        analysis = 'Margin laba cukup';
        analysisColor = AppColors.primary;
      } else if (profitMargin >= 0) {
        analysis = 'Margin laba rendah - pertimbangkan optimisasi';
        analysisColor = AppColors.warning;
      } else {
        analysis = 'Rugi - segera tinjau biaya operasional';
        analysisColor = AppColors.error;
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: analysisColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: analysisColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: analysisColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.insights_rounded,
                color: analysisColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Analisis',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    analysis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: analysisColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
