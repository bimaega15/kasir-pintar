import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../order/controllers/order_controller.dart';
import '../../../../data/models/order_item_model.dart';
import '../../../../routes/app_routes.dart';
import '../../../../utils/constants/app_colors.dart';
import '../../../../utils/helpers/currency_helper.dart';

class CartPanel extends StatelessWidget {
  const CartPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<OrderController>();
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
                        Text('🛒', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 12),
                        Text(
                          'Keranjang kosong',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tekan produk untuk menambahkan',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: c.cart.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 12, endIndent: 12),
                    itemBuilder: (context, index) {
                      final item = c.cart[index];
                      return _CartItemRow(
                        key: ValueKey(item.productId),
                        item: item,
                        c: c,
                      );
                    },
                  )),
          ),

          // Summary & Action
          Obx(() => c.cart.isNotEmpty
              ? SafeArea(top: false, child: _buildSummary(c))
              : const SizedBox()),
        ],
      ),
    );
  }

  Widget _buildSummary(OrderController c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        children: [
          // Discount field
          Row(
            children: [
              const Text('Diskon',
                  style:
                      TextStyle(fontSize: 13, color: AppColors.textSecondary)),
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
          Obx(() => c.discount.value > 0
              ? _summaryRow(
                  'Diskon',
                  '- ${CurrencyHelper.formatRupiah(c.discount.value)}',
                  color: AppColors.error,
                )
              : const SizedBox()),
          Obx(() => c.taxPercent.value > 0
              ? _summaryRow(
                  'Pajak (${c.taxPercent.value.toStringAsFixed(0)}%)',
                  CurrencyHelper.formatRupiah(c.taxAmount),
                )
              : const SizedBox()),
          Obx(() => c.serviceChargePercent.value > 0
              ? _summaryRow(
                  'Service (${c.serviceChargePercent.value.toStringAsFixed(0)}%)',
                  CurrencyHelper.formatRupiah(c.serviceChargeAmount),
                )
              : const SizedBox()),
          const Divider(height: 16),
          Obx(() => _summaryRow(
                'Total',
                CurrencyHelper.formatRupiah(c.total),
                isBold: true,
                color: AppColors.primary,
                fontSize: 16,
              )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Get.toNamed(AppRoutes.orderConfirm),
              icon: const Icon(Icons.send_rounded),
              label: const Text('Konfirmasi Pesanan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: fontSize,
                  color: isBold ? color : AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Per-item row ──────────────────────────────────────────────────────────────

class _CartItemRow extends StatefulWidget {
  final OrderItemModel item;
  final OrderController c;

  const _CartItemRow({super.key, required this.item, required this.c});

  @override
  State<_CartItemRow> createState() => _CartItemRowState();
}

class _CartItemRowState extends State<_CartItemRow> {
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController(text: widget.item.note);
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final item = widget.item;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris 1: emoji · nama · qty controls
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(item.productEmoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.productName,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _qtyButton(
                icon: Icons.remove,
                onTap: () => c.decreaseQty(item.productId),
              ),
              Obx(() {
                final it = c.cart
                    .firstWhereOrNull((e) => e.productId == item.productId);
                return SizedBox(
                  width: 30,
                  child: Text(
                    '${it?.quantity ?? 0}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                );
              }),
              _qtyButton(
                icon: Icons.add,
                onTap: () => c.increaseQty(item.productId),
              ),
            ],
          ),

          // Baris isi paket (jika item adalah paket)
          if (item.isPackage && item.packageItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: item.packageItems.map((pkg) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Text(pkg.productEmoji,
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '${pkg.productName}  x${pkg.quantity}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),

          // Baris 2: harga satuan (kiri) · subtotal (kanan), sejajar dengan konten
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 3),
            child: Row(
              children: [
                Text(
                  CurrencyHelper.formatRupiah(item.productPrice),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const Spacer(),
                Obx(() {
                  final it = c.cart
                      .firstWhereOrNull((e) => e.productId == item.productId);
                  return Text(
                    CurrencyHelper.formatRupiah(it?.subtotal ?? 0),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                  );
                }),
              ],
            ),
          ),

          // Baris 3: field catatan opsional
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 6),
            child: TextField(
              controller: _noteCtrl,
              onChanged: (v) => c.setItemNote(item.productId, v),
              style: const TextStyle(fontSize: 11),
              maxLines: 1,
              decoration: InputDecoration(
                hintText: 'Catatan dapur (opsional)',
                hintStyle:
                    TextStyle(fontSize: 11, color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.edit_note_rounded,
                    size: 16, color: Colors.grey.shade400),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.2),
                ),
              ),
            ),
          ),
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
}
