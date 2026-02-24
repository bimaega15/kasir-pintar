import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/helpers/currency_helper.dart';

class ActiveOrdersView extends StatefulWidget {
  const ActiveOrdersView({super.key});

  @override
  State<ActiveOrdersView> createState() => _ActiveOrdersViewState();
}

class _ActiveOrdersViewState extends State<ActiveOrdersView> {
  final _repo = Get.find<OrderRepository>();
  final orders = <OrderModel>[].obs;
  final isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    isLoading.value = true;
    try {
      final list = await _repo.getActive();
      orders.assignAll(list);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pesanan Aktif'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Obx(() {
        if (isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (orders.isEmpty) {
          return const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.receipt_long_rounded,
                  size: 64, color: AppColors.textSecondary),
              SizedBox(height: 12),
              Text('Tidak ada pesanan aktif',
                  style: TextStyle(color: AppColors.textSecondary)),
            ]),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (_, i) => _buildOrderCard(orders[i]),
        );
      }),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    Color statusColor;
    switch (order.kitchenStatus) {
      case KitchenStatus.pending:
        statusColor = Colors.orange.shade600;
        break;
      case KitchenStatus.inProgress:
        statusColor = Colors.blue.shade600;
        break;
      case KitchenStatus.ready:
        statusColor = AppColors.success;
        break;
      default:
        statusColor = AppColors.textSecondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 6,
              offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(
                  order.orderType == OrderType.dineIn
                      ? Icons.restaurant_rounded
                      : Icons.takeout_dining_rounded,
                  color: statusColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(order.invoiceNumber,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                if (order.tableNumber != null) ...[
                  const SizedBox(width: 6),
                  Text('· Meja ${order.tableNumber}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                ],
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    order.kitchenStatusLabel,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          // Items preview
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Column(
              children: order.items
                  .map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(children: [
                          Text(item.productEmoji),
                          const SizedBox(width: 6),
                          Expanded(
                              child: Text(item.productName,
                                  style: const TextStyle(fontSize: 13))),
                          Text('${item.quantity}x',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                        ]),
                      ))
                  .toList(),
            ),
          ),
          // Footer
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Text(
                  CurrencyHelper.formatRupiah(order.total),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.primary),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () =>
                      Get.toNamed(AppRoutes.payment, arguments: order),
                  icon: const Icon(Icons.payment_rounded, size: 16),
                  label: const Text('Bayar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: order.kitchenStatus == KitchenStatus.ready
                        ? AppColors.success
                        : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
