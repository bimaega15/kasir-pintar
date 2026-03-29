import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/debt_controller.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/helpers/currency_helper.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/responsive/responsive_helper.dart';

class DebtReportView extends GetView<DebtController> {
  const DebtReportView({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadReport();
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laporan Hutang & Piutang'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: controller.loadReport,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingReport.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final s = controller.reportStats.value;
        return SingleChildScrollView(
          padding: Res.padding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryHeader(s),
              const SizedBox(height: 16),
              _buildStatusCards(s),
              const SizedBox(height: 16),
              _buildAgingSection(s),
              const SizedBox(height: 16),
              _buildTopDebtors(s),
              const SizedBox(height: 16),
              _buildManageButton(),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  // ── Summary Header ────────────────────────────────────────────────────────

  Widget _buildSummaryHeader(DebtReportStats s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE53935), Color(0xFFEF5350)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text(
                'Total Sisa Hutang',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyHelper.formatRupiah(s.totalRemaining),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _headerChip('${s.unpaidCount + s.partialCount} belum lunas',
                  Colors.white24),
              const SizedBox(width: 8),
              _headerChip('${s.totalCount} total data', Colors.white24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerChip(String label, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 11)),
      );

  // ── Status Cards ──────────────────────────────────────────────────────────

  Widget _buildStatusCards(DebtReportStats s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Breakdown Status',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _statusCard('Belum Lunas', s.unpaidCount,
                    s.unpaidAmount, AppColors.error)),
            const SizedBox(width: 8),
            Expanded(
                child: _statusCard(
                    'Sebagian', s.partialCount, s.partialAmount, Colors.orange)),
            const SizedBox(width: 8),
            Expanded(
                child: _statusCard(
                    'Lunas', s.paidCount, s.paidAmount, AppColors.success)),
          ],
        ),
      ],
    );
  }

  Widget _statusCard(
      String label, int count, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: const [
          BoxShadow(
              color: AppColors.cardShadow, blurRadius: 6, offset: Offset(0, 2))
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
            child: Icon(Icons.circle_rounded, color: color, size: 14),
          ),
          const SizedBox(height: 8),
          Text('$count transaksi',
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(
            CurrencyHelper.formatRupiah(amount),
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  // ── Aging Analysis ────────────────────────────────────────────────────────

  Widget _buildAgingSection(DebtReportStats s) {
    final total =
        (s.age07 + s.age730 + s.ageOver30).clamp(1.0, double.infinity);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Analisis Umur Piutang',
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          const Text('Berdasarkan tanggal pencatatan hutang (belum lunas)',
              style:
                  TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          _agingRow(
            label: '< 7 hari',
            count: s.age07Count,
            amount: s.age07,
            ratio: s.age07 / total,
            color: AppColors.success,
          ),
          const SizedBox(height: 12),
          _agingRow(
            label: '7 – 30 hari',
            count: s.age730Count,
            amount: s.age730,
            ratio: s.age730 / total,
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _agingRow(
            label: '> 30 hari',
            count: s.ageOver30Count,
            amount: s.ageOver30,
            ratio: s.ageOver30 / total,
            color: AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _agingRow({
    required String label,
    required int count,
    required double amount,
    required double ratio,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(CurrencyHelper.formatRupiah(amount),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color)),
                Text('$count transaksi',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  // ── Top Debtors ───────────────────────────────────────────────────────────

  Widget _buildTopDebtors(DebtReportStats s) {
    if (s.topDebtors.isEmpty) return const SizedBox.shrink();
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hutang Terbesar',
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          const Text('Urut berdasarkan sisa hutang terbanyak',
              style:
                  TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          ...s.topDebtors.asMap().entries.map((e) {
            final i = e.key;
            final d = e.value;
            final name = (d['customer_name'] as String? ?? '').isNotEmpty
                ? d['customer_name'] as String
                : d['invoice_number'] as String;
            final remaining =
                (d['remaining_amount'] as num?)?.toDouble() ?? 0.0;
            final total =
                (d['total_amount'] as num?)?.toDouble() ?? 0.0;
            final status = d['status'] as String? ?? 'unpaid';
            final statusColor = status == 'partial' ? Colors.orange : AppColors.error;
            final paid = total - remaining;
            final payRatio = total > 0 ? paid / total : 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: statusColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: i < 3
                          ? [
                              const Color(0xFFFFD700),
                              const Color(0xFFC0C0C0),
                              const Color(0xFFCD7F32),
                            ][i].withValues(alpha: 0.2)
                          : AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: i < 3
                              ? [
                                  const Color(0xFFB8860B),
                                  const Color(0xFF808080),
                                  const Color(0xFF8B4513),
                                ][i]
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        const SizedBox(height: 3),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: payRatio.clamp(0.0, 1.0),
                            backgroundColor: AppColors.error.withValues(alpha: 0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.success),
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Lunas ${CurrencyHelper.formatRupiah(paid)} '
                          'dari ${CurrencyHelper.formatRupiah(total)}',
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyHelper.formatRupiah(remaining),
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: statusColor),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status == 'partial' ? 'Sebagian' : 'Belum Lunas',
                          style: TextStyle(
                              fontSize: 9,
                              color: statusColor,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Manage Button ─────────────────────────────────────────────────────────

  Widget _buildManageButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => Get.toNamed(AppRoutes.debtList),
        icon: const Icon(Icons.manage_search_rounded),
        label: const Text('Kelola Daftar Hutang'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
