import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/transaction_model.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/helpers/currency_helper.dart';

class TransactionDetailView extends StatelessWidget {
  const TransactionDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final transaction = Get.arguments as TransactionModel;
    return Scaffold(
      appBar: AppBar(title: Text(transaction.invoiceNumber)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(transaction),
            const SizedBox(height: 16),
            _buildItemsCard(transaction),
            const SizedBox(height: 16),
            _buildSummaryCard(transaction),
            const SizedBox(height: 16),
            _buildPaymentCard(transaction),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(TransactionModel t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.receipt_long_rounded,
              color: Colors.white70, size: 32),
          const SizedBox(height: 12),
          Text(
            t.invoiceNumber,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyHelper.formatDateTime(t.createdAt),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.person_outline,
                  color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Text(
                t.cashierName,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(TransactionModel t) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_bag_outlined,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Item (${t.totalItems} pcs)',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const Divider(height: 20),
            ...t.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Text(item.product.emoji,
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.product.name,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        '${item.quantity}x',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        CurrencyHelper.formatRupiah(item.subtotal),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(TransactionModel t) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rincian Harga',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            const Divider(height: 20),
            _row('Subtotal', CurrencyHelper.formatRupiah(t.subtotal)),
            if (t.discount > 0)
              _row('Diskon', '- ${CurrencyHelper.formatRupiah(t.discount)}',
                  valueColor: AppColors.error),
            const Divider(height: 16),
            _row('Total', CurrencyHelper.formatRupiah(t.total),
                isBold: true, valueColor: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(TransactionModel t) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Informasi Pembayaran',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            const Divider(height: 20),
            _row('Metode', t.paymentMethod),
            _row('Dibayar', CurrencyHelper.formatRupiah(t.paymentAmount)),
            if (t.change > 0)
              _row('Kembalian', CurrencyHelper.formatRupiah(t.change),
                  valueColor: AppColors.success),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          Text(value,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    isBold ? FontWeight.bold : FontWeight.w500,
                color: valueColor ?? AppColors.textPrimary,
              )),
        ],
      ),
    );
  }
}
