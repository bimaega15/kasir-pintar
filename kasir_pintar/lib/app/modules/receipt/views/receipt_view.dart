import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/models/transaction_model.dart';
import '../../../routes/app_routes.dart';
import '../../../services/printer_service.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/helpers/currency_helper.dart';

class ReceiptView extends StatefulWidget {
  const ReceiptView({super.key});

  @override
  State<ReceiptView> createState() => _ReceiptViewState();
}

class _ReceiptViewState extends State<ReceiptView> {
  final _screenshotController = ScreenshotController();
  bool _isSharing = false;

  Future<void> _shareReceipt(TransactionModel transaction) async {
    setState(() => _isSharing = true);
    try {
      final image = await _screenshotController.capture(pixelRatio: 2.0);
      if (image == null) return;
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/struk_${transaction.invoiceNumber.replaceAll('/', '_')}.png',
      );
      await file.writeAsBytes(image);
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Struk ${transaction.invoiceNumber} - ${CurrencyHelper.formatRupiah(transaction.total)}',
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal berbagi struk: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transaction = Get.arguments as TransactionModel;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Struk Pembayaran'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Get.offAllNamed(AppRoutes.home),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Success badge
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.cardShadow,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                            size: 44,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Pembayaran Berhasil!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyHelper.formatDateTime(transaction.createdAt),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Receipt card (wrapped for screenshot)
                  Screenshot(
                    controller: _screenshotController,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.cardShadow,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Header struk
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 20,
                            ),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(14),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  '🏪 KASIR PINTAR',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  transaction.invoiceNumber,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      transaction.orderType == 'take_away'
                                          ? Icons.takeout_dining_rounded
                                          : Icons.restaurant_rounded,
                                      color: Colors.white70,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      transaction.orderTypeLabel +
                                          (transaction.tableNumber != null
                                              ? ' · Meja ${transaction.tableNumber}'
                                              : ''),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Items
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                ...transaction.items.map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 5,
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          item.product.emoji,
                                          style: const TextStyle(fontSize: 18),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.product.name,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                '${item.quantity} x ${CurrencyHelper.formatRupiah(item.product.price)}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          CurrencyHelper.formatRupiah(
                                            item.subtotal,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Divider(height: 20),
                                _receiptRow(
                                  'Subtotal',
                                  CurrencyHelper.formatRupiah(
                                    transaction.subtotal,
                                  ),
                                ),
                                if (transaction.discount > 0)
                                  _receiptRow(
                                    'Diskon',
                                    '- ${CurrencyHelper.formatRupiah(transaction.discount)}',
                                    valueColor: AppColors.error,
                                  ),
                                if (transaction.taxAmount > 0)
                                  _receiptRow(
                                    'Pajak',
                                    CurrencyHelper.formatRupiah(
                                      transaction.taxAmount,
                                    ),
                                  ),
                                if (transaction.serviceChargeAmount > 0)
                                  _receiptRow(
                                    'Service Charge',
                                    CurrencyHelper.formatRupiah(
                                      transaction.serviceChargeAmount,
                                    ),
                                  ),
                                const Divider(height: 12),
                                _receiptRow(
                                  'TOTAL',
                                  CurrencyHelper.formatRupiah(
                                    transaction.total,
                                  ),
                                  isBold: true,
                                  valueColor: AppColors.primary,
                                  fontSize: 16,
                                ),
                                const SizedBox(height: 8),
                                _receiptRow(
                                  'Metode Bayar',
                                  transaction.paymentMethod,
                                ),
                                _receiptRow(
                                  'Dibayar',
                                  CurrencyHelper.formatRupiah(
                                    transaction.paymentAmount,
                                  ),
                                ),
                                if (transaction.change > 0)
                                  _receiptRow(
                                    'Kembalian',
                                    CurrencyHelper.formatRupiah(
                                      transaction.change,
                                    ),
                                    valueColor: AppColors.success,
                                    isBold: true,
                                  ),
                              ],
                            ),
                          ),

                          // Footer
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Terima kasih telah berbelanja!\nSilakan kunjungi kami kembali.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              children: [
                // Cetak Struk (Android only)
                if (Platform.isAndroid)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final printerService = Get.find<PrinterService>();
                          printerService.printReceipt(transaction);
                        },
                        icon: const Icon(Icons.print_rounded),
                        label: const Text('Cetak Struk'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                // Bagikan Struk (all platforms)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSharing
                          ? null
                          : () => _shareReceipt(transaction),
                      icon: _isSharing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.share_rounded),
                      label: Text(
                        _isSharing ? 'Menyiapkan...' : 'Bagikan Struk',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Get.offAllNamed(AppRoutes.home),
                        icon: const Icon(Icons.home_rounded),
                        label: const Text('Ke Beranda'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Get.offAllNamed(AppRoutes.home),
                        icon: const Icon(Icons.add_shopping_cart_rounded),
                        label: const Text('Pesanan Baru'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(
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
              color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
            ),
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
