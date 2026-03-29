import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/debt_model.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/helpers/currency_helper.dart';
import '../controllers/debt_controller.dart';
import '../../../utils/responsive/responsive_helper.dart';

class DebtListView extends GetView<DebtController> {
  const DebtListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daftar Hutang'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Obx(() => IconButton(
                tooltip: controller.showPaidDebts.value
                    ? 'Sembunyikan yang lunas'
                    : 'Tampilkan semua',
                icon: Icon(controller.showPaidDebts.value
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () {
                  controller.showPaidDebts.value =
                      !controller.showPaidDebts.value;
                  controller.loadDebts();
                },
              )),
        ],
      ),
      body: Column(
        children: [
          // Summary banner
          Obx(() => Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                color: AppColors.primary,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Piutang Belum Lunas',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyHelper.formatRupiah(
                              controller.totalOutstanding.value),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${controller.unpaidCount.value} belum lunas',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              )),

          // List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.debts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.account_balance_wallet_outlined,
                          size: 64,
                          color: AppColors.textSecondary
                              .withValues(alpha: 0.4)),
                      const SizedBox(height: 16),
                      Text(
                        controller.showPaidDebts.value
                            ? 'Belum ada catatan hutang'
                            : 'Semua hutang sudah lunas',
                        style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: controller.loadDebts,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.debts.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 12),
                  itemBuilder: (ctx, i) =>
                      _buildDebtCard(ctx, controller.debts[i]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtCard(BuildContext context, DebtModel debt) {
    final isPaid = debt.status == 'paid';
    final isPartial = debt.status == 'partial';
    final statusColor = isPaid
        ? AppColors.success
        : isPartial
            ? Colors.orange.shade600
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.customerName.isNotEmpty
                          ? debt.customerName
                          : '(Tanpa Nama)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      debt.invoiceNumber,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  debt.statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Amount rows
          _amountRow('Total Tagihan',
              CurrencyHelper.formatRupiah(debt.totalAmount)),
          if (debt.dpAmount > 0)
            _amountRow('DP Dibayar',
                CurrencyHelper.formatRupiah(debt.dpAmount),
                valueColor: AppColors.success),
          if (debt.payments.isNotEmpty)
            _amountRow(
              'Sudah Dibayar',
              CurrencyHelper.formatRupiah(
                  debt.payments.fold(0.0, (s, p) => s + p.amount)),
              valueColor: AppColors.success,
            ),
          _amountRow(
            'Sisa Hutang',
            CurrencyHelper.formatRupiah(debt.remainingAmount),
            valueColor: isPaid ? AppColors.success : AppColors.error,
            isBold: true,
          ),
          const SizedBox(height: 4),
          Text(
            _formatDate(debt.createdAt),
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary),
          ),

          // Payment history
          if (debt.payments.isNotEmpty) ...[
            const SizedBox(height: 10),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                'Riwayat Pembayaran (${debt.payments.length})',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              children: debt.payments
                  .map((p) => Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline,
                                size: 14, color: AppColors.success),
                            const SizedBox(width: 6),
                            Text(p.method,
                                style: const TextStyle(fontSize: 12)),
                            const Spacer(),
                            Text(
                              CurrencyHelper.formatRupiah(p.amount),
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(p.paidAt),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ],

          // Action buttons
          if (!isPaid) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDelete(context, debt),
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 16),
                    label: const Text('Hapus'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding:
                          const EdgeInsets.symmetric(vertical: 10),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => controller
                        .showRecordPaymentDialog(context, debt),
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: const Text('Bayar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 10),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _amountRow(String label, String value,
      {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  isBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmDelete(
      BuildContext context, DebtModel debt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Catatan Hutang?'),
        content: Text(
            'Hutang ${debt.invoiceNumber} akan dihapus permanen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm == true) await controller.deleteDebt(debt.id);
  }
}
