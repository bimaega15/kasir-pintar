import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/kitchen_controller.dart';
import '../../../data/models/order_model.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/helpers/currency_helper.dart';

class KitchenView extends GetView<KitchenController> {
  const KitchenView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Dapur'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          actions: [
            Obx(() => controller.isLoading.value
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: controller.loadOrders,
                  )),
          ],
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [
              Obx(() => _buildTab(
                  'Pending', controller.pendingOrders.length, Colors.orange)),
              Obx(() => _buildTab(
                  'Proses', controller.inProgressOrders.length, Colors.blue)),
              Obx(() =>
                  _buildTab('Siap', controller.readyOrders.length, Colors.green)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOrderList(KitchenStatus.pending),
            _buildOrderList(KitchenStatus.inProgress),
            _buildOrderList(KitchenStatus.ready),
          ],
        ),
      ),
    );
  }

  Tab _buildTab(String label, int count, Color badgeColor) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderList(KitchenStatus status) {
    return Obx(() {
      final list = switch (status) {
        KitchenStatus.pending => controller.pendingOrders,
        KitchenStatus.inProgress => controller.inProgressOrders,
        _ => controller.readyOrders,
      };

      if (list.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.restaurant_menu_rounded,
                  size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text('Tidak ada pesanan',
                  style: TextStyle(color: Colors.grey.shade500)),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) => _buildOrderCard(list[i]),
      );
    });
  }

  Widget _buildOrderCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: AppColors.cardShadow, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(
                  order.orderType == OrderType.dineIn
                      ? Icons.restaurant_rounded
                      : Icons.takeout_dining_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  order.invoiceNumber,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
                if (order.tableNumber != null) ...[
                  const SizedBox(width: 6),
                  Text('· Meja ${order.tableNumber}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                ],
                const Spacer(),
                Text(
                  CurrencyHelper.formatTime(order.createdAt),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          // Items
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(item.productEmoji,
                                  style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.productName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '×${item.quantity}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                      fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          if (item.note.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 3, left: 26),
                              child: Text(
                                '📝 ${item.note}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.deepOrange,
                                    fontStyle: FontStyle.italic),
                              ),
                            ),
                        ],
                      ),
                    )),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (order.kitchenStatus == KitchenStatus.pending)
                      ElevatedButton.icon(
                        onPressed: () => controller.updateStatus(
                            order.id, KitchenStatus.inProgress),
                        icon: const Icon(Icons.play_arrow_rounded, size: 16),
                        label: const Text('Mulai Proses'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    if (order.kitchenStatus == KitchenStatus.inProgress)
                      ElevatedButton.icon(
                        onPressed: () => controller.updateStatus(
                            order.id, KitchenStatus.ready),
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Tandai Siap'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    if (order.kitchenStatus == KitchenStatus.ready)
                      const Chip(
                        label: Text('Siap Disajikan ✓'),
                        backgroundColor: Color(0xFFE8F5E9),
                        labelStyle: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
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
}
