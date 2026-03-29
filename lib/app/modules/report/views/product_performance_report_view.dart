import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/report_controller.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/responsive/responsive_helper.dart';

class ProductPerformanceReportView extends StatelessWidget {
  const ProductPerformanceReportView({super.key});

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
        title: const Text('Laporan Performa Produk'),
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

              // Performance Summary Stats
              _buildPerformanceSummary(ctrl, currencyFmt),
              const SizedBox(height: 24),

              // Top Performing Products
              if (ctrl.topPerformingProducts.isNotEmpty) ...[
                const Text(
                  '⭐ Produk Best Sellers',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildProductRankingList(ctrl, currencyFmt, ctrl.topPerformingProducts, isTop: true),
                const SizedBox(height: 24),
              ],

              // All Products Performance Table
              if (ctrl.productPerformance.isNotEmpty) ...[
                const Text(
                  'Semua Produk - Analisis Performa',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildProductPerformanceTable(ctrl, currencyFmt),
                const SizedBox(height: 24),
              ],

              // Low Performing Products
              if (ctrl.lowPerformingProducts.isNotEmpty) ...[
                const Text(
                  '⚠️ Produk Perlu Perhatian',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildProductRankingList(ctrl, currencyFmt, ctrl.lowPerformingProducts, isTop: false),
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
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
          )
        ],
      ),
      child: Obx(() {
        final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
        final startDate = ctrl.dateRange.value?.start;
        final endDate = ctrl.dateRange.value?.end;
        
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
            const SizedBox(height: 8),
            // Date Range Input Field
            GestureDetector(
              onTap: () => _showDateRangePicker(ctrl),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
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
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.primary.withValues(alpha: 0.6),
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Period Buttons
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
    final firstDate = DateTime(now.year - 1);
    final lastDate = now;

    try {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: firstDate,
        lastDate: lastDate,
        initialDateRange: ctrl.dateRange.value ?? DateTimeRange(start: now, end: now),
        locale: const Locale('id', 'ID'),
        confirmText: 'Terapkan',
        cancelText: 'Batal',
        fieldStartLabelText: 'Tanggal Mulai',
        fieldEndLabelText: 'Tanggal Akhir',
      );

      if (picked != null) {
        ctrl.setCustomRange(picked);
      }
    } catch (e) {
      debugPrint('Error showing date range picker: $e');
    }
  }

  Widget _buildPerformanceSummary(
    ReportController ctrl,
    NumberFormat currencyFmt,
  ) {
    return Obx(() {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricBox(
                  label: 'Total Produk Terjual',
                  value: ctrl.productPerformance.length.toString(),
                  icon: Icons.shopping_bag_rounded,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricBox(
                  label: 'Best Seller',
                  value: ctrl.topPerformingProducts.isNotEmpty
                      ? ctrl.topPerformingProducts.first.productName.substring(0, 15)
                      : '-',
                  icon: Icons.star_rounded,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricBox(
                  label: 'Total Penjualan',
                  value: currencyFmt.format(ctrl.totalSalesAmount.value),
                  icon: Icons.trending_up_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricBox(
                  label: 'Rata-rata per Produk',
                  value: currencyFmt.format(
                    ctrl.productPerformance.isEmpty
                        ? 0
                        : ctrl.totalSalesAmount.value /
                            ctrl.productPerformance.length,
                  ),
                  icon: Icons.calculate_rounded,
                  color: AppColors.primaryLight,
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildMetricBox({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
              fontSize: 13,
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

  Widget _buildProductRankingList(
    ReportController ctrl,
    NumberFormat currencyFmt,
    List products,
    {required bool isTop}
  ) {
    return Obx(() {
      if (products.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              'Tidak ada data',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        );
      }

      return Column(
        children: List.generate(
          products.length,
          (index) {
            final product = products[index];
            final rank = index + 1;
            Color rankColor = Colors.grey;

            if (rank == 1) rankColor = Colors.amber[700]!;
            if (rank == 2) rankColor = Colors.grey[400]!;
            if (rank == 3) rankColor = Colors.orange[700]!;

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
                children: [
                  Row(
                    children: [
                      // Rank Badge
                      CircleAvatar(
                        backgroundColor: rankColor,
                        radius: 20,
                        child: Text(
                          '#$rank',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Product Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  product.productEmoji,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    product.productName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${product.quantity} item • ${product.transactionCount} transaksi',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Revenue Info
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFmt.format(product.totalRevenue),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${product.revenuePct.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Stock Status
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _getStockStatusColor(product.currentStock)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getStockStatusIcon(product.currentStock),
                                size: 14,
                                color: _getStockStatusColor(product.currentStock),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Stok: ${product.currentStock}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: _getStockStatusColor(product.currentStock),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        product.performanceTier,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          backgroundColor:
                              _getPerformanceTierColor(product.performanceTier)
                                  .withValues(alpha: 0.2),
                          color: _getPerformanceTierColor(product.performanceTier),
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

  Widget _buildProductPerformanceTable(
    ReportController ctrl,
    NumberFormat currencyFmt,
  ) {
    return Obx(() {
      if (ctrl.productPerformance.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              'Tidak ada data produk',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        );
      }

      return Container(
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
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    flex: 2,
                    child: Text(
                      'Produk',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const Expanded(
                    flex: 1,
                    child: Text(
                      'Qty',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const Expanded(
                    flex: 2,
                    child: Text(
                      'Revenue',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    flex: 1,
                    child: Text(
                      '%',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Rows
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ctrl.productPerformance.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Colors.grey[200],
              ),
              itemBuilder: (context, index) {
                final product = ctrl.productPerformance[index];
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${product.productEmoji} ${product.productName}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tier: ${product.performanceTier}',
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          product.quantity.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          currencyFmt.format(product.totalRevenue),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${product.revenuePct.toStringAsFixed(1)}%',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      );
    });
  }

  Color _getStockStatusColor(int stock) {
    if (stock == 0) return AppColors.error;
    if (stock < 5) return AppColors.warning;
    return AppColors.success;
  }

  IconData _getStockStatusIcon(int stock) {
    if (stock == 0) return Icons.highlight_off_rounded;
    if (stock < 5) return Icons.warning_rounded;
    return Icons.check_circle_rounded;
  }

  Color _getPerformanceTierColor(String tier) {
    switch (tier) {
      case 'Star':
        return const Color(0xFFFFB800); // Gold
      case 'Core':
        return AppColors.primary;
      case 'Supporting':
        return AppColors.accent;
      default:
        return AppColors.textSecondary;
    }
  }
}
