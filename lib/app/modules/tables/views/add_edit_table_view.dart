import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/table_model.dart';
import '../../../utils/constants/app_colors.dart';
import '../controllers/tables_controller.dart';

class AddEditTableView extends GetView<TablesController> {
  const AddEditTableView({super.key});

  @override
  Widget build(BuildContext context) {
    final isEdit = controller.editingTable != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Meja' : 'Tambah Meja'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _card(
              child: Column(
                children: [
                  TextField(
                    controller: controller.numberController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Nomor Meja',
                      prefixIcon: Icon(Icons.table_restaurant_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller.capacityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Kapasitas (kursi)',
                      prefixIcon: Icon(Icons.people_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Obx(() => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Status Meja',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 10),
                          SegmentedButton<TableStatus>(
                            segments: TableStatus.values
                                .map((s) => ButtonSegment(
                                      value: s,
                                      label: Text(
                                          TableModel(number: 0, status: s)
                                              .statusLabel,
                                          style: const TextStyle(fontSize: 12)),
                                    ))
                                .toList(),
                            selected: {controller.selectedStatus.value},
                            onSelectionChanged: (v) =>
                                controller.selectedStatus.value = v.first,
                          ),
                        ],
                      )),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.saveTable,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Meja'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
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
        child: child,
      );
}
