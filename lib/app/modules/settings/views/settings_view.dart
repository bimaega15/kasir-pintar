import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../../../services/user_session.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/responsive/responsive_helper.dart';
import '../../../routes/app_routes.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            tooltip: 'Simpan',
            onPressed: controller.saveSettings,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: Res.padding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Menu Cards
              const Text(
                'Konfigurasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              // Pengaturan Toko — admin only
              if (Get.find<UserSession>().isAdmin) ...[
                _buildMenuCard(
                  icon: Icons.tune_rounded,
                  title: 'Pengaturan Toko',
                  subtitle: 'Kelola nama toko, pajak, dan biaya layanan',
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),
              ],
              // Printer
              _buildMenuCard(
                icon: Icons.print_rounded,
                title: 'Printer Thermal',
                subtitle: 'Konfigurasi printer dan pengaturan cetak',
                color: Colors.purple,
                onTap: () => Get.toNamed(AppRoutes.printerSettings),
              ),
              const SizedBox(height: 12),
              // Pembaruan Aplikasi
              _buildMenuCard(
                icon: Icons.system_update_rounded,
                title: 'Pembaruan Aplikasi',
                subtitle: 'Cek dan unduh versi terbaru',
                color: Colors.green,
                onTap: () => controller.checkForUpdates(),
              ),
              const SizedBox(height: 12),
              // Ekspor / Impor — admin only
              if (Get.find<UserSession>().isAdmin)
                _buildMenuCard(
                  icon: Icons.import_export_rounded,
                  title: 'Ekspor / Impor Data',
                  subtitle: 'Backup dan restore data via file Excel (.xlsx)',
                  color: Colors.teal,
                  onTap: () => Get.toNamed(AppRoutes.exportImport),
                ),
              const SizedBox(height: 12),
              // Tentang Aplikasi
              _buildMenuCard(
                icon: Icons.info_outline_rounded,
                title: 'Tentang Aplikasi',
                subtitle: 'Info pembuat, versi, dan kontak developer',
                color: Colors.indigo,
                onTap: () => Get.toNamed(AppRoutes.about),
              ),
              const SizedBox(height: 12),
              // SQL Backup — admin only
              if (Get.find<UserSession>().isAdmin) ...[
                _buildMenuCard(
                  icon: Icons.upload_rounded,
                  title: 'Export Database (SQL)',
                  subtitle: 'Backup seluruh data ke file .sql dan bagikan',
                  color: Colors.teal,
                  onTap: () => controller.exportSqlBackup(),
                ),
                const SizedBox(height: 12),
                _buildMenuCard(
                  icon: Icons.download_rounded,
                  title: 'Import Database (SQL)',
                  subtitle: 'Restore seluruh data dari file .sql backup',
                  color: Colors.deepOrange,
                  onTap: () => controller.importSqlBackup(),
                ),
                const SizedBox(height: 12),
              ],
              // Seed Data — admin only
              if (Get.find<UserSession>().isAdmin) ...[
                _buildMenuCard(
                  icon: Icons.restore_rounded,
                  title: 'Isi Data Menu Mie Gacor',
                  subtitle: 'Hapus semua produk & kategori, isi ulang dengan menu Mie Gacor',
                  color: Colors.orange,
                  onTap: () => controller.seedMieGacorData(),
                ),
                const SizedBox(height: 12),
                _buildMenuCard(
                  icon: Icons.delete_forever_rounded,
                  title: 'Reset Semua Data',
                  subtitle: 'Hapus seluruh data transaksi, produk, dan operasional',
                  color: Colors.red,
                  onTap: () => controller.resetAllData(),
                ),
              ],
              const SizedBox(height: 24),
              // Form Settings — admin only
              if (Get.find<UserSession>().isAdmin) ...[
              const Divider(),
              const SizedBox(height: 16),
              _section(
                title: 'Informasi Toko',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo upload
                    const Text(
                      'Logo Toko',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Obx(() {
                      final path = controller.logoPath.value;
                      return Row(
                        children: [
                          // Preview
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.textSecondary
                                      .withValues(alpha: 0.2)),
                            ),
                            child: path.isNotEmpty && File(path).existsSync()
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      File(path),
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(Icons.store_rounded,
                                    size: 36,
                                    color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: controller.pickLogo,
                                    icon: const Icon(Icons.upload_rounded,
                                        size: 16),
                                    label: Text(path.isNotEmpty
                                        ? 'Ganti Logo'
                                        : 'Upload Logo'),
                                    style: ElevatedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                    ),
                                  ),
                                ),
                                if (path.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: controller.clearLogo,
                                      icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 16),
                                      label: const Text('Hapus Logo'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.error,
                                        side: const BorderSide(
                                            color: AppColors.error),
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller.storeNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Toko',
                        prefixIcon: Icon(Icons.store_rounded),
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller.storeAddressController,
                      decoration: const InputDecoration(
                        labelText: 'Alamat Toko',
                        prefixIcon: Icon(Icons.location_on_rounded),
                        border: OutlineInputBorder(),
                        hintText: 'Jl. Contoh No. 1, Kota',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller.storeFooterController,
                      decoration: const InputDecoration(
                        labelText: 'Catatan Kaki Struk',
                        prefixIcon: Icon(Icons.notes_rounded),
                        border: OutlineInputBorder(),
                        hintText:
                            'Contoh: Instagram: @tokoku | Promo setiap Jumat!',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        helperText: 'Tampil di bagian bawah struk (opsional)',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _section(
                title: 'Pajak & Biaya Layanan',
                child: Column(
                  children: [
                    TextField(
                      controller: controller.taxController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Pajak (%)',
                        hintText: '0',
                        prefixIcon: Icon(Icons.percent_rounded),
                        suffixText: '%',
                        border: OutlineInputBorder(),
                        helperText: 'Masukkan 0 untuk menonaktifkan pajak',
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller.serviceChargeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Service Charge (%)',
                        hintText: '0',
                        prefixIcon: Icon(Icons.room_service_rounded),
                        suffixText: '%',
                        border: OutlineInputBorder(),
                        helperText: 'Masukkan 0 untuk menonaktifkan service charge',
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: controller.saveSettings,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Simpan Pengaturan'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ], // end admin-only form section
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Akun',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout_rounded, color: Colors.red),
                  label: const Text(
                    'Keluar / Logout',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Keluar'),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: AppColors.cardShadow, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
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
            if (onTap != null)
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
}
