import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/history_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/helpers/currency_helper.dart';

class HistoryView extends GetView<HistoryController> {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
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
      body: Obx(() {
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
                      padding: const EdgeInsets.symmetric(vertical: 8),
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
    );
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

  Widget _buildTransactionTile(transaction) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      onTap: () =>
          Get.toNamed(AppRoutes.transactionDetail, arguments: transaction),
      leading: Container(
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
    );
  }
}
