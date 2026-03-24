import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/history_controller.dart';
import '../../../data/models/transaction_model.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/helpers/currency_helper.dart';

class HistoryView extends GetView<HistoryController> {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.isMergeMode.value
            ? 'Pilih Transaksi (${controller.selectedForMerge.length})'
            : 'Riwayat Transaksi')),
        actions: [
          Obx(() => controller.isMergeMode.value
              ? TextButton(
                  onPressed: controller.toggleMergeMode,
                  child: const Text('Batal',
                      style: TextStyle(color: Colors.white)),
                )
              : IconButton(
                  icon: const Icon(Icons.merge_rounded),
                  tooltip: 'Gabung Bill',
                  onPressed: controller.toggleMergeMode,
                )),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              controller: controller.searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cari no. invoice...',
                hintStyle: const TextStyle(color: Colors.white60),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white70),
                suffixIcon: Obx(() =>
                    controller.searchQuery.value.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: Colors.white70),
                            onPressed: controller.searchController.clear,
                          )
                        : const SizedBox()),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
        Obx(() {
        final list = controller.filteredTransactions;

        return Column(
          children: [
            // Summary bar
            if (controller.transactions.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.white,
                child: Row(
                  children: [
                    _summaryChip(
                      '${controller.transactions.length} Transaksi',
                      Icons.receipt_long_rounded,
                      AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    _summaryChip(
                      CurrencyHelper.formatRupiah(controller.totalRevenue),
                      Icons.attach_money_rounded,
                      AppColors.success,
                    ),
                  ],
                ),
              ),

            // List
            Expanded(
              child: list.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('📋',
                              style: TextStyle(fontSize: 52)),
                          SizedBox(height: 12),
                          Text('Belum ada transaksi',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(top: 8, bottom: 100),
                      itemCount: list.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (context, i) =>
                          _buildTransactionTile(list[i]),
                    ),
            ),
          ],
        );
      }),

      // ── Merge Bill confirm bar ────────────────────────────────────────────
      Obx(() {
        if (!controller.isMergeMode.value) return const SizedBox.shrink();
        final n = controller.selectedForMerge.length;
        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (n >= 2)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$n transaksi dipilih',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary)),
                          Obx(() => Text(
                                CurrencyHelper.formatRupiah(
                                    controller.mergeTotal),
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary),
                              )),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          n >= 2 ? controller.mergeSelectedBills : null,
                      icon: const Icon(Icons.merge_rounded, size: 18),
                      label: Text(n < 2
                          ? 'Pilih minimal 2 transaksi'
                          : 'Gabung $n Bill'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.primary.withValues(alpha: 0.4),
                        disabledForegroundColor: Colors.white70,
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
      ],
    ),    // Stack
  );      // Scaffold
  }

  Widget _summaryChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showVoidDialog(BuildContext context, TransactionModel tx) {
    const reasons = [
      'Salah input item',
      'Pelanggan batal',
      'Barang habis',
      'Lainnya',
    ];
    String selected = reasons.first;
    final otherCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Batalkan Transaksi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tx.invoiceNumber,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              Text(
                CurrencyHelper.formatRupiah(tx.total),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              const Text('Alasan pembatalan:',
                  style: TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selected,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(),
                ),
                items: reasons
                    .map((r) =>
                        DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => selected = v!),
              ),
              if (selected == 'Lainnya') ...[
                const SizedBox(height: 10),
                TextField(
                  controller: otherCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Tulis alasan...',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Tutup'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final reason = selected == 'Lainnya'
                    ? otherCtrl.text.trim()
                    : selected;
                if (reason.isEmpty) return;
                Navigator.of(ctx).pop();
                controller.voidTransaction(tx, reason);
              },
              child: const Text('Batalkan'),
            ),
          ],
        ),
      ),
    ).then((_) => otherCtrl.dispose());
  }

  Widget _buildTransactionTile(TransactionModel transaction) {
    return Obx(() {
      final mergeMode = controller.isMergeMode.value;
      final isSelected =
          controller.selectedForMerge.contains(transaction.id);
      return GestureDetector(
        onLongPress: mergeMode
            ? null
            : () => _showVoidDialog(Get.context!, transaction),
        onTap: mergeMode
            ? () => controller.toggleMergeSelection(transaction.id)
            : () => Get.toNamed(AppRoutes.transactionDetail,
                arguments: transaction),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.06)
              : Colors.transparent,
          child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: mergeMode
              ? AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSelected
                        ? Icons.check_rounded
                        : Icons.receipt_rounded,
                    color: isSelected
                        ? Colors.white
                        : AppColors.primary,
                    size: 24,
                  ),
                )
              : Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_rounded,
                      color: AppColors.primary, size: 24),
                ),
      title: Text(
        transaction.invoiceNumber,
        style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        '${CurrencyHelper.formatDateTime(transaction.createdAt)}  •  ${transaction.totalItems} item',
        style: const TextStyle(
            fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            CurrencyHelper.formatRupiah(transaction.total),
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              transaction.paymentMethod,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.success,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
          ),  // ListTile
        ),    // AnimatedContainer
      );      // GestureDetector
    });       // Obx
  }
}
