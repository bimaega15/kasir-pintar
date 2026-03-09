import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/constants/app_colors.dart';
import '../controllers/price_levels_controller.dart';

class PriceLevelsView extends GetView<PriceLevelsController> {
  const PriceLevelsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Level Harga Produk'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          controller.prepareAdd();
          Get.toNamed(AppRoutes.addEditPriceLevel);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Level'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.priceLevels.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.price_change_outlined,
                    size: 64,
                    color: AppColors.textSecondary.withValues(alpha: 0.4)),
                const SizedBox(height: 12),
                const Text('Belum ada level harga',
                    style: TextStyle(
                        fontSize: 16, color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        return Column(
          children: [
            // Info banner
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Level default digunakan di POS saat tidak ada level yang dipilih. '
                      'Ketuk bintang untuk mengubah default.',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                itemCount: controller.priceLevels.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final lvl = controller.priceLevels[i];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: lvl.isDefault
                          ? Border.all(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              width: 1.5)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: lvl.isDefault
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.price_change_rounded,
                          color: lvl.isDefault
                              ? AppColors.primary
                              : Colors.grey.shade500,
                          size: 22,
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(lvl.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
                          if (lvl.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('Default',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      subtitle: lvl.description.isNotEmpty
                          ? Text(lvl.description,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary))
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Set default
                          IconButton(
                            icon: Icon(
                              lvl.isDefault
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: lvl.isDefault
                                  ? Colors.amber.shade600
                                  : Colors.grey.shade400,
                              size: 22,
                            ),
                            tooltip: 'Jadikan Default',
                            onPressed: lvl.isDefault
                                ? null
                                : () => controller.setDefault(lvl),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                color: AppColors.primary, size: 20),
                            onPressed: () {
                              controller.prepareEdit(lvl);
                              Get.toNamed(AppRoutes.addEditPriceLevel);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline,
                                color: lvl.isDefault
                                    ? Colors.grey.shade300
                                    : Colors.red.shade400,
                                size: 20),
                            onPressed: lvl.isDefault
                                ? null
                                : () => controller.deletePriceLevel(lvl),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}
