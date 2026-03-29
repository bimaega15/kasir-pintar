import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/helpers/currency_helper.dart';
import '../../../utils/responsive/responsive_helper.dart';
import '../../main_navigation/controllers/main_navigation_controller.dart';
import '../../shift/controllers/shift_controller.dart';
import '../../../services/user_session.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: controller.scrollController,
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: Res.padding(context),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildShiftBanner(),
                _buildLowStockBanner(),
                _buildLowStockBahanBakuBanner(),
                _buildStatsGrid(context),
                const SizedBox(height: 24),
                _buildQuickAccessSection(context),
                const SizedBox(height: 24),
                _buildInfoCard(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessSection(BuildContext context) {
    final session = Get.find<UserSession>();
    final navCtrl = Get.find<MainNavigationController>(
        tag: MainNavigationController.TAG);

    final items = <_MenuItemData>[
      _MenuItemData(
        icon: Icons.point_of_sale_rounded,
        label: 'Kasir',
        color: AppColors.primary,
        onTap: () => navCtrl.changeIndex(4),
      ),
      if (session.isAdmin)
        _MenuItemData(
          icon: Icons.inventory_2_rounded,
          label: 'Master Data',
          color: Colors.green.shade600,
          onTap: () => navCtrl.changeIndex(1),
        ),
      _MenuItemData(
        icon: Icons.assessment_rounded,
        label: 'Laporan',
        color: Colors.purple.shade600,
        onTap: () => navCtrl.changeIndex(2),
      ),
      _MenuItemData(
        icon: Icons.settings_rounded,
        label: 'Pengaturan',
        color: Colors.blueGrey.shade600,
        onTap: () => navCtrl.changeIndex(3),
      ),
      _MenuItemData(
        icon: Icons.history_rounded,
        label: 'Riwayat',
        color: Colors.indigo.shade500,
        onTap: () => Get.toNamed(AppRoutes.history),
      ),
      _MenuItemData(
        icon: Icons.people_alt_rounded,
        label: 'Pelanggan',
        color: Colors.teal.shade600,
        onTap: () => Get.toNamed(AppRoutes.customers),
      ),
      _MenuItemData(
        icon: Icons.confirmation_number_rounded,
        label: 'Antrian',
        color: Colors.orange.shade700,
        onTap: () => Get.toNamed(AppRoutes.queue),
      ),
      _MenuItemData(
        icon: Icons.badge_rounded,
        label: 'Presensi',
        color: Colors.cyan.shade700,
        onTap: () => Get.toNamed(AppRoutes.attendance),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Menu',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          child: GridView.count(
            crossAxisCount: Res.menuCols(context),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 20,
            crossAxisSpacing: 0,
            childAspectRatio: 0.82,
            children: items.map((item) => _buildMenuIcon(item)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuIcon(_MenuItemData item) {
    return GestureDetector(
      onTap: item.onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    final shiftCtrl = Get.find<ShiftController>();
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: AppColors.primary,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Obx(() => AnimatedOpacity(
        opacity: controller.isAppBarCollapsed.value ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Kasir Pintar Sasbim',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: controller.loadStats,
              child: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      )),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryDark, AppColors.primaryLight],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles background
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.03),
                  ),
                ),
              ),
              // Content - hanya tampil saat expanded
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting with Refresh Button
                    Obx(() => Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    controller.greeting.value,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Kasir Pintar Sasbim',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Refresh Button
                            GestureDetector(
                              onTap: controller.loadStats,
                              child: const Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Shift Badge
                            Obx(() => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: shiftCtrl.activeShift.value != null
                                        ? Colors.green.shade400
                                        : Colors.red.shade400,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (shiftCtrl.activeShift.value !=
                                                null
                                            ? Colors.green
                                            : Colors.red)
                                          .withValues(alpha: 0.3),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        shiftCtrl.activeShift.value != null
                                            ? 'Aktif'
                                            : 'Tutup',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        )),
                    const SizedBox(height: 12),
                    // Subtitle
                    const Text(
                      'Sistem Kasir Modern untuk Restoran & Retail',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShiftBanner() {
    final shiftCtrl = Get.find<ShiftController>();
    return Obx(() {
      final shift = shiftCtrl.activeShift.value;
      if (shift != null) {
        // Active shift — green info strip
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_open_rounded,
                  color: AppColors.success, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Shift aktif: ${shift.cashierName} · ${CurrencyHelper.formatTime(shift.openedAt)}',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600),
                ),
              ),
              GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.closeShift),
                child: const Text('Tutup Shift',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.success,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      } else {
        // No active shift — warning strip
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.warning, size: 18),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Belum ada shift aktif. Buka shift sebelum berjualan.',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.warning),
                ),
              ),
              GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.openShift),
                child: const Text('Buka',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.warning,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    });
  }

  Widget _buildLowStockBanner() {
    return Obx(() {
      final items = controller.lowStockProducts;
      if (items.isEmpty) return const SizedBox.shrink();

      return GestureDetector(
        onTap: () => Get.toNamed(AppRoutes.products),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.orange.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Stok Hampir Habis (${items.length} produk)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                    Text(
                      'Kelola →',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 14, endIndent: 14),
              // Product list (max 3 shown)
              ...items.take(3).map((p) => Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Row(
                      children: [
                        Text(p.emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            p.name,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: p.computedStock == 0
                                ? Colors.red.shade100
                                : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            p.computedStock == 0 ? 'Habis' : 'Stok: ${p.computedStock}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: p.computedStock == 0
                                  ? Colors.red.shade700
                                  : Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              if (items.length > 3)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  child: Text(
                    '+${items.length - 3} produk lainnya',
                    style: TextStyle(
                        fontSize: 11, color: Colors.orange.shade600),
                  ),
                )
              else
                const SizedBox(height: 4),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildLowStockBahanBakuBanner() {
    return Obx(() {
      final items = controller.lowStockBahanBaku;
      if (items.isEmpty) return const SizedBox.shrink();

      return GestureDetector(
        onTap: () => Get.toNamed(AppRoutes.bahanBaku),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.red.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bahan Baku Menipis (${items.length} item)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ),
                    Text(
                      'Kelola →',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 14, endIndent: 14),
              ...items.take(3).map((bb) => Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Row(
                      children: [
                        Text(bb.emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            bb.name,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_fmtQty(bb.stock)}/${_fmtQty(bb.minStock)} ${bb.unit}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              if (items.length > 3)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  child: Text(
                    '+${items.length - 3} bahan baku lainnya',
                    style: TextStyle(
                        fontSize: 11, color: Colors.red.shade600),
                  ),
                )
              else
                const SizedBox(height: 4),
            ],
          ),
        ),
      );
    });
  }

  String _fmtQty(double qty) =>
      qty == qty.truncateToDouble() ? qty.toInt().toString() : qty.toStringAsFixed(1);

  Widget _buildStatsGrid(BuildContext context) {
    final cols = Res.cols(context, mobile: 2, tablet: 4);
    final ratio = Res.isTablet(context) ? 1.9 : 1.6;
    return Obx(() => GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: ratio,
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

  Widget _buildInfoCard() {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.about),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.white, size: 36),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kasir Pintar Sasbim v2.0',
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
      ),
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuItemData({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
