import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/report_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/constants/app_colors.dart';

class ReportPageContent extends StatelessWidget {
  const ReportPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laporan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Laporan & Riwayat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            // Riwayat Transaksi
            Obx(() {
              final ctrl = Get.find<ReportController>();
              return _buildReportCard(
                icon: Icons.history_rounded,
                title: 'Riwayat Transaksi',
                subtitle: 'Lihat semua transaksi, filter berdasarkan tanggal',
                color: AppColors.success,
                count: ctrl.totalTransactions.value.toString(),
                onTap: () {
                  ctrl.loadStats();
                  Get.toNamed(AppRoutes.history);
                },
              );
            }),
            const SizedBox(height: 16),
            // Log Batal
            Obx(() {
              final ctrl = Get.find<ReportController>();
              return _buildReportCard(
                icon: Icons.cancel_rounded,
                title: 'Log Transaksi Dibatalkan',
                subtitle: 'Lihat transaksi yang dibatalkan beserta alasannya',
                color: AppColors.error,
                count: ctrl.totalCancelled.value.toString(),
                onTap: () => Get.toNamed(AppRoutes.voidLog),
              );
            }),
            const SizedBox(height: 24),
            // Analytics Reports Section
            const Text(
              'Laporan Analitik',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            // Laporan Penjualan
            Obx(() {
              final ctrl = Get.find<ReportController>();
              return _buildReportCard(
                icon: Icons.shopping_cart_checkout_rounded,
                title: 'Laporan Penjualan',
                subtitle: 'Analisis detail produk terjual & metode pembayaran',
                color: AppColors.success,
                count: ctrl.totalItemsSold.value.toString(),
                onTap: () {
                  ctrl.loadStats();
                  Get.toNamed(AppRoutes.salesReport);
                },
              );
            }),
            const SizedBox(height: 16),
            // Laporan Omset
            Obx(() {
              final ctrl = Get.find<ReportController>();
              return _buildReportCard(
                icon: Icons.trending_up_rounded,
                title: 'Laporan Omset',
                subtitle: 'Total pendapatan, diskon, pajak & pendapatan bersih',
                color: AppColors.accent,
                count: ctrl.periodLabel,
                onTap: () {
                  ctrl.loadStats();
                  Get.toNamed(AppRoutes.revenueReport);
                },
              );
            }),
            const SizedBox(height: 16),
            // Laporan Laba Rugi
            Obx(() {
              final ctrl = Get.find<ReportController>();
              return _buildReportCard(
                icon: Icons.bar_chart_rounded,
                title: 'Laporan Laba Rugi',
                subtitle: 'Analisis keuntungan, biaya produksi & margin laba',
                color: AppColors.primary,
                count: ctrl.profitMargin.value.toStringAsFixed(1),
                onTap: () {
                  ctrl.loadStats();
                  Get.toNamed(AppRoutes.profitLossReport);
                },
              );
            }),
            const SizedBox(height: 16),
            // Laporan Performa Produk
            Obx(() {
              final ctrl = Get.find<ReportController>();
              return _buildReportCard(
                icon: Icons.trending_up_rounded,
                title: 'Laporan Performa Produk',
                subtitle: 'Ranking produk, kontribusi revenue & analisis stok',
                color: AppColors.primaryLight,
                count: ctrl.productPerformance.length.toString(),
                onTap: () {
                  ctrl.loadStats();
                  Get.toNamed(AppRoutes.productPerformanceReport);
                },
              );
            }),
            const SizedBox(height: 16),
            // Pengeluaran Operasional
            _buildReportCard(
              icon: Icons.money_off_rounded,
              title: 'Pengeluaran Operasional',
              subtitle: 'Catat & pantau biaya operasional bisnis',
              color: Colors.red,
              count: '',
              onTap: () => Get.toNamed(AppRoutes.expense),
            ),
            const SizedBox(height: 16),
            // Presensi Karyawan
            _buildReportCard(
              icon: Icons.badge_rounded,
              title: 'Presensi Karyawan',
              subtitle: 'Catat kehadiran & kelola data karyawan',
              color: Colors.teal,
              count: '',
              onTap: () => Get.toNamed(AppRoutes.attendance),
            ),
            const SizedBox(height: 16),
            // Laporan Hutang & Piutang
            _buildReportCard(
              icon: Icons.account_balance_wallet_rounded,
              title: 'Laporan Hutang & Piutang',
              subtitle: 'Analisis sisa hutang, aging piutang & debitur terbesar',
              color: Colors.red,
              count: '',
              onTap: () => Get.toNamed(AppRoutes.debtReport),
            ),
            const SizedBox(height: 24),
            // Stats Cards
            Obx(() {
              final ctrl = Get.find<ReportController>();
              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      label: 'Total Transaksi',
                      value: ctrl.totalTransactions.value.toString(),
                      icon: Icons.receipt_long_rounded,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      label: 'Dibatalkan',
                      value: ctrl.totalCancelled.value.toString(),
                      icon: Icons.cancel_rounded,
                      color: AppColors.error,
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 24),
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryLight.withValues(alpha: 0.1),
                    AppColors.primary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Analisis Bisnis',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Pantau riwayat transaksi dan identifikasi pola penjualan untuk meningkatkan bisnis Anda.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String count,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ],
          border: Border.all(
            color: color.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
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
            color: color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
