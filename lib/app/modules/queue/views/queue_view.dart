import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/queue_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../services/printer_service.dart';
import '../../../utils/constants/app_colors.dart';

class QueueView extends GetView<QueueController> {
  const QueueView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cetak Nomor Antrian'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: 'Pengaturan Printer',
            onPressed: () => Get.toNamed(AppRoutes.printerSettings),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status printer
          _buildPrinterStatus(),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Label
                    const Text(
                      'Nomor Antrian Berikutnya',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Kotak nomor besar
                    Obx(() => Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.cardShadow,
                                blurRadius: 16,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: controller.isLoading.value
                                ? const CircularProgressIndicator()
                                : Text(
                                    (controller.currentNumber.value)
                                        .toString()
                                        .padLeft(3, '0'),
                                    style: const TextStyle(
                                      fontSize: 80,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                      letterSpacing: 4,
                                    ),
                                  ),
                          ),
                        )),

                    const SizedBox(height: 12),
                    const Text(
                      'Nomor antrian saat ini',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Tombol ambil & cetak antrian
                    Obx(() => SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: controller.isLoading.value
                                ? null
                                : controller.nextAndPrint,
                            icon: const Icon(Icons.print_rounded, size: 22),
                            label: const Text(
                              'Ambil & Cetak Antrian',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  AppColors.primary.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 2,
                            ),
                          ),
                        )),

                    const SizedBox(height: 16),

                    // Tombol reset
                    TextButton.icon(
                      onPressed: () => _confirmReset(context),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Reset Antrian Hari Ini'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Info reset otomatis
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14, color: AppColors.textSecondary.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                Text(
                  'Nomor antrian reset otomatis setiap hari',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrinterStatus() {
    if (!Get.isRegistered<PrinterService>()) return const SizedBox.shrink();
    final printerService = Get.find<PrinterService>();

    return Obx(() {
      final connected = printerService.isConnected.value;
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: connected
              ? AppColors.success.withValues(alpha: 0.1)
              : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: connected
                ? AppColors.success.withValues(alpha: 0.3)
                : Colors.orange.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              connected
                  ? Icons.bluetooth_connected_rounded
                  : Icons.bluetooth_disabled_rounded,
              size: 16,
              color: connected ? AppColors.success : Colors.orange.shade700,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                connected
                    ? 'Printer terhubung: ${printerService.connectedDeviceName.value}'
                    : 'Printer belum terhubung — nomor akan tetap tersimpan',
                style: TextStyle(
                  fontSize: 12,
                  color: connected
                      ? AppColors.success
                      : Colors.orange.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (!connected)
              GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.printerSettings),
                child: Text(
                  'Hubungkan',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Antrian'),
        content: const Text(
          'Yakin ingin me-reset nomor antrian hari ini ke 0?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.resetQueue();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
