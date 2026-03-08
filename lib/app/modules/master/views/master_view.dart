import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/constants/app_colors.dart';
import '../../categories/controllers/categories_controller.dart';
import '../../products/controllers/products_controller.dart';
import '../../tables/controllers/tables_controller.dart';

class MasterPageContent extends StatelessWidget {
  const MasterPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Master Data'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kelola Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            // Produk Menu
            _buildMenuCard(
              icon: Icons.inventory_2_rounded,
              title: 'Produk',
              subtitle: 'Kelola daftar produk, harga, dan stok',
              color: AppColors.accent,
              onTap: () => Get.toNamed(AppRoutes.products),
              actionButton: ElevatedButton.icon(
                onPressed: () {
                  // Ensure controller is registered
                  if (!Get.isRegistered<ProductsController>()) {
                    Get.put(ProductsController());
                  }
                  final ctrl = Get.find<ProductsController>();
                  ctrl.prepareAdd();
                  Get.toNamed(AppRoutes.addEditProduct);
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Tambah Produk'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  minimumSize: const Size.fromHeight(36),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildMenuCard(
              icon: Icons.category_rounded,
              title: 'Kategori Produk',
              subtitle: 'Kelola kategori untuk mengorganisir produk',
              color: Colors.purple.shade600,
              onTap: () => Get.toNamed(AppRoutes.categories),
              actionButton: ElevatedButton.icon(
                onPressed: () {
                  if (!Get.isRegistered<CategoriesController>()) {
                    Get.put(CategoriesController());
                  }
                  final ctrl = Get.find<CategoriesController>();
                  ctrl.prepareAdd();
                  Get.toNamed(AppRoutes.addEditCategory);
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Tambah Kategori'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  minimumSize: const Size.fromHeight(36),
                ),
              ),
            ),
            Column(
              children: [
                const SizedBox(height: 16),
                _buildMenuCard(
                    icon: Icons.table_restaurant_rounded,
                    title: 'Meja Restoran',
                    subtitle: 'Kelola meja, nomor, dan kapasitas',
                    color: Colors.teal.shade600,
                    onTap: () => Get.toNamed(AppRoutes.tables),
                    actionButton: ElevatedButton.icon(
                      onPressed: () {
                        if (!Get.isRegistered<TablesController>()) {
                          Get.put(TablesController());
                        }
                        final ctrl = Get.find<TablesController>();
                        ctrl.prepareAdd();
                        Get.toNamed(AppRoutes.addEditTable);
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Tambah Meja'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        minimumSize: const Size.fromHeight(36),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.primaryLight.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tip Manajemen',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Perbarui data produk dan meja secara berkala untuk memastikan informasi selalu akurat.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
    required Widget actionButton,
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
        child: Column(
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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: actionButton,
            ),
          ],
        ),
      ),
    );
  }
}
