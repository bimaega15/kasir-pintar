import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/shift_controller.dart';
import '../../../data/models/shift_model.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/helpers/currency_helper.dart';

class ClosingReportView extends GetView<ShiftController> {
  const ClosingReportView({super.key});

  @override
  Widget build(BuildContext context) {
    final shift = Get.arguments as ShiftModel;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadClosingReport(shift);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laporan Closing'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => controller.loadClosingReport(shift),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingReport.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShiftHeaderCard(shift),
              const SizedBox(height: 14),
              _buildCashReconciliation(shift),
              const SizedBox(height: 14),
              _buildTransactionSummary(),
              const SizedBox(height: 14),
              _buildPaymentBreakdown(),
              const SizedBox(height: 14),
              _buildTopProducts(),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  // ── Shift Header ──────────────────────────────────────────────────────────

  Widget _buildShiftHeaderCard(ShiftModel shift) {
    final duration = shift.closedAt != null
        ? shift.closedAt!.difference(shift.openedAt)
        : DateTime.now().difference(shift.openedAt);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.badge_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shift.cashierName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      shift.isOpen ? '🟢 Shift Aktif' : '🔴 Shift Selesai',
                      style: TextStyle(
                        fontSize: 12,
                        color: shift.isOpen
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${hours}j ${minutes}m',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 13),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          _row('Buka Shift', CurrencyHelper.formatDateTime(shift.openedAt)),
          if (shift.closedAt != null)
            _row('Tutup Shift',
                CurrencyHelper.formatDateTime(shift.closedAt!)),
        ],
      ),
    );
  }

  // ── Cash Reconciliation ───────────────────────────────────────────────────

  Widget _buildCashReconciliation(ShiftModel shift) {
    if (shift.isOpen) return const SizedBox.shrink();
    final diff = shift.difference ?? 0;
    final isPositive = diff >= 0;
    final diffColor = diff == 0
        ? AppColors.textSecondary
        : (isPositive ? AppColors.success : AppColors.error);

    return _card(
      title: '💰 Rekonsiliasi Kas',
      child: Column(
        children: [
          _row('Saldo Awal',
              CurrencyHelper.formatRupiah(shift.openingBalance)),
          if (shift.expectedCash != null) ...[
            _row(
              'Pendapatan Tunai',
              CurrencyHelper.formatRupiah(
                  (shift.expectedCash ?? 0) - shift.openingBalance),
              valueColor: AppColors.success,
            ),
            _row('Ekspektasi Kas',
                CurrencyHelper.formatRupiah(shift.expectedCash!),
                isBold: true),
          ],
          if (shift.closingBalance != null) ...[
            const Divider(height: 16),
            _row('Saldo Akhir Aktual',
                CurrencyHelper.formatRupiah(shift.closingBalance!),
                isBold: true),
            const Divider(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Selisih',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: diffColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${diff >= 0 ? '+' : ''}${CurrencyHelper.formatRupiah(diff)}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: diffColor,
                        fontSize: 14),
                  ),
                ),
              ],
            ),
            if (diff != 0) ...[
              const SizedBox(height: 4),
              Text(
                isPositive
                    ? '⬆️ Kas lebih dari ekspektasi'
                    : '⬇️ Kas kurang dari ekspektasi',
                style: TextStyle(
                    fontSize: 11,
                    color: diffColor,
                    fontStyle: FontStyle.italic),
              ),
            ],
          ],
          if (shift.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '📋 ${shift.notes}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Transaction Summary ───────────────────────────────────────────────────

  Widget _buildTransactionSummary() {
    final stats = controller.shiftStats.value;
    if (stats == null) return const SizedBox.shrink();

    return _card(
      title: '🧾 Ringkasan Transaksi',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _statBox(
                  label: 'Total Transaksi',
                  value: stats.txCount.toString(),
                  color: AppColors.primary,
                  icon: Icons.receipt_long_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statBox(
                  label: 'Total Omset',
                  value: CurrencyHelper.formatRupiah(stats.revenue),
                  color: AppColors.success,
                  icon: Icons.trending_up_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _row('Subtotal', CurrencyHelper.formatRupiah(stats.subtotal)),
          if (stats.discount > 0)
            _row('Diskon', '- ${CurrencyHelper.formatRupiah(stats.discount)}',
                valueColor: AppColors.error),
          if (stats.tax > 0)
            _row('Pajak', '+ ${CurrencyHelper.formatRupiah(stats.tax)}',
                valueColor: AppColors.accent),
          if (stats.serviceCharge > 0)
            _row('Service Charge',
                '+ ${CurrencyHelper.formatRupiah(stats.serviceCharge)}',
                valueColor: AppColors.accent),
          const Divider(height: 12),
          _row('Total Pendapatan', CurrencyHelper.formatRupiah(stats.revenue),
              isBold: true, valueColor: AppColors.success),
        ],
      ),
    );
  }

  // ── Payment Breakdown ─────────────────────────────────────────────────────

  Widget _buildPaymentBreakdown() {
    final stats = controller.shiftStats.value;
    if (stats == null || stats.payments.isEmpty) return const SizedBox.shrink();

    return _card(
      title: '💳 Breakdown Pembayaran',
      child: Column(
        children: stats.payments.map((p) {
          final pct = stats.revenue > 0
              ? (p.total / stats.revenue * 100).toStringAsFixed(1)
              : '0.0';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _paymentColor(p.method).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(_paymentIcon(p.method),
                          size: 16, color: _paymentColor(p.method)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.method,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          Text('${p.count} transaksi · $pct%',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyHelper.formatRupiah(p.total),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: stats.revenue > 0 ? p.total / stats.revenue : 0,
                    minHeight: 4,
                    backgroundColor:
                        _paymentColor(p.method).withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(
                        _paymentColor(p.method)),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Top Products ──────────────────────────────────────────────────────────

  Widget _buildTopProducts() {
    final stats = controller.shiftStats.value;
    if (stats == null || stats.products.isEmpty) return const SizedBox.shrink();

    return _card(
      title: '📦 Produk Terlaris',
      child: Column(
        children: stats.products.asMap().entries.map((e) {
          final idx = e.key;
          final p = e.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '#${idx + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: idx == 0
                          ? const Color(0xFFF57C00)
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                Text(p.emoji,
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(p.name,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${p.qty}x',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 13),
                    ),
                    Text(
                      CurrencyHelper.formatRupiah(p.total),
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _card({String? title, required Widget child}) {
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
            Text(title,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }

  Widget _row(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: isBold
                      ? AppColors.textPrimary
                      : AppColors.textSecondary)),
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

  Widget _statBox({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Color _paymentColor(String method) {
    switch (method) {
      case 'Tunai':
        return const Color(0xFF2E7D32);
      case 'Transfer Bank':
        return const Color(0xFF1565C0);
      case 'QRIS':
        return const Color(0xFF6A1B9A);
      case 'Kartu Debit':
      case 'Kartu Kredit':
        return const Color(0xFFF57C00);
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _paymentIcon(String method) {
    switch (method) {
      case 'Tunai':
        return Icons.payments_rounded;
      case 'Transfer Bank':
        return Icons.account_balance_rounded;
      case 'QRIS':
        return Icons.qr_code_rounded;
      case 'Kartu Debit':
      case 'Kartu Kredit':
        return Icons.credit_card_rounded;
      default:
        return Icons.payment_rounded;
    }
  }
}
