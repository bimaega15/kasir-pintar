import 'dart:io';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/helpers/thermal_receipt_helper.dart';
import '../controllers/printer_controller.dart';

class PrinterSettingsView extends GetView<PrinterController> {
  const PrinterSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengaturan Printer'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: !Platform.isAndroid
          ? _buildNotSupported()
          : Column(
              children: [
                _buildStatusCard(),
                _buildActionsBar(),
                _buildPaperWidthSettings(),
                _buildCashDrawerSettings(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Perangkat Bluetooth Berpasangan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                Expanded(child: _buildDeviceList()),
              ],
            ),
    );
  }

  Widget _buildNotSupported() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.print_disabled_rounded,
              size: 72,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              'Printer Bluetooth hanya didukung di Android',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Obx(() {
      final connected = controller.isConnected.value;
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (connected ? AppColors.success : AppColors.textSecondary)
                    .withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                connected ? Icons.print_rounded : Icons.print_outlined,
                color: connected ? AppColors.success : AppColors.textSecondary,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    connected ? 'Terhubung' : 'Tidak Terhubung',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: connected
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    connected
                        ? controller.connectedDeviceName.value
                        : controller.savedName.value.isNotEmpty
                        ? 'Terakhir: ${controller.savedName.value}'
                        : 'Pilih printer dari daftar di bawah',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (connected)
              TextButton(
                onPressed: controller.disconnect,
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Putuskan'),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildActionsBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Obx(
              () => OutlinedButton.icon(
                onPressed: controller.isLoading.value
                    ? null
                    : controller.scanDevices,
                icon: controller.isLoading.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bluetooth_searching_rounded),
                label: Text(
                  controller.isLoading.value ? 'Memindai...' : 'Pindai Ulang',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(
              () => ElevatedButton.icon(
                onPressed: controller.isConnected.value
                    ? controller.testPrint
                    : null,
                icon: const Icon(Icons.receipt_long_rounded),
                label: const Text('Test Cetak'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade200,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashDrawerSettings() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row: enable toggle ──
            Obx(() => SwitchListTile.adaptive(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (controller.cashDrawerEnabled.value
                              ? AppColors.primary
                              : AppColors.textSecondary)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.point_of_sale_rounded,
                      color: controller.cashDrawerEnabled.value
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                  title: const Text(
                    'Laci Uang (Cash Drawer)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: const Text(
                    'Kirim perintah ESC/POS ke printer untuk membuka laci',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  value: controller.cashDrawerEnabled.value,
                  activeTrackColor: AppColors.primary,
                  onChanged: controller.setCashDrawerEnabled,
                )),
            // ── Sub-settings (visible only when enabled) ──
            Obx(() {
              if (!controller.cashDrawerEnabled.value) {
                return const SizedBox.shrink();
              }
              return Column(
                children: [
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  // Auto-open on Tunai toggle
                  SwitchListTile.adaptive(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    title: const Text(
                      'Buka otomatis saat pembayaran Tunai',
                      style: TextStyle(fontSize: 13),
                    ),
                    subtitle: const Text(
                      'Laci terbuka setelah transaksi tunai selesai',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    value: controller.cashDrawerAutoOpen.value,
                    activeTrackColor: AppColors.primary,
                    onChanged: controller.setCashDrawerAutoOpen,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  // Drawer pin selector
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Port Laci',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _drawerPinChip(
                                label: 'Laci 1 (Pin 2)',
                                pin: 0),
                            const SizedBox(width: 8),
                            _drawerPinChip(
                                label: 'Laci 2 (Pin 5)',
                                pin: 1),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  // Manual open button
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Obx(() => SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: controller.isConnected.value
                                ? controller.openCashDrawer
                                : null,
                            icon: const Icon(Icons.open_in_new_rounded, size: 18),
                            label: const Text('Buka Laci Sekarang'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 11),
                              disabledBackgroundColor: Colors.grey.shade200,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              textStyle: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        )),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _drawerPinChip({required String label, required int pin}) {
    return Obx(() {
      final selected = controller.cashDrawerPin.value == pin;
      return ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => controller.setCashDrawerPin(pin),
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        side: BorderSide(
          color: selected ? AppColors.primary : Colors.grey.shade300,
        ),
      );
    });
  }

  Widget _buildDeviceList() {
    return Obx(() {
      final list = controller.devices;
      if (list.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bluetooth_disabled_rounded,
                  size: 56,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Belum ada perangkat ditemukan.\nPastikan printer sudah dipasangkan di pengaturan Bluetooth Android, lalu tekan "Pindai Ulang".',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: list.length,
        itemBuilder: (_, i) => _buildDeviceTile(list[i]),
      );
    });
  }

  Widget _buildDeviceTile(BluetoothDevice device) {
    return Obx(() {
      final isActive =
          controller.isConnected.value &&
          controller.connectedDeviceName.value == (device.name ?? '');
      final isSaved = controller.savedMac.value == (device.address ?? '');

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppColors.success : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isActive ? AppColors.success : AppColors.primary)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.print_rounded,
              color: isActive ? AppColors.success : AppColors.primary,
              size: 22,
            ),
          ),
          title: Row(
            children: [
              Text(
                device.name ?? 'Unknown Device',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              if (isSaved) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Terakhir',
                    style: TextStyle(fontSize: 10, color: AppColors.accent),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(
            device.address ?? '',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          trailing: isActive
              ? const Icon(Icons.check_circle_rounded, color: AppColors.success)
              : Obx(
                  () => TextButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () => controller.connect(device),
                    child: const Text('Hubungkan'),
                  ),
                ),
        ),
      );
    });
  }

  Widget _buildPaperWidthSettings() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ukuran Kertas Thermal',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () => Row(
                children: PaperWidth.values
                    .map(
                      (width) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(
                              width.name == 'mm80' ? '80mm' : '58mm',
                              style: const TextStyle(fontSize: 12),
                            ),
                            selected:
                                controller.selectedPaperWidth.value == width,
                            onSelected: (selected) {
                              if (selected) controller.setPaperWidth(width);
                            },
                            selectedColor: AppColors.primary.withValues(
                              alpha: 0.3,
                            ),
                            side: BorderSide(
                              color:
                                  controller.selectedPaperWidth.value == width
                                  ? AppColors.primary
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
