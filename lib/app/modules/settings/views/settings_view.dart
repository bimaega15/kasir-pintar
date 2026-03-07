import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../../../utils/constants/app_colors.dart';
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
          padding: const EdgeInsets.all(16),
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
              // Pengaturan Toko
              _buildMenuCard(
                icon: Icons.tune_rounded,
                title: 'Pengaturan Toko',
                subtitle: 'Kelola nama toko, pajak, dan biaya layanan',
                color: Colors.blue,
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 24),
              // Form Settings
              const Divider(),
              const SizedBox(height: 16),
              _section(
                title: 'Informasi Toko',
                child: Column(
                  children: [
                    TextField(
                      controller: controller.storeNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Toko',
                        prefixIcon: Icon(Icons.store_rounded),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 16),
                    Obx(() => DropdownButtonFormField<String>(
                          initialValue: controller.selectedPosType.value,
                          decoration: const InputDecoration(
                            labelText: 'Jenis POS',
                            prefixIcon: Icon(Icons.storefront_rounded),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'restaurant', child: Text('POS Kasir Restaurant / Cafe')),
                            DropdownMenuItem(value: 'supermarket', child: Text('POS Kasir Supermarket')),
                            DropdownMenuItem(value: 'laundry', child: Text('POS Kasir Laundry')),
                          ],
                          onChanged: (val) {
                            if (val != null) controller.selectedPosType.value = val;
                          },
                        )),
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
