import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../utils/constants/app_colors.dart';
import '../controllers/bahan_baku_controller.dart';

class AddEditBahanBakuView extends GetView<BahanBakuController> {
  const AddEditBahanBakuView({super.key});

  static const _emojiOptions = [
    '\u{1F4E6}', // 📦
    '\u{1F35C}', // 🍜
    '\u{1F95A}', // 🥚
    '\u{1F96C}', // 🥬
    '\u{1F357}', // 🍗
    '\u{1F969}', // 🥩
    '\u{1F9C2}', // 🧂
    '\u{1F962}', // 🥢
    '\u{1FAD8}', // 🫘
    '\u{1F9C5}', // 🧅
    '\u{1F336}', // 🌶
    '\u{1F9C4}', // 🧄
    '\u{1F95B}', // 🥛
    '\u{1F9C8}', // 🧈
    '\u{1F35A}', // 🍚
    '\u{1FAD2}', // 🫒
    '\u{1F345}', // 🍅
    '\u{1F955}', // 🥕
    '\u{1F33D}', // 🌽
    '\u{1F95C}', // 🥜
  ];

  static const _unitOptions = [
    'kg',
    'gram',
    'liter',
    'ml',
    'pcs',
    'butir',
    'bungkus',
    'botol',
    'sachet',
    'ikat',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(controller.isEditing
            ? 'Edit Bahan Baku'
            : 'Tambah Bahan Baku'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => controller.saveBahanBaku(),
            child: const Text('Simpan',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji picker
            const _SectionTitle(title: 'Ikon'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Obx(() => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _emojiOptions.map((emoji) {
                      final isSelected =
                          controller.selectedEmoji.value == emoji;
                      return GestureDetector(
                        onTap: () =>
                            controller.selectedEmoji.value = emoji,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: isSelected
                                ? Border.all(
                                    color: AppColors.primary, width: 2)
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(emoji,
                              style: const TextStyle(fontSize: 22)),
                        ),
                      );
                    }).toList(),
                  )),
            ),
            const SizedBox(height: 20),

            // Name
            const _SectionTitle(title: 'Nama Bahan Baku'),
            const SizedBox(height: 8),
            _StyledTextField(
              controller: controller.nameController,
              hint: 'Contoh: Mie Mentah, Telur, Kecap',
              icon: Icons.inventory_2_rounded,
            ),
            const SizedBox(height: 16),

            // Unit
            const _SectionTitle(title: 'Satuan'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Obx(() => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _unitOptions.map((unit) {
                      final isSelected =
                          controller.selectedUnit.value == unit;
                      return GestureDetector(
                        onTap: () {
                          controller.selectedUnit.value = unit;
                          controller.unitController.text = unit;
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: isSelected
                                ? Border.all(
                                    color: AppColors.primary, width: 1.5)
                                : Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            unit,
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  )),
            ),
            const SizedBox(height: 4),
            _StyledTextField(
              controller: controller.unitController,
              hint: 'Atau ketik satuan lain...',
              icon: Icons.straighten_rounded,
              onChanged: (v) => controller.selectedUnit.value = v,
            ),
            const SizedBox(height: 16),

            // Price per unit
            const _SectionTitle(title: 'Harga per Satuan (Rp)'),
            const SizedBox(height: 8),
            _StyledTextField(
              controller: controller.priceController,
              hint: '0',
              icon: Icons.payments_rounded,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              numericOnly: true,
            ),
            const SizedBox(height: 16),

            // Initial stock (only for add)
            if (!controller.isEditing) ...[
              const _SectionTitle(title: 'Stok Awal'),
              const SizedBox(height: 8),
              _StyledTextField(
                controller: controller.stockController,
                hint: '0',
                icon: Icons.inventory_rounded,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                numericOnly: true,
              ),
              const SizedBox(height: 16),
            ],

            // Min stock
            const _SectionTitle(title: 'Stok Minimum (Alert)'),
            const SizedBox(height: 8),
            _StyledTextField(
              controller: controller.minStockController,
              hint: '0',
              icon: Icons.warning_amber_rounded,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              numericOnly: true,
            ),
            const SizedBox(height: 16),

            // Notes
            const _SectionTitle(title: 'Catatan (Opsional)'),
            const SizedBox(height: 8),
            _StyledTextField(
              controller: controller.notesController,
              hint: 'Catatan tambahan...',
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => controller.saveBahanBaku(),
                icon: Icon(
                    controller.isEditing
                        ? Icons.save_rounded
                        : Icons.add_rounded),
                label: Text(
                    controller.isEditing
                        ? 'Simpan Perubahan'
                        : 'Tambah Bahan Baku'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final bool numericOnly;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.onChanged,
    this.numericOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      inputFormatters: numericOnly
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : null,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
