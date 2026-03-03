import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/void_log_model.dart';
import '../../../data/providers/storage_provider.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/table_repository.dart';
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
  final _tableRepo = Get.find<TableRepository>();
  final _db = Get.find<DatabaseProvider>();
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
    final isOnHold = order.kitchenStatus == KitchenStatus.onHold;

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
      case KitchenStatus.onHold:
        statusColor = Colors.amber.shade700;
        break;
      default:
        statusColor = AppColors.textSecondary;
    }

    return GestureDetector(
      onLongPress: () => _showOrderActions(order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isOnHold
              ? Border.all(color: Colors.amber.shade700, width: 1.5)
              : null,
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
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
                  if (isOnHold)
                    OutlinedButton.icon(
                      onPressed: () => _resumeOrder(order),
                      icon: const Icon(Icons.play_arrow_rounded, size: 16),
                      label: const Text('Aktifkan'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: const BorderSide(color: AppColors.success),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () =>
                          Get.toNamed(AppRoutes.payment, arguments: order),
                      icon: const Icon(Icons.payment_rounded, size: 16),
                      label: const Text('Bayar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            order.kitchenStatus == KitchenStatus.ready
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
      ),
    );
  }

  void _showOrderActions(OrderModel order) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                order.invoiceNumber,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            const Divider(height: 1),
            if (order.kitchenStatus != KitchenStatus.onHold)
              ListTile(
                leading: const Icon(Icons.pause_circle_outline_rounded,
                    color: Colors.amber),
                title: const Text('Tahan Pesanan'),
                subtitle: const Text('Pesanan ditangguhkan sementara'),
                onTap: () {
                  Navigator.pop(context);
                  _holdOrder(order);
                },
              ),
            if (order.kitchenStatus == KitchenStatus.onHold)
              ListTile(
                leading: const Icon(Icons.play_circle_outline_rounded,
                    color: AppColors.success),
                title: const Text('Aktifkan Kembali'),
                onTap: () {
                  Navigator.pop(context);
                  _resumeOrder(order);
                },
              ),
            ListTile(
              leading:
                  const Icon(Icons.cancel_rounded, color: AppColors.error),
              title: const Text('Batalkan Pesanan',
                  style: TextStyle(color: AppColors.error)),
              subtitle: const Text('Tindakan ini tidak dapat dibatalkan'),
              onTap: () {
                Navigator.pop(context);
                _showVoidDialog(order);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _holdOrder(OrderModel order) async {
    await _repo.updateKitchenStatus(order.id, KitchenStatus.onHold);
    await _load();
    Get.snackbar(
      'Pesanan Ditahan',
      '${order.invoiceNumber} ditangguhkan',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.amber.shade100,
      colorText: Colors.amber.shade900,
    );
  }

  Future<void> _resumeOrder(OrderModel order) async {
    await _repo.updateKitchenStatus(order.id, KitchenStatus.pending);
    await _load();
    Get.snackbar(
      'Pesanan Diaktifkan',
      '${order.invoiceNumber} kembali aktif',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade900,
    );
  }

  void _showVoidDialog(OrderModel order) {
    final reasons = [
      'Salah input',
      'Pelanggan batal',
      'Stok tidak tersedia',
      'Lainnya',
    ];
    String selectedReason = reasons.first;
    final otherController = TextEditingController();

    Get.dialog(
      StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Batalkan Pesanan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Invoice: ${order.invoiceNumber}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13)),
              const SizedBox(height: 16),
              const Text('Alasan pembatalan:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedReason,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: reasons
                    .map((r) =>
                        DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => selectedReason = v);
                },
              ),
              if (selectedReason == 'Lainnya') ...[
                const SizedBox(height: 10),
                TextField(
                  controller: otherController,
                  decoration: const InputDecoration(
                    hintText: 'Tuliskan alasan...',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('Kembali')),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () async {
                final reason = selectedReason == 'Lainnya'
                    ? otherController.text.trim().isEmpty
                        ? 'Lainnya'
                        : otherController.text.trim()
                    : selectedReason;
                Get.back();
                await _voidOrder(order, reason);
              },
              child: const Text('Batalkan',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _voidOrder(OrderModel order, String reason) async {
    try {
      final log = VoidLogModel(
        orderId: order.id,
        invoiceNumber: order.invoiceNumber,
        orderTotal: order.total,
        reason: reason,
        voidedBy: 'Kasir',
      );
      await _db.insertVoidLog(log);
      await _repo.delete(order.id);
      if (order.tableId != null) {
        await _tableRepo.setAvailable(order.tableId!);
      }
      await _load();
      Get.snackbar(
        'Pesanan Dibatalkan',
        '${order.invoiceNumber} telah dibatalkan',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    } catch (e) {
      Get.snackbar('Error', 'Gagal membatalkan: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}
