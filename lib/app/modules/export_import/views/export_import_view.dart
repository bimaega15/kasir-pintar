import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/export_import_controller.dart';
import '../../../utils/constants/app_colors.dart';

class ExportImportView extends GetView<ExportImportController> {
  const ExportImportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ekspor / Impor Data'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  controller.loadingMessage.value,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              _buildInfoBanner(),
              const SizedBox(height: 20),

              // Ekspor
              _buildSectionTitle(
                  Icons.upload_rounded, 'Ekspor Data', Colors.teal),
              const SizedBox(height: 12),
              _buildExportCard(
                icon: '📦',
                title: 'Produk',
                subtitle: 'Ekspor semua data produk ke Excel',
                onExport: controller.exportProducts,
              ),
              _buildExportCard(
                icon: '🏷️',
                title: 'Kategori',
                subtitle: 'Ekspor semua kategori produk',
                onExport: controller.exportCategories,
              ),
              _buildExportCard(
                icon: '👤',
                title: 'Pelanggan',
                subtitle: 'Ekspor semua data pelanggan',
                onExport: controller.exportCustomers,
              ),
              _buildExportCard(
                icon: '🌾',
                title: 'Bahan Baku',
                subtitle: 'Ekspor semua data bahan baku',
                onExport: controller.exportBahanBaku,
              ),
              _buildExportCard(
                icon: '🧾',
                title: 'Riwayat Transaksi',
                subtitle: 'Ekspor seluruh riwayat transaksi (read-only)',
                onExport: controller.exportTransactions,
              ),

              const SizedBox(height: 24),

              // Impor
              _buildSectionTitle(
                  Icons.download_rounded, 'Impor Data', Colors.orange),
              const SizedBox(height: 4),
              const Text(
                'ID kosong = tambah baru · ID terisi = perbarui data',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              _buildImportCard(
                icon: '📦',
                title: 'Produk',
                subtitle: 'Impor dari file Excel (.xlsx)',
                onImport: controller.importProducts,
                onTemplate: () => controller.downloadTemplate('produk'),
              ),
              _buildImportCard(
                icon: '🏷️',
                title: 'Kategori',
                subtitle: 'Impor dari file Excel (.xlsx)',
                onImport: controller.importCategories,
                onTemplate: () => controller.downloadTemplate('kategori'),
              ),
              _buildImportCard(
                icon: '👤',
                title: 'Pelanggan',
                subtitle: 'Impor dari file Excel (.xlsx)',
                onImport: controller.importCustomers,
                onTemplate: () => controller.downloadTemplate('pelanggan'),
              ),
              _buildImportCard(
                icon: '🌾',
                title: 'Bahan Baku',
                subtitle: 'Impor dari file Excel (.xlsx)',
                onImport: controller.importBahanBaku,
                onTemplate: () => controller.downloadTemplate('bahan_baku'),
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              color: AppColors.primary, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'File Excel diekspor dalam format .xlsx. Untuk impor, '
              'gunakan file hasil ekspor atau unduh template terlebih dahulu.',
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildExportCard({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onExport,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 4,
              offset: Offset(0, 2))
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.teal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(icon, style: const TextStyle(fontSize: 22)),
          ),
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
        trailing: ElevatedButton.icon(
          onPressed: onExport,
          icon: const Icon(Icons.upload_rounded, size: 16),
          label: const Text('Ekspor'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            textStyle: const TextStyle(fontSize: 12),
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      ),
    );
  }

  Widget _buildImportCard({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onImport,
    required VoidCallback onTemplate,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 4,
              offset: Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: onImport,
                  icon: const Icon(Icons.download_rounded, size: 14),
                  label: const Text('Impor'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    textStyle: const TextStyle(fontSize: 11),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: onTemplate,
                  child: const Text(
                    'Unduh template',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
