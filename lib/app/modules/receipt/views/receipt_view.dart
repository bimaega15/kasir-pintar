import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/models/payment_entry_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/providers/storage_provider.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../routes/app_routes.dart';
import '../../../services/printer_service.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/helpers/currency_helper.dart';
import '../../main_navigation/controllers/main_navigation_controller.dart';

class ReceiptView extends StatefulWidget {
  const ReceiptView({super.key});

  @override
  State<ReceiptView> createState() => _ReceiptViewState();
}

class _ReceiptViewState extends State<ReceiptView> {
  final _screenshotController = ScreenshotController();
  bool _isSharing = false;
  late Future<List<PaymentEntry>> _paymentsFuture;
  late Future<Map<String, String>> _storeInfoFuture;
  final _txRepo = Get.find<TransactionRepository>();
  final _db = Get.find<DatabaseProvider>();

  @override
  void initState() {
    super.initState();
    final transaction = Get.arguments as TransactionModel;
    _paymentsFuture = _txRepo.getPayments(transaction.id);
    _storeInfoFuture = _loadStoreInfo();
  }

  Future<Map<String, String>> _loadStoreInfo() async {
    final name = await _db.getSetting('store_name') ?? 'Kasir Pintar';
    final address = await _db.getSetting('store_address') ?? '';
    final logo = await _db.getSetting('store_logo_path') ?? '';
    final footer = await _db.getSetting('store_footer') ?? '';
    return {'name': name, 'address': address, 'logo': logo, 'footer': footer};
  }

  String _buildReceiptText(
      TransactionModel transaction, Map<String, String> storeInfo) {
    final storeName = storeInfo['name'] ?? 'Kasir Pintar';
    final storeAddress = storeInfo['address'] ?? '';
    final sep = '─' * 32;
    final buf = StringBuffer();
    buf.writeln('🏪 ${storeName.toUpperCase()}');
    if (storeAddress.isNotEmpty) buf.writeln(storeAddress);
    buf.writeln(sep);
    buf.writeln(transaction.invoiceNumber);
    final orderLabel = transaction.orderType == 'take_away' ? 'Take Away' : 'Dine In';
    final tableLabel = transaction.tableNumber != null ? ' · Meja ${transaction.tableNumber}' : '';
    buf.writeln('$orderLabel$tableLabel');
    if (transaction.customerName.isNotEmpty) {
      buf.writeln('👤 ${transaction.customerName}');
    }
    buf.writeln(sep);
    for (final item in transaction.items) {
      buf.writeln('${item.product.emoji} ${item.product.name}');
      buf.writeln(
          '  ${item.quantity} x ${CurrencyHelper.formatRupiah(item.product.price)}  →  ${CurrencyHelper.formatRupiah(item.subtotal)}');
      if (item.product.isPackage && item.product.packageItems.isNotEmpty) {
        for (final pkg in item.product.packageItems) {
          buf.writeln('    ${pkg.productEmoji} ${pkg.productName}  ×${pkg.quantity}');
        }
      }
    }
    buf.writeln(sep);
    buf.writeln('Subtotal    : ${CurrencyHelper.formatRupiah(transaction.subtotal)}');
    if (transaction.discount > 0) {
      buf.writeln('Diskon      : - ${CurrencyHelper.formatRupiah(transaction.discount)}');
    }
    if (transaction.taxAmount > 0) {
      buf.writeln('Pajak       : ${CurrencyHelper.formatRupiah(transaction.taxAmount)}');
    }
    if (transaction.serviceChargeAmount > 0) {
      buf.writeln('Service     : ${CurrencyHelper.formatRupiah(transaction.serviceChargeAmount)}');
    }
    buf.writeln(sep);
    buf.writeln('TOTAL       : ${CurrencyHelper.formatRupiah(transaction.total)}');
    buf.writeln(sep);
    buf.writeln('Metode Bayar: ${transaction.paymentMethod}');
    buf.writeln('Dibayar     : ${CurrencyHelper.formatRupiah(transaction.paymentAmount)}');
    if (transaction.change > 0) {
      buf.writeln('Kembalian   : ${CurrencyHelper.formatRupiah(transaction.change)}');
    }
    buf.writeln(sep);
    buf.writeln('Terima kasih telah berbelanja! 🙏');
    final footer = storeInfo['footer'] ?? '';
    if (footer.isNotEmpty) {
      buf.writeln(sep);
      buf.writeln(footer);
    }
    return buf.toString();
  }

  Future<void> _shareReceipt(TransactionModel transaction) async {
    setState(() => _isSharing = true);
    try {
      final storeInfo = await _storeInfoFuture;
      final receiptText = _buildReceiptText(transaction, storeInfo);
      final image = await _screenshotController.capture(pixelRatio: 2.0);
      if (image != null) {
        final dir = await getTemporaryDirectory();
        final file = File(
          '${dir.path}/struk_${transaction.invoiceNumber.replaceAll('/', '_')}.png',
        );
        await file.writeAsBytes(image);
        await Share.shareXFiles(
          [XFile(file.path)],
          text: receiptText,
        );
      } else {
        await Share.share(receiptText);
      }
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
          _isSharing
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.share_rounded),
                  tooltip: 'Bagikan Struk',
                  onPressed: () => _shareReceipt(transaction),
                ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Get.offAllNamed(AppRoutes.main),
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
                  // Main receipt card with success header
                  Screenshot(
                    controller: _screenshotController,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                        children: [
                          // Success badge integrated at top
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.success.withValues(alpha: 0.08),
                                  AppColors.success.withValues(alpha: 0.04),
                                ],
                              ),
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.success.withValues(alpha: 0.1),
                                ),
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.success,
                                    size: 40,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Pembayaran Berhasil!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyHelper.formatDateTime(
                                      transaction.createdAt),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Header struk — nama toko, logo, alamat
                          FutureBuilder<Map<String, String>>(
                            future: _storeInfoFuture,
                            builder: (context, snap) {
                              final info = snap.data ?? {};
                              final storeName = info['name'] ?? 'Kasir Pintar';
                              final address = info['address'] ?? '';
                              final logoPath = info['logo'] ?? '';
                              final hasLogo = logoPath.isNotEmpty &&
                                  File(logoPath).existsSync();

                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 20),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                ),
                                child: Column(
                                  children: [
                                    // Logo
                                    if (hasLogo) ...[
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        child: Image.file(
                                          File(logoPath),
                                          height: 64,
                                          width: 64,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    // Nama toko
                                    Text(
                                      storeName.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        letterSpacing: 1,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    // Alamat
                                    if (address.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        address,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    // Invoice number
                                    Text(
                                      transaction.invoiceNumber,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Order type
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                    if (transaction.customerName.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '👤 ${transaction.customerName}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
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
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              item.product.emoji,
                                              style: const TextStyle(
                                                  fontSize: 18),
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
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${item.quantity} x ${CurrencyHelper.formatRupiah(item.product.price)}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors
                                                          .textSecondary,
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
                                        if (item.product.isPackage &&
                                            item.product.packageItems
                                                .isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 26, top: 4),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: item.product.packageItems
                                                  .map((pkg) => Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                bottom: 2),
                                                        child: Row(children: [
                                                          Text(pkg.productEmoji,
                                                              style:
                                                                  const TextStyle(
                                                                      fontSize:
                                                                          11)),
                                                          const SizedBox(
                                                              width: 4),
                                                          Text(
                                                            '${pkg.productName}  ×${pkg.quantity}',
                                                            style: TextStyle(
                                                                fontSize: 11,
                                                                color: Colors
                                                                    .grey
                                                                    .shade500),
                                                          ),
                                                        ]),
                                                      ))
                                                  .toList(),
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
                                // Split payment breakdown
                                FutureBuilder<List<PaymentEntry>>(
                                  future: _paymentsFuture,
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData ||
                                        snapshot.data!.isEmpty ||
                                        snapshot.data!.length <= 1) {
                                      return const SizedBox();
                                    }
                                    final payments = snapshot.data!;
                                    return Column(
                                      children: [
                                        const SizedBox(height: 8),
                                        const Divider(height: 12),
                                        const Padding(
                                          padding: EdgeInsets.only(top: 4),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              'Rincian Pembayaran',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                                color:
                                                    AppColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ),
                                        ...List.generate(
                                          payments.length,
                                          (i) => _receiptRow(
                                            '${payments[i].method} (${i + 1})',
                                            CurrencyHelper.formatRupiah(
                                              payments[i].amount,
                                            ),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          // Footer
                          FutureBuilder<Map<String, String>>(
                            future: _storeInfoFuture,
                            builder: (context, snap) {
                              final footer =
                                  snap.data?['footer'] ?? '';
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(
                                    12, 12, 12, 16),
                                decoration: const BoxDecoration(
                                  color: AppColors.background,
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Terima kasih telah berbelanja!\nSilakan kunjungi kami kembali.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (footer.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      const Divider(height: 1),
                                      const SizedBox(height: 8),
                                      Text(
                                        footer,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              children: [
                // Cetak Struk (Android only)
                if (Platform.isAndroid)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final printerService = Get.find<PrinterService>();
                          printerService.printReceipt(transaction);
                        },
                        icon: const Icon(Icons.print_rounded, size: 20),
                        label: const Text(
                          'Cetak Struk',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Get.offAllNamed(AppRoutes.main),
                        icon: const Icon(Icons.home_rounded, size: 20),
                        label: const Text(
                          'Beranda',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Get.offAllNamed(AppRoutes.main);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (Get.isRegistered<MainNavigationController>(
                                tag: MainNavigationController.TAG)) {
                              Get.find<MainNavigationController>(
                                      tag: MainNavigationController.TAG)
                                  .changeIndex(4);
                            }
                          });
                        },
                        icon: const Icon(Icons.point_of_sale_rounded, size: 20),
                        label: const Text(
                          'Menu Kasir',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.offAllNamed(AppRoutes.orderType);
                        },
                        icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
                        label: const Text(
                          'Pesanan Baru',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
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
