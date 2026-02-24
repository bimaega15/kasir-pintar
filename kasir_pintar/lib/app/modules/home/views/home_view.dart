import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/helpers/currency_helper.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildStatsGrid(),
                const SizedBox(height: 24),
                const Text(
                  'Menu Utama',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMenuGrid(),
                const SizedBox(height: 24),
                _buildInfoCard(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryDark, AppColors.primaryLight],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(() => Text(
                    controller.greeting.value,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  )),
              const SizedBox(height: 4),
              const Text(
                'Kasir Pintar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_rounded, color: Colors.white),
          tooltip: 'Pengaturan',
          onPressed: () => Get.toNamed(AppRoutes.appSettings),
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          tooltip: 'Refresh',
          onPressed: controller.loadStats,
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Obx(() => GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _buildStatCard(
              label: 'Pendapatan Hari Ini',
              value: CurrencyHelper.formatRupiah(controller.todayRevenue.value),
              icon: Icons.attach_money_rounded,
              color: AppColors.success,
            ),
            _buildStatCard(
              label: 'Transaksi Hari Ini',
              value: '${controller.totalTransactionsToday.value} Transaksi',
              icon: Icons.receipt_long_rounded,
              color: AppColors.accent,
            ),
            _buildStatCard(
              label: 'Pesanan Aktif',
              value: '${controller.activeOrderCount.value} Pesanan',
              icon: Icons.restaurant_rounded,
              color: Colors.orange.shade600,
            ),
            _buildStatCard(
              label: 'Total Produk',
              value: '${controller.totalProducts.value} Produk',
              icon: Icons.inventory_2_rounded,
              color: AppColors.primaryLight,
            ),
          ],
        ));
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 6,
              offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.0,
      children: [
        _buildMenuCard(
          label: 'Kasir',
          icon: Icons.point_of_sale_rounded,
          color: AppColors.primary,
          onTap: () => Get.toNamed(AppRoutes.orderType),
        ),
        _buildMenuCard(
          label: 'Meja',
          icon: Icons.table_restaurant_rounded,
          color: Colors.teal.shade600,
          onTap: () => Get.toNamed(AppRoutes.tables),
        ),
        _buildMenuCard(
          label: 'Dapur',
          icon: Icons.soup_kitchen_rounded,
          color: Colors.deepOrange.shade600,
          onTap: () => Get.toNamed(AppRoutes.kitchen),
          badge: controller.activeOrderCount,
        ),
        _buildMenuCard(
          label: 'Aktif',
          icon: Icons.receipt_long_rounded,
          color: Colors.purple.shade600,
          onTap: () => Get.toNamed(AppRoutes.activeOrders),
          badge: controller.activeOrderCount,
        ),
        _buildMenuCard(
          label: 'Produk',
          icon: Icons.inventory_2_rounded,
          color: AppColors.accent,
          onTap: () => Get.toNamed(AppRoutes.products),
        ),
        _buildMenuCard(
          label: 'Riwayat',
          icon: Icons.history_rounded,
          color: AppColors.success,
          onTap: () => Get.toNamed(AppRoutes.history),
        ),
        _buildMenuCard(
          label: 'Printer',
          icon: Icons.print_rounded,
          color: const Color(0xFF1565C0),
          onTap: () => Get.toNamed(AppRoutes.printerSettings),
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    RxInt? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                top: 6,
                right: 6,
                child: Obx(() => badge.value > 0
                    ? Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${badge.value}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    : const SizedBox()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.white, size: 36),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kasir Pintar v2.0',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Restoran & retail POS dengan dapur & multi-payment.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
