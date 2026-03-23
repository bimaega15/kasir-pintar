import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/main_navigation_controller.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../home/views/home_view.dart';
import '../../settings/views/settings_view.dart';
import '../../../modules/master/views/master_view.dart';
import '../../../modules/report/views/report_view.dart';
import '../../home/controllers/home_controller.dart';
import '../../kitchen/controllers/kitchen_controller.dart';
import '../../debt/controllers/debt_controller.dart';
import '../../order/controllers/order_controller.dart';
import '../../../services/user_session.dart';

class MainNavigationView extends StatefulWidget {
  const MainNavigationView({super.key});

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> {
  late final MainNavigationController _ctrl;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<MainNavigationController>(tag: MainNavigationController.TAG);
    _pages = const [
      HomeView(),
      MasterPageContent(),
      ReportPageContent(),
      SettingsView(),
      KasirPageContent(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isKasir = Get.find<UserSession>().isKasir;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() => Stack(
        children: [
          IndexedStack(
            index: _ctrl.currentIndex.value,
            children: _pages,
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(height: 120),
          ),
        ],
      )),
      // Admin-only: FAB Kasir di tengah menonjol ke atas
      floatingActionButton: isKasir
          ? null
          : Obx(() {
              final isActive = _ctrl.currentIndex.value == 4;
              return FloatingActionButton(
                onPressed: () => _ctrl.changeIndex(4),
                backgroundColor: AppColors.primary,
                elevation: isActive ? 2 : 6,
                shape: const CircleBorder(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.point_of_sale_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Kasir',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildCustomBottomBar(),
    );
  }

  Widget _buildCustomBottomBar() {
    return Obx(() {
      final isKasir = Get.find<UserSession>().isKasir;
      final stackIdx = _ctrl.currentIndex.value;
      final isKasirActive = stackIdx == 4;

      if (isKasir) {
        // Kasir role: 4 item inline, tanpa FAB
        return BottomAppBar(
          color: Colors.white,
          elevation: 8,
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.home_rounded, 'Home',
                    !isKasirActive && stackIdx == 0,
                    () => _ctrl.changeIndex(0)),
                _kasirNavItem(isKasirActive),
                _navItem(Icons.assessment_rounded, 'Report',
                    !isKasirActive && stackIdx == 2,
                    () => _ctrl.changeIndex(2)),
                _navItem(Icons.settings_rounded, 'Setting',
                    !isKasirActive && stackIdx == 3,
                    () => _ctrl.changeIndex(3)),
              ],
            ),
          ),
        );
      } else {
        // Admin role: notch di tengah untuk FAB Kasir
        return BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          color: Colors.white,
          elevation: 8,
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.home_rounded, 'Home',
                    !isKasirActive && stackIdx == 0,
                    () => _ctrl.changeIndex(0)),
                _navItem(Icons.inventory_2_rounded, 'Master',
                    !isKasirActive && stackIdx == 1,
                    () => _ctrl.changeIndex(1)),
                const Expanded(child: SizedBox()), // ruang untuk FAB
                _navItem(Icons.assessment_rounded, 'Report',
                    !isKasirActive && stackIdx == 2,
                    () => _ctrl.changeIndex(2)),
                _navItem(Icons.settings_rounded, 'Setting',
                    !isKasirActive && stackIdx == 3,
                    () => _ctrl.changeIndex(3)),
              ],
            ),
          ),
        );
      }
    });
  }

  Widget _navItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: isActive ? 28 : 24,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kasirNavItem(bool isActive) {
    return _navItem(
      Icons.point_of_sale_rounded,
      'Kasir',
      isActive,
      () => _ctrl.changeIndex(4),
    );
  }
}

// ============================================================================
// Kasir Page Content Widget
// ============================================================================

class KasirPageContent extends StatefulWidget {
  const KasirPageContent({super.key});

  @override
  State<KasirPageContent> createState() => _KasirPageContentState();
}

class _KasirPageContentState extends State<KasirPageContent> {
  late final HomeController _homeCtrl;
  late final KitchenController _kitchenCtrl;
  late final OrderController _orderCtrl;
  late final DebtController _debtCtrl;

  @override
  void initState() {
    super.initState();
    _homeCtrl = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());
    _kitchenCtrl = Get.isRegistered<KitchenController>()
        ? Get.find<KitchenController>()
        : Get.put(KitchenController());
    _orderCtrl = Get.isRegistered<OrderController>()
        ? Get.find<OrderController>()
        : Get.put(OrderController());
    _debtCtrl = Get.isRegistered<DebtController>()
        ? Get.find<DebtController>()
        : Get.put(DebtController());
    // Refresh data when kasir page opens
    _homeCtrl.loadStats();
    _kitchenCtrl.loadOrders();
    _orderCtrl.loadParkedCount();
    _debtCtrl.loadDebts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kasir - Point of Sale'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Menu Kasir',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              // Masukkan Pesanan
              _buildMenuCard(
                icon: Icons.point_of_sale_rounded,
                title: 'Masukkan Pesanan',
                subtitle: 'Buat pesanan baru (Dine-In / Take-Away)',
                color: AppColors.primary,
                onTap: () => Get.toNamed(AppRoutes.orderType),
              ),
              const SizedBox(height: 12),
              Obx(() => _buildMenuCard(
                icon: Icons.soup_kitchen_rounded,
                title: 'Sistem Dapur',
                subtitle: 'Display pesanan untuk dapur & monitoring produksi',
                color: Colors.deepOrange.shade600,
                badgeCount: _kitchenCtrl.pendingOrders.length,
                onTap: () => Get.toNamed(AppRoutes.kitchen),
              )),
              const SizedBox(height: 12),
              Obx(() => _buildMenuCard(
                icon: Icons.receipt_long_rounded,
                title: 'Pesanan Aktif',
                subtitle: 'Lihat dan kelola pesanan yang sedang diproses',
                color: Colors.purple.shade600,
                badgeCount: _homeCtrl.activeOrderCount.value,
                onTap: () => Get.toNamed(AppRoutes.activeOrders),
              )),
              const SizedBox(height: 12),
              Obx(() => _buildMenuCard(
                icon: Icons.pause_circle_outline_rounded,
                title: 'Transaksi Tertunda',
                subtitle: 'Lanjutkan transaksi yang ditunda sebelumnya',
                color: Colors.amber.shade700,
                badgeCount: _orderCtrl.parkedCount.value,
                onTap: () => Get.toNamed(AppRoutes.parkedOrders),
              )),
              const SizedBox(height: 12),
              Obx(() => _buildMenuCard(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Daftar Hutang',
                subtitle: 'Kelola piutang dan catat pembayaran hutang',
                color: Colors.orange.shade700,
                badgeCount: _debtCtrl.unpaidCount.value,
                onTap: () => Get.toNamed(AppRoutes.debtList),
              )),
              const SizedBox(height: 12),
              // Riwayat Transaksi
              _buildMenuCard(
                icon: Icons.history_rounded,
                title: 'Riwayat Transaksi',
                subtitle: 'Lihat semua transaksi yang telah selesai',
                color: AppColors.accent,
                onTap: () => Get.toNamed(AppRoutes.history),
              ),
              const SizedBox(height: 12),
              // Manajemen Shift
              _buildMenuCard(
                icon: Icons.schedule_rounded,
                title: 'Manajemen Shift',
                subtitle: 'Buka/Tutup shift dan lihat laporan shifts',
                color: AppColors.success,
                onTap: () => Get.toNamed(AppRoutes.shiftReport),
              ),
              const SizedBox(height: 24),
              const Text(
                'Quick Stats',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Obx(() => _buildStatCard(
                      icon: Icons.receipt_long_rounded,
                      label: 'Transaksi Hari Ini',
                      value: _homeCtrl.totalTransactionsToday.value.toString(),
                      color: AppColors.accent,
                    )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() => _buildStatCard(
                      icon: Icons.shopping_cart_rounded,
                      label: 'Pesanan Aktif',
                      value: _homeCtrl.activeOrderCount.value.toString(),
                      color: Colors.purple,
                    )),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ],
          border: Border.all(
            color: color.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            // Badge count
            if (badgeCount != null && badgeCount > 0)
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
