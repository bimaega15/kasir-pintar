import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../../../utils/constants/app_colors.dart';

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
              _section(
                title: 'Informasi Toko',
                child: TextField(
                  controller: controller.storeNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Toko',
                    prefixIcon: Icon(Icons.store_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _section(
                title: 'Pajak & Biaya Layanan',
                child: Column(
                  children: [
                    TextField(
                      controller: controller.taxController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Pajak (%)',
                        hintText: '0',
                        prefixIcon: Icon(Icons.percent_rounded),
                        suffixText: '%',
                        border: OutlineInputBorder(),
                        helperText: 'Masukkan 0 untuk menonaktifkan pajak',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller.serviceChargeController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Service Charge (%)',
                        hintText: '0',
                        prefixIcon: Icon(Icons.room_service_rounded),
                        suffixText: '%',
                        border: OutlineInputBorder(),
                        helperText:
                            'Masukkan 0 untuk menonaktifkan service charge',
                      ),
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
            ],
          ),
        );
      }),
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
}
