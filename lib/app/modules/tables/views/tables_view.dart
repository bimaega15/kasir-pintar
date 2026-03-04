import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/table_model.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/constants/app_colors.dart';
import '../controllers/tables_controller.dart';

class TablesView extends GetView<TablesController> {
  const TablesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manajemen Meja'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadTables,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          controller.prepareAdd();
          Get.toNamed(AppRoutes.addEditTable);
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah Meja'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.tables.isEmpty) {
          return const Center(
            child: Text('Belum ada meja',
                style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        return Column(
          children: [
            _buildLegend(),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: controller.tables.length,
                itemBuilder: (_, i) => _buildTableCard(controller.tables[i]),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _legendDot(Colors.green.shade400, 'Tersedia'),
          const SizedBox(width: 16),
          _legendDot(Colors.red.shade400, 'Terisi'),
          const SizedBox(width: 16),
          _legendDot(Colors.orange.shade400, 'Reservasi'),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(children: [
      Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    ]);
  }

  Widget _buildTableCard(TableModel table) {
    Color cardColor;
    Color textColor;
    IconData statusIcon;

    switch (table.status) {
      case TableStatus.occupied:
        cardColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        statusIcon = Icons.person_rounded;
        break;
      case TableStatus.reserved:
        cardColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        statusIcon = Icons.event_rounded;
        break;
      case TableStatus.available:
        cardColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        statusIcon = Icons.check_circle_rounded;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onLongPress: () => _showTableActions(table),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: textColor.withValues(alpha: 0.3)),
            boxShadow: const [
              BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 4,
                  offset: Offset(0, 2))
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.table_restaurant_rounded, color: textColor, size: 32),
              const SizedBox(height: 8),
              Text(
                'Meja ${table.number}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: textColor),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(statusIcon, size: 12, color: textColor),
                  const SizedBox(width: 3),
                  Text(table.statusLabel,
                      style: TextStyle(fontSize: 11, color: textColor)),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${table.capacity} kursi',
                style: TextStyle(
                    fontSize: 11,
                    color: textColor.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTableActions(TableModel table) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Meja ${table.number}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: AppColors.primary),
              title: const Text('Edit Meja'),
              onTap: () {
                Navigator.pop(Get.context!);
                controller.prepareEdit(table);
                Get.toNamed(AppRoutes.addEditTable);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_rounded, color: AppColors.error),
              title: const Text('Hapus Meja',
                  style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(Get.context!);
                controller.deleteTable(table);
              },
            ),
          ],
        ),
      ),
      isDismissible: true,
      enableDrag: true,
    );
  }
}
