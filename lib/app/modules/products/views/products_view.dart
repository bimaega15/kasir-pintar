import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/products_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/helpers/currency_helper.dart';
import 'product_barcode_sheet.dart';

class ProductsView extends GetView<ProductsController> {
  const ProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Produk'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: TextField(
                  controller: controller.searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Cari produk...',
                    hintStyle: const TextStyle(color: Colors.white60),
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.white70),
                    suffixIcon: Obx(() =>
                        controller.searchQuery.value.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    color: Colors.white70),
                                onPressed: controller.searchController.clear,
                              )
                            : const SizedBox()),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              // Category filter
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                  itemCount: controller.categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final cat = controller.categories[i];
                    return Obx(() {
                      final selected =
                          controller.filterCategory.value == cat.id;
                      return GestureDetector(
                        onTap: () =>
                            controller.filterCategory.value = cat.id,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${cat.icon} ${cat.name}',
                            style: TextStyle(
                              fontSize: 12,
                              color: selected
                                  ? AppColors.primary
                                  : Colors.white,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          controller.prepareAdd();
          Get.toNamed(AppRoutes.addEditProduct);
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk'),
      ),
      body: Obx(() {
        final list = controller.filteredProducts;
        if (list.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('📦', style: TextStyle(fontSize: 52)),
                SizedBox(height: 12),
                Text('Belum ada produk',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 16)),
                SizedBox(height: 4),
                Text('Tekan tombol + untuk menambah produk',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: list.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, indent: 72),
          itemBuilder: (context, i) => _buildProductTile(context, list[i]),
        );
      }),
    );
  }

  Widget _buildProductTile(BuildContext context, product) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: product.imagePath != null &&
                File(product.imagePath!).existsSync()
            ? Image.file(
                File(product.imagePath!),
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              )
            : Center(
                child: Text(product.emoji, style: const TextStyle(fontSize: 26)),
              ),
      ),
      title: Text(
        product.name,
        style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        '${CurrencyHelper.formatRupiah(product.price)}  •  Stok: ${product.computedStock}',
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (product.computedStock < 5)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                product.computedStock == 0 ? 'Habis' : 'Hampir habis',
                style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
          IconButton(
            icon: Icon(Icons.qr_code_rounded,
                color: Colors.purple.shade400, size: 20),
            tooltip: 'Lihat QR Code',
            onPressed: () => ProductBarcodeSheet.show(context, product),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: AppColors.primary, size: 20),
            onPressed: () {
              controller.prepareEdit(product);
              Get.toNamed(AppRoutes.addEditProduct);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColors.error, size: 20),
            onPressed: () => controller.deleteProduct(product),
          ),
        ],
      ),
    );
  }
}
