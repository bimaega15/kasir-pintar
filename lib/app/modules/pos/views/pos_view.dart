import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../order/controllers/order_controller.dart';
import '../../../data/models/order_model.dart';
import '../../../utils/constants/app_colors.dart';
import 'barcode_scanner_view.dart';
import 'widgets/product_card.dart';
import 'widgets/cart_panel.dart';
import '../../../utils/helpers/currency_helper.dart';

class PosView extends GetView<OrderController> {
  const PosView({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          if (controller.orderType.value == OrderType.takeAway) {
            return const Text('Kasir · Take Away');
          }
          final table = controller.selectedTable.value;
          if (table != null) {
            return Text(
                'Kasir · Meja ${table.number} (${controller.guestCount.value} tamu)');
          }
          return const Text('Kasir');
        }),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (BarcodeScannerView.isSupported)
            IconButton(
              icon: const Icon(Icons.qr_code_scanner_rounded),
              tooltip: 'Scan QR Produk',
              onPressed: () async {
                final result = await Navigator.of(context).push<String>(
                  MaterialPageRoute(
                    builder: (_) => const BarcodeScannerView(),
                  ),
                );
                if (result != null) controller.handleScannedQr(result);
              },
            ),
          Obx(() => controller.cart.isNotEmpty
              ? Stack(
                  alignment: Alignment.topRight,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_rounded),
                      onPressed: () => _showCartBottomSheet(context),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${controller.totalItems}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                )
              : const SizedBox()),
        ],
      ),
      body: isWide ? _buildWideLayout() : _buildNarrowLayout(context),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(flex: 3, child: _buildProductPanel()),
        const SizedBox(width: 1),
        const SizedBox(width: 320, child: CartPanel()),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    return Stack(
      children: [
        _buildProductPanel(),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Obx(() {
            if (controller.cart.isEmpty) return const SizedBox.shrink();
            return _buildFloatingCartBar(context);
          }),
        ),
      ],
    );
  }

  Widget _buildFloatingCartBar(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCartBottomSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Item count badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${controller.totalItems}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${controller.totalItems} item dipilih',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              CurrencyHelper.formatRupiah(controller.total),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildProductPanel() {
    return Column(
      children: [
        _buildSearchBar(),
        _buildPriceLevelBar(),
        _buildCategoryChips(),
        Expanded(child: _buildProductGrid()),
      ],
    );
  }

  Widget _buildPriceLevelBar() {
    return Obx(() {
      final levels = controller.priceLevels;
      final currentLevelId = controller.activePriceLevelId.value; // register dependency di sini
      if (levels.length <= 1) return const SizedBox.shrink();
      return Container(
        height: 40,
        color: AppColors.primary.withValues(alpha: 0.06),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          itemCount: levels.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final level = levels[i];
            final selected = currentLevelId == level.id;
            return GestureDetector(
              onTap: () => controller.setActivePriceLevel(level.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.divider,
                  ),
                ),
                child: Text(
                  level.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: TextField(
        controller: controller.searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Cari produk...',
          hintStyle: const TextStyle(color: Colors.white60),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white70),
                  onPressed: controller.searchController.clear,
                )
              : const SizedBox()),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      height: 48,
      color: Colors.white,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: controller.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = controller.categories[i];
          return Obx(() {
            final selected = controller.selectedCategory.value == cat.id;
            return GestureDetector(
              onTap: () => controller.selectedCategory.value = cat.id,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.divider,
                  ),
                ),
                child: Text(
                  '${cat.icon} ${cat.name}',
                  style: TextStyle(
                    fontSize: 13,
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    return Obx(() {
      final list = controller.filteredProducts;
      // Register level dependencies di sini (bukan di dalam itemBuilder)
      final levelId = controller.activePriceLevelId.value;
      final levels = controller.priceLevels;
      // Snapshot cart so itemBuilder has reactive dependency on it
      final cart = controller.cart.toList();
      final activeLevel = levels.isNotEmpty
          ? levels.firstWhereOrNull((l) => l.id == levelId)
          : null;
      final showLabel = levels.length > 1 && activeLevel != null;
      if (list.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('📦', style: TextStyle(fontSize: 48)),
              SizedBox(height: 12),
              Text('Tidak ada produk',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 15)),
            ],
          ),
        );
      }
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180,
          childAspectRatio: 0.75,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: list.length,
        itemBuilder: (context, i) {
          final product = list[i];
          final displayPrice = activeLevel != null
              ? product.getPriceForLevel(levelId)
              : null;
          return ProductCard(
            product: product,
            onTap: () => controller.addToCart(product),
            onDecrease: () => controller.decreaseQty(product.id),
            displayPrice: displayPrice,
            levelLabel: showLabel ? activeLevel.name : null,
            quantity: cart
                .firstWhereOrNull((i) => i.productId == product.id)
                ?.quantity ?? 0,
          );
        },
      );
    });
  }

  void _showCartBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const CartPanel(),
      ),
    );
  }
}
