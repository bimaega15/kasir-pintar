import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/report_controller.dart';
import '../../../utils/constants/app_colors.dart';

class SalesReportView extends StatelessWidget {
  const SalesReportView({super.key});

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
        title: const Text('Laporan Penjualan'),
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

              // Summary Stats
              _buildSummaryStats(ctrl, currencyFmt),
              const SizedBox(height: 24),

              // Product Sales Section
              if (ctrl.productSales.isNotEmpty) ...[
                const Text(
                  'Penjualan Produk',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildProductSalesList(ctrl, currencyFmt),
                const SizedBox(height: 24),
              ],

              // Payment Method Breakdown
              if (ctrl.paymentMethodBreakdown.isNotEmpty) ...[
                const Text(
                  'Metode Pembayaran',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildPaymentMethodList(ctrl, currencyFmt),
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
        initialDateRange: ctrl.dateRange.value ??
            DateTimeRange(start: now, end: now),
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
                  label: 'Total Penjualan',
                  value: currencyFmt.format(ctrl.totalSalesAmount.value),
                  icon: Icons.trending_up_rounded,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox(
                  label: 'Total Item',
                  value: ctrl.totalItemsSold.value.toString(),
                  icon: Icons.shopping_cart_rounded,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  label: 'Rata-rata Transaksi',
                  value: currencyFmt.format(ctrl.avgTransactionValue.value),
                  icon: Icons.calculate_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox(
                  label: 'Total Transaksi',
                  value: ctrl.filteredTransactions.length.toString(),
                  icon: Icons.receipt_rounded,
                  color: AppColors.primaryLight,
                ),
              ),
            ],
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

  Widget _buildProductSalesList(
    ReportController ctrl,
    NumberFormat currencyFmt,
  ) {
    return Obx(() {
      if (ctrl.productSales.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              'Tidak ada data penjualan produk',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        );
      }

      return Column(
        children: List.generate(
          ctrl.productSales.length,
          (index) {
            final product = ctrl.productSales[index];
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
              child: Row(
                children: [
                  // Product emoji
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        product.productEmoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Product info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.productName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${product.quantity} item • ${currencyFmt.format(product.unitPrice)} per item',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFmt.format(product.totalAmount),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${(product.totalAmount / (ctrl.totalSalesAmount.value > 0 ? ctrl.totalSalesAmount.value : 1) * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildPaymentMethodList(
    ReportController ctrl,
    NumberFormat currencyFmt,
  ) {
    return Obx(() {
      if (ctrl.paymentMethodBreakdown.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              'Tidak ada data metode pembayaran',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        );
      }

      return Column(
        children: List.generate(
          ctrl.paymentMethodBreakdown.length,
          (index) {
            final method = ctrl.paymentMethodBreakdown[index];
            final percentage =
                (method.amount / (ctrl.totalSalesAmount.value > 0 ? ctrl.totalSalesAmount.value : 1)) *
                    100;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        method.method,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFmt.format(method.amount),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
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
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getColorByIndex(index),
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

  Color _getColorByIndex(int index) {
    final colors = [
      AppColors.success,
      AppColors.accent,
      AppColors.primary,
      AppColors.primaryLight,
      AppColors.warning,
      AppColors.error,
    ];
    return colors[index % colors.length];
  }
}
