import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/debt_model.dart';
import '../../../data/models/payment_entry_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/debt_repository.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/helpers/currency_helper.dart';
import '../../../utils/responsive/responsive_helper.dart';

class TransactionDetailView extends StatefulWidget {
  const TransactionDetailView({super.key});

  @override
  State<TransactionDetailView> createState() => _TransactionDetailViewState();
}

class _TransactionDetailViewState extends State<TransactionDetailView> {
  late TransactionModel transaction;
  late Future<List<PaymentEntry>> _paymentsFuture;
  late Future<DebtModel?> _debtFuture;
  final _txRepo = Get.find<TransactionRepository>();
  final _debtRepo = Get.find<DebtRepository>();

  @override
  void initState() {
    super.initState();
    transaction = Get.arguments as TransactionModel;
    _paymentsFuture = _txRepo.getPayments(transaction.id);
    _debtFuture = _debtRepo.getByInvoice(transaction.invoiceNumber);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(transaction.invoiceNumber)),
      body: SingleChildScrollView(
        padding: Res.padding(context),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                      if (item.product.isPackage &&
                          item.product.packageItems.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 30, top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: item.product.packageItems
                                .map((pkg) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 2),
                                      child: Row(children: [
                                        Text(pkg.productEmoji,
                                            style: const TextStyle(
                                                fontSize: 12)),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${pkg.productName}  ×${pkg.quantity}',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500),
                                        ),
                                      ]),
                                    ))
                                .toList(),
                          ),
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
    final isHutang = t.paymentMethod.contains('Hutang') ||
        t.paymentMethod.contains('DP');
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
            _row('Total Tagihan', CurrencyHelper.formatRupiah(t.total),
                isBold: true),
            _row('DP / Dibayar', CurrencyHelper.formatRupiah(t.paymentAmount)),
            if (t.change > 0)
              _row('Kembalian', CurrencyHelper.formatRupiah(t.change),
                  valueColor: AppColors.success),
            // Hutang detail block
            if (isHutang)
              FutureBuilder<DebtModel?>(
                future: _debtFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  final debt = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Status Hutang',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: debt.status == 'paid'
                                  ? Colors.green.shade100
                                  : debt.status == 'partial'
                                      ? Colors.orange.shade100
                                      : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              debt.statusLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: debt.status == 'paid'
                                    ? Colors.green.shade800
                                    : debt.status == 'partial'
                                        ? Colors.orange.shade800
                                        : Colors.red.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (debt.remainingAmount > 0) ...[
                        const SizedBox(height: 6),
                        _row(
                          'Sisa Hutang',
                          CurrencyHelper.formatRupiah(debt.remainingAmount),
                          valueColor: Colors.orange.shade700,
                          isBold: true,
                        ),
                      ],
                      if (debt.payments.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text('Riwayat Pembayaran Hutang',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        ...debt.payments.map((p) {
                              // Parse paid/kembalian from notes if present
                              // Notes format: "Dibayar: Rp X · Kembalian: Rp Y"
                              double? displayAmount;
                              double? kembalianAmount;
                              if (p.notes.contains('Dibayar:') &&
                                  p.notes.contains('Kembalian:')) {
                                final dibayarMatch = RegExp(
                                        r'Dibayar: Rp ([\d.]+)')
                                    .firstMatch(p.notes);
                                final kembalianMatch = RegExp(
                                        r'Kembalian: Rp ([\d.]+)')
                                    .firstMatch(p.notes);
                                if (dibayarMatch != null) {
                                  displayAmount = double.tryParse(
                                      dibayarMatch.group(1)!
                                          .replaceAll('.', ''));
                                }
                                if (kembalianMatch != null) {
                                  kembalianAmount = double.tryParse(
                                      kembalianMatch.group(1)!
                                          .replaceAll('.', ''));
                                }
                              }

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${p.method} · ${CurrencyHelper.formatDate(p.paidAt)}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary),
                                        ),
                                        Text(
                                          CurrencyHelper.formatRupiah(
                                              displayAmount ?? p.amount),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                    if (kembalianAmount != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Kembalian',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.green.shade700,
                                              ),
                                            ),
                                            Text(
                                              CurrencyHelper.formatRupiah(
                                                  kembalianAmount),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.green.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                      ],
                    ],
                  );
                },
              ),
            // Split payment breakdown
            FutureBuilder<List<PaymentEntry>>(
              future: _paymentsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox();
                }
                final payments = snapshot.data!;
                // Only show breakdown if more than one payment method
                if (payments.length <= 1) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Rincian Pembayaran',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      ...List.generate(
                        payments.length,
                        (i) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${payments[i].method} (${i + 1})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                CurrencyHelper.formatRupiah(payments[i].amount),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
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
