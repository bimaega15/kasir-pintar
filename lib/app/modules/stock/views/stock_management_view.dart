import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/stock_movement_model.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/constants/app_colors.dart';
import '../controllers/stock_controller.dart';

class StockManagementView extends GetView<StockController> {
  const StockManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    final searchCtrl = TextEditingController();
    final searchQuery = ''.obs;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manajemen Stok'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Semua Pergerakan Stok',
            icon: const Icon(Icons.history_rounded),
            onPressed: () =>
                Get.toNamed(AppRoutes.stockCard, arguments: null),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: searchCtrl,
              onChanged: (v) => searchQuery.value = v.toLowerCase(),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                hintStyle:
                    TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                prefixIcon:
                    Icon(Icons.search, color: Colors.white.withValues(alpha: 0.8)),
                suffixIcon: Obx(() => searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white),
                        onPressed: () {
                          searchCtrl.clear();
                          searchQuery.value = '';
                        },
                      )
                    : const SizedBox.shrink()),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          // Product list
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final query = searchQuery.value;
              final filtered = controller.products
                  .where((p) =>
                      query.isEmpty || p.name.toLowerCase().contains(query))
                  .toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 64,
                          color: AppColors.textSecondary
                              .withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text(
                        query.isEmpty
                            ? 'Belum ada produk'
                            : 'Produk tidak ditemukan',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.loadAll,
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (ctx, i) =>
                      _ProductStockTile(product: filtered[i]),
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.stockOpname),
        backgroundColor: Colors.teal.shade600,
        icon: const Icon(Icons.fact_check_outlined),
        label: const Text('Stok Opname'),
      ),
    );
  }
}

class _ProductStockTile extends StatelessWidget {
  final ProductModel product;
  const _ProductStockTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<StockController>();
    final isLow = product.stock < 5;
    final stockColor = isLow ? AppColors.error : Colors.green.shade700;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isLow
              ? AppColors.error.withValues(alpha: 0.25)
              : AppColors.divider,
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(product.emoji, style: const TextStyle(fontSize: 22)),
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          isLow ? 'Stok menipis!' : 'Stok tersedia',
          style: TextStyle(
              fontSize: 11,
              color: stockColor),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${product.stock}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: stockColor,
                  ),
                ),
                const Text('unit',
                    style: TextStyle(
                        fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  color: AppColors.textSecondary),
              onSelected: (val) {
                if (val == 'adjust') {
                  _showAdjustDialog(context, ctrl, product);
                } else if (val == 'card') {
                  Get.toNamed(AppRoutes.stockCard, arguments: product.id);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'adjust',
                    child: Row(children: [
                      Icon(Icons.tune_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Sesuaikan Stok'),
                    ])),
                const PopupMenuItem(
                    value: 'card',
                    child: Row(children: [
                      Icon(Icons.history_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Kartu Stok'),
                    ])),
              ],
            ),
          ],
        ),
        onTap: () => _showAdjustDialog(context, ctrl, product),
        onLongPress: () => _showAdjustDialog(context, ctrl, product),
      ),
    );
  }

  void _showAdjustDialog(
      BuildContext context, StockController ctrl, ProductModel product) {
    final typeObs = StockMovementType.purchase.obs;
    final qtyCtrl = TextEditingController(text: '1');
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(product.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Stok saat ini: ${product.stock} unit',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Jenis Penyesuaian',
                style:
                    TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Obx(() => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButton<String>(
                    value: typeObs.value,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: [
                      _dropdownItem(StockMovementType.purchase, 'Stok Masuk (Pembelian)'),
                      _dropdownItem(StockMovementType.adjustmentIn, 'Koreksi Tambah'),
                      _dropdownItem(StockMovementType.adjustmentOut, 'Koreksi Kurang'),
                    ],
                    onChanged: (v) {
                      if (v != null) typeObs.value = v;
                    },
                  ),
                )),
            const SizedBox(height: 14),
            const Text('Jumlah',
                style:
                    TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: 'Masukkan jumlah...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Catatan (opsional)',
                style:
                    TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Tambahkan catatan...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
                  if (qty <= 0) {
                    Get.snackbar('Perhatian', 'Jumlah harus lebih dari 0',
                        snackPosition: SnackPosition.BOTTOM);
                    return;
                  }
                  final type = typeObs.value;
                  final isOut = type == StockMovementType.adjustmentOut;
                  final delta = isOut ? -qty : qty;
                  Get.back();
                  await ctrl.adjustStock(
                      product, delta, type, notesCtrl.text.trim());
                  Get.snackbar(
                    'Berhasil',
                    'Stok ${product.name} berhasil diperbarui',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green.shade600,
                    colorText: Colors.white,
                  );
                },
                child: const Text('Simpan Perubahan',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DropdownMenuItem<String> _dropdownItem(String value, String label) =>
      DropdownMenuItem(value: value, child: Text(label));
}
