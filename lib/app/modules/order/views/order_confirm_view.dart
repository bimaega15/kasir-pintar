import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/helpers/currency_helper.dart';
import '../controllers/order_controller.dart';

class OrderConfirmView extends GetView<OrderController> {
  const OrderConfirmView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Konfirmasi Pesanan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Obx(
        () => Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Order info
                    _infoCard(),
                    const SizedBox(height: 12),
                    // Items
                    _itemsCard(),
                    const SizedBox(height: 12),
                    // Discount input
                    _discountCard(),
                    const SizedBox(height: 12),
                    // Summary
                    _summaryCard(),
                  ],
                ),
              ),
            ),
            _bottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  controller.orderType.value.name == 'dineIn'
                      ? Icons.restaurant_rounded
                      : Icons.takeout_dining_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.orderType.value.name == 'dineIn'
                          ? 'Dine In'
                          : 'Take Away',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (controller.selectedTable.value != null)
                      Text(
                        'Meja ${controller.selectedTable.value!.number} · ${controller.guestCount.value} Tamu',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Customer name (free text)
          Row(
            children: [
              const Icon(
                Icons.person_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nama Pemesan',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      controller.customerName.value.isEmpty
                          ? '(Belum diisi)'
                          : controller.customerName.value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: controller.customerName.value.isEmpty
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          // Linked customer from customer database
          GestureDetector(
            onTap: () => controller.showCustomerPicker(Get.context!),
            child: Row(
              children: [
                const Icon(
                  Icons.people_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih Pelanggan',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        controller.selectedCustomerName.value.isEmpty
                            ? 'Ketuk untuk memilih pelanggan'
                            : controller.selectedCustomerName.value,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: controller.selectedCustomerName.value.isEmpty
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  controller.selectedCustomerName.value.isEmpty
                      ? Icons.chevron_right_rounded
                      : Icons.check_circle_rounded,
                  size: 18,
                  color: controller.selectedCustomerName.value.isEmpty
                      ? AppColors.textSecondary
                      : Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Daftar Pesanan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const Spacer(),
              Text(
                '${controller.totalItems} item',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          ...controller.cart.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Text(item.productEmoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (item.note.isNotEmpty)
                          Text(
                            '📝 ${item.note}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${item.quantity}x',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        CurrencyHelper.formatRupiah(item.subtotal),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _discountCard() {
    return Obx(() {
      final sub = controller.subtotal;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Diskon',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Spacer(),
                // Mode toggle
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'Rp', label: Text('Rp')),
                    ButtonSegment(value: '%', label: Text('%')),
                  ],
                  selected: {controller.discountMode.value},
                  onSelectionChanged: (s) {
                    controller.discountMode.value = s.first;
                    controller.discountController.clear();
                    controller.discount.value = 0;
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    textStyle: WidgetStateProperty.all(
                        const TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Quick percent buttons
            if (controller.discountMode.value == '%')
              Row(
                children: [10.0, 15.0, 20.0].map((pct) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: OutlinedButton(
                      onPressed: () => controller.applyPercentDiscount(pct),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        side:
                            const BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text('${pct.toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 12)),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.discountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '0',
                prefixText:
                    controller.discountMode.value == 'Rp' ? 'Rp ' : null,
                suffixText:
                    controller.discountMode.value == '%' ? '%' : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                errorText: controller.discount.value > sub
                    ? 'Diskon melebihi subtotal'
                    : null,
              ),
              onChanged: controller.updateDiscountFromInput,
            ),
            if (controller.discount.value > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '- ${CurrencyHelper.formatRupiah(controller.discount.value)}',
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _row('Subtotal', CurrencyHelper.formatRupiah(controller.subtotal)),
          if (controller.discount.value > 0)
            _row(
              'Diskon',
              '- ${CurrencyHelper.formatRupiah(controller.discount.value)}',
              valueColor: AppColors.error,
            ),
          if (controller.taxPercent.value > 0)
            _row(
              'Pajak (${controller.taxPercent.value.toStringAsFixed(0)}%)',
              CurrencyHelper.formatRupiah(controller.taxAmount),
            ),
          if (controller.serviceChargePercent.value > 0)
            _row(
              'Service Charge (${controller.serviceChargePercent.value.toStringAsFixed(0)}%)',
              CurrencyHelper.formatRupiah(controller.serviceChargeAmount),
            ),
          const Divider(height: 16),
          _row(
            'Total',
            CurrencyHelper.formatRupiah(controller.total),
            isBold: true,
            valueColor: AppColors.primary,
            fontSize: 16,
          ),
        ],
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
    double fontSize = 13,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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

  Widget _bottomButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: controller.isCartEmpty ? null : controller.sendToKitchen,
              icon: const Icon(Icons.send_rounded),
              label: const Text('Kirim ke Dapur'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: Get.back,
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Edit Pesanan'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.isCartEmpty ? null : controller.parkOrder,
                  icon: const Icon(Icons.pause_circle_outline_rounded),
                  label: const Text('Tunda'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.amber),
                    foregroundColor: Colors.amber.shade700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    boxShadow: const [
      BoxShadow(
        color: AppColors.cardShadow,
        blurRadius: 6,
        offset: Offset(0, 2),
      ),
    ],
  );
}
