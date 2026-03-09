import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/constants/app_colors.dart';
import '../controllers/stock_controller.dart';

class StockOpnameView extends GetView<StockController> {
  const StockOpnameView({super.key});

  @override
  Widget build(BuildContext context) {
    final dtFormatter = DateFormat('dd MMM yyyy HH:mm', 'id_ID');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Stok Opname'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final opnames = controller.opnames;
        if (opnames.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fact_check_outlined,
                    size: 64,
                    color: AppColors.textSecondary.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                const Text('Belum ada riwayat opname',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 14)),
                const SizedBox(height: 8),
                const Text('Tekan tombol + untuk membuat opname baru',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.loadOpnames,
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: opnames.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final opname = opnames[i];
              final isDraft = opname.status == 'draft';
              final statusColor =
                  isDraft ? Colors.orange.shade700 : Colors.green.shade700;
              final statusLabel = isDraft ? 'Draft' : 'Selesai';

              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: isDraft
                          ? Colors.orange.withValues(alpha: 0.3)
                          : AppColors.divider),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    await controller.openOpname(opname);
                    Get.toNamed(AppRoutes.stockOpnameDetail,
                        arguments: opname);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isDraft
                                ? Icons.edit_note_rounded
                                : Icons.check_circle_outline_rounded,
                            color: statusColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          statusColor.withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      statusLabel,
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: statusColor),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${opname.itemsCount} produk',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dtFormatter.format(opname.createdAt),
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                              ),
                              if (opname.notes.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  opname.notes,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (!isDraft && opname.completedAt != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Selesai: ${dtFormatter.format(opname.completedAt!)}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green.shade700),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (isDraft) ...[
                          const Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: AppColors.textSecondary),
                        ] else ...[
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: AppColors.error, size: 20),
                            onPressed: () =>
                                _confirmDelete(context, opname.id),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewOpnameDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showNewOpnameDialog(BuildContext context) {
    final notesCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Buat Opname Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Semua produk akan dicatat dengan stok sistem saat ini.',
              style:
                  TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: notesCtrl,
              decoration: InputDecoration(
                labelText: 'Catatan (opsional)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            onPressed: () async {
              Get.back();
              await controller.createNewOpname(notesCtrl.text.trim());
              final opname = controller.activeOpname.value;
              if (opname != null) {
                Get.toNamed(AppRoutes.stockOpnameDetail, arguments: opname);
              }
            },
            child: const Text('Buat'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String opnameId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Opname'),
        content: const Text(
            'Opname yang sudah selesai akan dihapus. Lanjutkan?'),
        actions: [
          TextButton(
              onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            onPressed: () async {
              Get.back();
              await controller.deleteOpname(opnameId);
              Get.snackbar('Berhasil', 'Opname berhasil dihapus',
                  snackPosition: SnackPosition.BOTTOM);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
