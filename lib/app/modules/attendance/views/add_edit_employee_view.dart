import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/constants/app_colors.dart';

/// Halaman ini tidak lagi digunakan — pengelolaan pengguna dilakukan
/// melalui menu Settings > Manajemen Pengguna.
class AddEditEmployeeView extends StatelessWidget {
  const AddEditEmployeeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Karyawan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.manage_accounts_rounded,
                  size: 72,
                  color: AppColors.textSecondary.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              const Text(
                'Kelola pengguna melalui Settings',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Kembali'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
