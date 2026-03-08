import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/constants/app_colors.dart';
import '../controllers/categories_controller.dart';

class CategoriesView extends GetView<CategoriesController> {
  const CategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategori Produk'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          controller.prepareAdd();
          Get.toNamed(AppRoutes.addEditCategory);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Kategori'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.category_outlined,
                    size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                const SizedBox(height: 12),
                const Text(
                  'Belum ada kategori',
                  style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tambah kategori produk untuk mengorganisir menu',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          itemCount: controller.categories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final cat = controller.categories[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(cat.icon, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                title: Text(
                  cat.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: AppColors.primary, size: 20),
                      onPressed: () {
                        controller.prepareEdit(cat);
                        Get.toNamed(AppRoutes.addEditCategory);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: Colors.red.shade400, size: 20),
                      onPressed: () => controller.deleteCategory(cat),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
