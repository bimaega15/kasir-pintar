import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../data/models/bahan_baku_model.dart';
import '../../../utils/helpers/currency_helper.dart';
import '../controllers/bahan_baku_controller.dart';
import '../../../utils/responsive/responsive_helper.dart';

class BahanBakuView extends GetView<BahanBakuController> {
  const BahanBakuView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bahan Baku'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: controller.loadAll,
          ),
        ],
      ),
      body: Column(
        children: [
          // Low stock alert
          Obx(() {
            final lowStock = controller.lowStockItems;
            if (lowStock.isEmpty) return const SizedBox.shrink();
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.warning.withValues(alpha: 0.15),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.orange.shade800, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${lowStock.length} bahan baku stok menipis!',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => controller.searchQuery.value = v,
              decoration: InputDecoration(
                hintText: 'Cari bahan baku...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
              ),
            ),
          ),
          // List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = controller.filteredList;
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 64, color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      Text(
                        controller.searchQuery.value.isEmpty
                            ? 'Belum ada bahan baku'
                            : 'Tidak ditemukan',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: controller.loadAll,
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _BahanBakuCard(item: list[i]),
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          controller.prepareAdd();
          Get.toNamed(AppRoutes.addEditBahanBaku);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
      ),
    );
  }
}

class _BahanBakuCard extends StatelessWidget {
  final dynamic item;
  const _BahanBakuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<BahanBakuController>();
    final isLow = item.isLowStock;

    return GestureDetector(
      onTap: () {
        Get.toNamed(AppRoutes.bahanBakuDetail, arguments: item);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLow
                ? AppColors.warning.withValues(alpha: 0.5)
                : AppColors.divider,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Emoji
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (isLow ? AppColors.warning : AppColors.primary)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(item.emoji, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Harga: ${CurrencyHelper.formatRupiah(item.price)}/${item.unit}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                // Stock badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLow
                            ? AppColors.error.withValues(alpha: 0.1)
                            : AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_formatQty(item.stock)} ${item.unit}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isLow ? AppColors.error : AppColors.success,
                        ),
                      ),
                    ),
                    if (isLow) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Min: ${_formatQty(item.minStock)}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.orange.shade700),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.add_circle_outline,
                    label: 'Stok Masuk',
                    color: AppColors.success,
                    onTap: () => _showStockDialog(
                        context, ctrl, item, BahanBakuMovementType.purchase),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.remove_circle_outline,
                    label: 'Pemakaian',
                    color: AppColors.error,
                    onTap: () => _showStockDialog(
                        context, ctrl, item, BahanBakuMovementType.usage),
                  ),
                ),
                const SizedBox(width: 8),
                _SmallActionButton(
                  icon: Icons.edit_rounded,
                  color: AppColors.primary,
                  onTap: () {
                    ctrl.prepareEdit(item);
                    Get.toNamed(AppRoutes.addEditBahanBaku);
                  },
                ),
                const SizedBox(width: 6),
                _SmallActionButton(
                  icon: Icons.delete_outline_rounded,
                  color: AppColors.error,
                  onTap: () => _confirmDelete(context, ctrl, item),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatQty(double qty) {
    return qty == qty.truncateToDouble()
        ? qty.toInt().toString()
        : qty.toStringAsFixed(1);
  }

  void _showStockDialog(BuildContext context, BahanBakuController ctrl,
      dynamic item, String type) {
    ctrl.clearMovementForm();
    final isPurchase = type == BahanBakuMovementType.purchase;

    Get.dialog(
      AlertDialog(
        title: Text(isPurchase ? 'Stok Masuk' : 'Pemakaian'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(item.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Stok: ${_formatQty(item.stock)} ${item.unit}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl.movementQtyController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: InputDecoration(
                labelText: 'Jumlah (${item.unit})',
                border: const OutlineInputBorder(),
              ),
            ),
            if (isPurchase) ...[
              const SizedBox(height: 12),
              TextField(
                controller: ctrl.movementCostController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                decoration: const InputDecoration(
                  labelText: 'Total Biaya (Rp) - opsional',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: ctrl.movementNotesController,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final qty =
                  double.tryParse(ctrl.movementQtyController.text) ?? 0;
              if (qty <= 0) {
                Get.snackbar('Peringatan', 'Jumlah harus lebih dari 0',
                    snackPosition: SnackPosition.BOTTOM);
                return;
              }
              final cost =
                  double.tryParse(ctrl.movementCostController.text);
              Get.back();
              ctrl.adjustStock(
                item,
                qty,
                type,
                ctrl.movementNotesController.text.trim(),
                totalCost: isPurchase ? cost : null,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isPurchase ? AppColors.success : AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(isPurchase ? 'Tambah Stok' : 'Kurangi Stok'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, BahanBakuController ctrl, dynamic item) {
    Get.dialog(
      AlertDialog(
        title: const Text('Hapus Bahan Baku'),
        content: Text(
            'Yakin ingin menghapus "${item.name}"?\nSemua riwayat pergerakan stok juga akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              ctrl.deleteBahanBaku(item);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SmallActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
