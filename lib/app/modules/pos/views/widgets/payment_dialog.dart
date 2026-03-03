import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/pos_controller.dart';
import '../../../../utils/constants/app_colors.dart';
import '../../../../utils/helpers/currency_helper.dart';

class PaymentDialog extends StatelessWidget {
  const PaymentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<PosController>();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  const Icon(Icons.payment_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  const Text(
                    'Pembayaran',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: Get.back,
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                ],
              ),
              const Divider(height: 20),

              // Total
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text('Total Tagihan',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 6),
                    Obx(() => Text(
                          CurrencyHelper.formatRupiah(c.total),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Payment method
              const Text('Metode Pembayaran',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Obx(() => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: c.paymentMethods.map((method) {
                      final selected = c.paymentMethod.value == method;
                      return GestureDetector(
                        onTap: () => c.paymentMethod.value = method,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.divider,
                            ),
                          ),
                          child: Text(
                            method,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  )),
              const SizedBox(height: 16),

              // Cash input (only for Tunai)
              Obx(() => c.paymentMethod.value == 'Tunai'
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Uang Diterima',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: c.cashController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            prefixText: 'Rp ',
                            hintText: '0',
                            suffixIcon:
                                Icon(Icons.edit, color: AppColors.textSecondary),
                          ),
                          onChanged: c.updateCashAmount,
                        ),
                        const SizedBox(height: 10),
                        // Quick cash buttons
                        Obx(() {
                          final total = c.total;
                          final amounts = _quickAmounts(total);
                          return Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: amounts
                                .map((amt) => GestureDetector(
                                      onTap: () {
                                        c.cashController.text =
                                            amt.toStringAsFixed(0);
                                        c.updateCashAmount(c.cashController.text);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.background,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: AppColors.divider),
                                        ),
                                        child: Text(
                                          CurrencyHelper.formatRupiah(amt),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ))
                                .toList(),
                          );
                        }),
                        const SizedBox(height: 10),
                        // Change
                        Obx(() {
                          final change = c.cashAmount.value - c.total;
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: change >= 0
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: change >= 0
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  change >= 0
                                      ? 'Kembalian'
                                      : 'Kekurangan',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: change >= 0
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                                Text(
                                  CurrencyHelper.formatRupiah(change.abs()),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: change >= 0
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                      ],
                    )
                  : const SizedBox(height: 16)),

              // Confirm button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: c.processPayment,
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Konfirmasi Pembayaran'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<double> _quickAmounts(double total) {
    final multiples = [5000.0, 10000.0, 20000.0, 50000.0, 100000.0];
    final result = <double>[];
    for (final m in multiples) {
      final rounded = (total / m).ceil() * m;
      if (!result.contains(rounded) && rounded >= total) {
        result.add(rounded);
        if (result.length >= 4) break;
      }
    }
    return result;
  }
}
