import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/payment_controller.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/helpers/currency_helper.dart';

class PaymentView extends GetView<PaymentController> {
  const PaymentView({super.key});

  @override
  Widget build(BuildContext context) {
    final order = controller.order;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pembayaran'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order summary card
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              order.orderType.name == 'dineIn'
                                  ? Icons.restaurant_rounded
                                  : Icons.takeout_dining_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              order.invoiceNumber,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            if (order.tableNumber != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                '· Meja ${order.tableNumber}',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        // Items
                        ...order.items.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(item.productEmoji),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(item.productName,
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.w500)),
                                            if (item.note.isNotEmpty)
                                              Text(item.note,
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppColors
                                                          .textSecondary,
                                                      fontStyle:
                                                          FontStyle.italic)),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${item.quantity}x',
                                        style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        CurrencyHelper.formatRupiah(
                                            item.subtotal),
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  if (item.isPackage &&
                                      item.packageItems.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 26, top: 3),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: item.packageItems
                                            .map((pkg) => Text(
                                                  '${pkg.productEmoji} ${pkg.productName}  ×${pkg.quantity}',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          Colors.grey.shade500),
                                                ))
                                            .toList(),
                                      ),
                                    ),
                                ],
                              ),
                            )),
                        const Divider(height: 16),
                        _summaryRow('Subtotal',
                            CurrencyHelper.formatRupiah(order.subtotal)),
                        if (order.discount > 0)
                          _summaryRow(
                            'Diskon',
                            '- ${CurrencyHelper.formatRupiah(order.discount)}',
                            valueColor: AppColors.error,
                          ),
                        if (order.taxAmount > 0)
                          _summaryRow(
                            'Pajak (${order.taxPercent.toStringAsFixed(0)}%)',
                            CurrencyHelper.formatRupiah(order.taxAmount),
                          ),
                        if (order.serviceChargeAmount > 0)
                          _summaryRow(
                            'Service (${order.serviceChargePercent.toStringAsFixed(0)}%)',
                            CurrencyHelper.formatRupiah(
                                order.serviceChargeAmount),
                          ),
                        const Divider(height: 12),
                        _summaryRow(
                          'TOTAL',
                          CurrencyHelper.formatRupiah(order.total),
                          isBold: true,
                          valueColor: AppColors.primary,
                          fontSize: 16,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Split bill progress or action buttons
                  Obx(() => controller.isSplitMode.value
                      ? _buildSplitProgress()
                      : Row(
                          children: [
                            const Text(
                              'Metode Pembayaran',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => _showHutangDialog(context),
                              icon: const Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 16),
                              label: const Text('Hutang/DP'),
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.orange.shade700),
                            ),
                            TextButton.icon(
                              onPressed: _showSplitCountDialog,
                              icon: const Icon(Icons.call_split_rounded,
                                  size: 16),
                              label: const Text('Bagi'),
                              style: TextButton.styleFrom(
                                  foregroundColor: AppColors.accent),
                            ),
                          ],
                        )),
                  // Add payment method button (non-split mode)
                  Obx(() => !controller.isSplitMode.value &&
                          controller.entries.length < 3
                      ? Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: controller.addEntry,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Tambah Metode'),
                            style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary),
                          ),
                        )
                      : const SizedBox()),
                  const SizedBox(height: 8),
                  Obx(() => Column(
                        children: List.generate(
                          controller.entries.length,
                          (i) => _buildPaymentEntry(i),
                        ),
                      )),

                  // Remaining / Change indicator
                  const SizedBox(height: 8),
                  Obx(() {
                    // Use split-aware calculations if in split mode
                    final isSplit = controller.isSplitMode.value;
                    final remaining = isSplit ? controller.splitRemaining : controller.remaining;
                    final change = isSplit ? controller.splitChange : controller.change;
                    final isPaid = isSplit ? controller.isSplitAmountPaid : controller.isPaid;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isPaid
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isPaid ? AppColors.success : AppColors.error,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isPaid
                                ? (change > 0 ? 'Kembalian' : 'Lunas')
                                : 'Kekurangan',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color:
                                  isPaid ? AppColors.success : AppColors.error,
                            ),
                          ),
                          Text(
                            isPaid
                                ? CurrencyHelper.formatRupiah(change)
                                : CurrencyHelper.formatRupiah(remaining),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color:
                                  isPaid ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Process button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Obx(() {
              final isProcessing = controller.isProcessing.value;
              final isSplit = controller.isSplitMode.value;
              final isPaid = isSplit
                  ? controller.isSplitAmountPaid
                  : controller.isPaid;
              final isHutang = !isPaid && !isSplit;

              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isProcessing
                      ? null
                      : isSplit
                          ? controller.processSplitPayment
                          : isHutang
                              ? () => _showCatatHutangDialog(context)
                              : controller.processPayment,
                  icon: isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Icon(isHutang
                          ? Icons.receipt_long_rounded
                          : Icons.check_circle_rounded),
                  label: Text(isProcessing
                      ? 'Memproses...'
                      : isHutang
                          ? 'Catat sebagai Hutang'
                          : 'Proses Pembayaran'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isHutang ? Colors.orange.shade600 : AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitProgress() {
    return Obx(() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.call_split_rounded,
                  color: AppColors.accent, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Bagian ${controller.splitIndex.value + 1} dari ${controller.splitCount.value}  ·  '
                  'Tagihan: ${CurrencyHelper.formatRupiah(controller.currentSplitAmount)}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent),
                ),
              ),
            ],
          ),
        ));
  }

  void _showCatatHutangDialog(BuildContext context) {
    final customerCtrl = TextEditingController(
        text: controller.order.customerName);
    final amountPaid = controller.totalPaid;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Catat sebagai Hutang'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('DP / Dibayar', style: TextStyle(fontSize: 13)),
                  Text(
                    CurrencyHelper.formatRupiah(amountPaid),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: customerCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama Pelanggan',
                prefixIcon: Icon(Icons.person_outline_rounded),
                hintText: 'Opsional',
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.processDebt(
                amountPaid: amountPaid,
                customerName: customerCtrl.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white),
            child: const Text('Konfirmasi Hutang'),
          ),
        ],
      ),
    );
  }

  void _showHutangDialog(BuildContext context) {
    final customerCtrl = TextEditingController(
        text: controller.order.customerName);
    final paidCtrl = TextEditingController();
    double amountPaid = 0;
    final total = controller.order.total;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final isOverpaid = amountPaid >= total;

          return AlertDialog(
            title: const Text('Hutang / Down Payment'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total tagihan
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Tagihan',
                            style: TextStyle(fontSize: 13)),
                        Text(
                          CurrencyHelper.formatRupiah(total),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: customerCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nama Pelanggan',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                      hintText: 'Opsional',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: paidCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah Dibayar Sekarang',
                      prefixText: 'Rp ',
                      hintText: '0  (kosongkan jika hutang penuh)',
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() {
                      amountPaid = double.tryParse(
                              v.replaceAll('.', '').trim()) ??
                          0;
                    }),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal')),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  controller.processDebt(
                    amountPaid: amountPaid,
                    customerName: customerCtrl.text.trim(),
                  );
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white),
                child: Text(isOverpaid ? 'Proses Pembayaran' : 'Konfirmasi Hutang'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSplitCountDialog() {
    int count = 2;
    Get.dialog(
      StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Bagi Tagihan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Jumlah orang yang membayar terpisah:'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      if (count > 2) setState(() => count--);
                    },
                  ),
                  Text('$count orang',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      if (count < 8) setState(() => count++);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '≈ ${CurrencyHelper.formatRupiah((controller.order.total / count).ceilToDouble())} / orang',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                Get.back();
                controller.enterSplitMode(count);
              },
              child: const Text('Mulai'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentEntry(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
              color: AppColors.cardShadow, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          // Method dropdown
          Obx(() => DropdownButton<String>(
                value: controller.entries[index].method,
                underline: const SizedBox(),
                items: controller.paymentMethods
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) controller.updateEntryMethod(index, v);
                },
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
              )),
          const SizedBox(width: 12),
          // Amount field
          Expanded(
            child: TextField(
              controller: controller.amountControllers[index],
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                hintText: '0',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onChanged: (v) => controller.updateEntryAmount(index, v),
            ),
          ),
          // Remove button (only if more than one entry)
          if (controller.entries.length > 1)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline,
                  color: AppColors.error, size: 20),
              onPressed: () => controller.removeEntry(index),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 6,
                offset: Offset(0, 2))
          ],
        ),
        child: child,
      );

  Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
    double fontSize = 13,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: fontSize,
                color: isBold ? AppColors.textPrimary : AppColors.textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
