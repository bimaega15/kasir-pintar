import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/main_navigation_controller.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../home/views/home_view.dart';
import '../../home/controllers/home_controller.dart';
import '../../settings/views/settings_view.dart';
import '../../settings/controllers/settings_controller.dart';
import '../../../modules/master/views/master_view.dart';
import '../../../modules/report/views/report_view.dart';

class MainNavigationView extends GetView<MainNavigationController> {
  const MainNavigationView({super.key});

  @override
  String? get tag => MainNavigationController.TAG;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            IndexedStack(
              index: controller.currentIndex.value,
              children: _buildPages(),
            ),
            // Spacer at bottom to prevent content overlap with navbar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 120,
                color: Colors.transparent,
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildCustomBottomBar(),
        floatingActionButton: _buildKasirButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      );
    });
  }

  List<Widget> _buildPages() {
    return [
      // Home Page
      GetBuilder<HomeController>(
        builder: (controller) {
          return const HomeView();
        },
      ),
      // Master Page
      const MasterPageContent(),
      // Report Page
      const ReportPageContent(),
      // Settings Page
      GetBuilder<SettingsController>(
        builder: (controller) {
          return const SettingsView();
        },
      ),
      // Kasir Page
      const KasirPageContent(),
    ];
  }

  Widget _buildCustomBottomBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: controller.currentIndex.value == 4 ? 0 : controller.currentIndex.value,
        onTap: (index) {
          if (index >= 4) {
            controller.changeIndex(4);
          } else {
            controller.changeIndex(index);
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
        ),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded, size: 24),
            activeIcon: Icon(Icons.home_rounded, size: 28),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_rounded, size: 24),
            activeIcon: Icon(Icons.inventory_2_rounded, size: 28),
            label: 'Master',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment_rounded, size: 24),
            activeIcon: Icon(Icons.assessment_rounded, size: 28),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded, size: 24),
            activeIcon: Icon(Icons.settings_rounded, size: 28),
            label: 'Setting',
          ),
        ],
      ),
    );
  }

  Widget _buildKasirButton() {
    return GestureDetector(
      onTap: () => controller.changeIndex(4),
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(27.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Obx(() => Icon(
            Icons.point_of_sale_rounded,
            color: Colors.white,
            size: controller.currentIndex.value == 4 ? 24 : 20,
          )),
        ),
      ),
    );
  }
}

// ============================================================================
// Kasir Page Content Widget
// ============================================================================

class KasirPageContent extends StatelessWidget {
  const KasirPageContent({super.key});

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
              subtitle: 'Buat pesanan baru (Dine-In / Take-Away / Retail)',
              color: AppColors.primary,
              onTap: () => Get.toNamed(AppRoutes.orderType),
            ),
            const SizedBox(height: 12),
            // Dapur / Kitchen
            _buildMenuCard(
              icon: Icons.soup_kitchen_rounded,
              title: 'Sistem Dapur',
              subtitle: 'Display pesanan untuk dapur & monitoring produksi',
              color: Colors.deepOrange.shade600,
              onTap: () => Get.toNamed(AppRoutes.kitchen),
            ),
            const SizedBox(height: 12),
            // Pesanan Aktif
            _buildMenuCard(
              icon: Icons.receipt_long_rounded,
              title: 'Pesanan Aktif',
              subtitle: 'Lihat dan kelola pesanan yang sedang diproses',
              color: Colors.purple.shade600,
              onTap: () => Get.toNamed(AppRoutes.activeOrders),
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
                  child: _buildStatCard(
                    icon: Icons.shopping_cart_rounded,
                    label: 'Pesanan Aktif',
                    value: '5',
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.done_all_rounded,
                    label: 'Siap Diambil',
                    value: '3',
                    color: AppColors.success,
                  ),
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
        child: Row(
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
