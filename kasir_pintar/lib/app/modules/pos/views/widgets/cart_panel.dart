import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/pos_controller.dart';
import '../../../../utils/constants/app_colors.dart';
import '../../../../utils/helpers/currency_helper.dart';
import 'payment_dialog.dart';

class CartPanel extends StatelessWidget {
  const CartPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<PosController>();
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: AppColors.primary,
            child: Row(
              children: [
                const Icon(Icons.shopping_cart_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Keranjang',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                const Spacer(),
                Obx(() => c.cart.isNotEmpty
                    ? GestureDetector(
                        onTap: c.clearCart,
                        child: const Text(
                          'Hapus Semua',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      )
                    : const SizedBox()),
              ],
            ),
          ),

          // Cart items
          Expanded(
            child: Obx(() => c.cart.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🛒',
                            style: TextStyle(fontSize: 48)),
                        SizedBox(height: 12),
                        Text(
                          'Keranjang kosong',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Pilih produk untuk ditambahkan',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: c.cart.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      final item = c.cart[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Text(item.product.emoji,
                                style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    CurrencyHelper.formatRupiah(item.product.price),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ),
                            // Qty controls
                            Row(
                              children: [
                                _qtyButton(
                                  icon: Icons.remove,
                                  onTap: () =>
                                      c.decreaseQty(item.product.id),
                                ),
                                Obx(() {
                                  final it = c.cart.firstWhereOrNull(
                                      (e) => e.product.id == item.product.id);
                                  return SizedBox(
                                    width: 28,
                                    child: Text(
                                      '${it?.quantity ?? 0}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                  );
                                }),
                                _qtyButton(
                                  icon: Icons.add,
                                  onTap: () =>
                                      c.increaseQty(item.product.id),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Obx(() {
                              final it = c.cart.firstWhereOrNull(
                                  (e) => e.product.id == item.product.id);
                              return Text(
                                CurrencyHelper.formatRupiah(it?.subtotal ?? 0),
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  )),
          ),

          // Summary & Payment
          Obx(() => c.cart.isNotEmpty
              ? _buildSummary(c)
              : const SizedBox()),
        ],
      ),
    );
  }

  Widget _qtyButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.divider),
        ),
        child: Icon(icon, size: 14, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildSummary(PosController c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        children: [
          // Discount
          Row(
            children: [
              const Text('Diskon',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: c.discountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: '0',
                    prefixText: 'Rp ',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onChanged: c.updateDiscount,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _summaryRow('Subtotal', CurrencyHelper.formatRupiah(c.subtotal)),
          if (c.discountAmount.value > 0)
            _summaryRow(
              'Diskon',
              '- ${CurrencyHelper.formatRupiah(c.discountAmount.value)}',
              color: AppColors.error,
            ),
          const Divider(height: 16),
          _summaryRow(
            'Total',
            CurrencyHelper.formatRupiah(c.total),
            isBold: true,
            color: AppColors.primary,
            fontSize: 16,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Get.dialog(const PaymentDialog()),
              icon: const Icon(Icons.payment_rounded),
              label: const Text('Bayar Sekarang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
    double fontSize = 13,
  }) {
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      color: color ?? AppColors.textPrimary,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: fontSize,
                  color: isBold ? color : AppColors.textSecondary)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
