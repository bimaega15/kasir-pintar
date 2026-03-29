import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/products_controller.dart';
import '../../../data/models/product_model.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/responsive/responsive_helper.dart';

class AddEditProductView extends GetView<ProductsController> {
  const AddEditProductView({super.key});

  static const _emojis = [
    '📦', '🍔', '🍟', '🍕', '🌮', '🌯', '🥙', '🧆', '🥚', '🍳',
    '🥞', '🧇', '🥓', '🍗', '🍖', '🦴', '🌭', '🥪', '🥗', '🍜',
    '🍝', '🍛', '🍲', '🥣', '🍱', '🍣', '🍤', '🍙', '🍚', '🍘',
    '☕', '🧋', '🍵', '🧃', '🥤', '🍺', '🍹', '🍊', '🥑', '🍌',
    '🍿', '🥔', '🧁', '🍰', '🎂', '🍩', '🍪', '🍫', '🍬', '🧻',
  ];

  @override
  Widget build(BuildContext context) {
    final isEditing = controller.editingProduct != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Produk' : 'Tambah Produk'),
        actions: [
          TextButton(
            onPressed: () async {
              await controller.saveProduct();
            },
            child: const Text('Simpan',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: Res.padding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo picker
            _sectionLabel('Foto Produk (opsional)'),
            const SizedBox(height: 8),
            _buildImagePicker(),
            const SizedBox(height: 20),

            // Emoji picker
            _sectionLabel('Ikon Produk'),
            const SizedBox(height: 8),
            _buildEmojiPicker(),
            const SizedBox(height: 20),

            // Name
            _sectionLabel('Nama Produk *'),
            const SizedBox(height: 8),
            TextField(
              controller: controller.nameController,
              decoration: const InputDecoration(
                hintText: 'Contoh: Nasi Goreng',
                prefixIcon: Icon(Icons.label_outline),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Category
            _sectionLabel('Kategori'),
            const SizedBox(height: 8),
            _buildCategoryDropdown(),
            const SizedBox(height: 16),

            // Price & Stock
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Harga (Rp) *'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: controller.priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '0',
                          prefixText: 'Rp ',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Stok'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: controller.stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '0',
                          prefixIcon: Icon(Icons.inventory_2_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            _sectionLabel('Deskripsi (opsional)'),
            const SizedBox(height: 8),
            TextField(
              controller: controller.descController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Deskripsi singkat produk...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),

            // Package toggle
            _buildPackageToggle(),
            const SizedBox(height: 16),

            // Package items (shown only when isPackage = true)
            Obx(() => controller.isPackage.value
                ? _buildPackageItemsSection()
                : const SizedBox.shrink()),

            // Price Levels
            _buildPriceLevelsSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      );

  Widget _buildImagePicker() {
    return Obx(() {
      final path = controller.selectedImagePath.value;
      final hasImage = path != null && File(path).existsSync();
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: hasImage
            ? Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(path),
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => controller.pickImage(),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Ganti Foto'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => controller.removeImage(),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Hapus Foto'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : GestureDetector(
                onTap: () => controller.pickImage(),
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.divider,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_a_photo_rounded,
                            size: 36, color: AppColors.textSecondary),
                        SizedBox(height: 8),
                        Text(
                          'Tap untuk pilih foto',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Jika tidak ada foto, ikon emoji akan digunakan',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      );
    });
  }

  Widget _buildEmojiPicker() {
    return Obx(() => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              // Selected emoji preview
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(controller.selectedEmoji.value,
                          style: const TextStyle(fontSize: 36)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Pilih ikon untuk produk',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _emojis.map((emoji) {
                  final selected = controller.selectedEmoji.value == emoji;
                  return GestureDetector(
                    onTap: () => controller.selectedEmoji.value = emoji,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                          child: Text(emoji,
                              style: const TextStyle(fontSize: 20))),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ));
  }

  Widget _buildPriceLevelsSection() {
    return Obx(() {
      final nonDefaultLevels =
          controller.availablePriceLevels.where((l) => !l.isDefault).toList();
      if (nonDefaultLevels.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Harga Level Lainnya (opsional)'),
          const SizedBox(height: 4),
          Text(
            'Kosongkan jika sama dengan Harga (Rp) di atas',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 10),
          ...nonDefaultLevels.map((level) {
            final ctrl = controller.levelPriceControllers[level.id];
            if (ctrl == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Harga ${level.name}',
                  hintText: '0',
                  prefixText: 'Rp ',
                  prefixIcon: const Icon(Icons.sell_outlined),
                ),
              ),
            );
          }),
        ],
      );
    });
  }

  Widget _buildPackageToggle() {
    return Obx(() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              const Icon(Icons.inventory_2_outlined, color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Produk Paket', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('Berisi kumpulan beberapa produk',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Switch(
                value: controller.isPackage.value,
                activeThumbColor: AppColors.primary,
                onChanged: (val) {
                  controller.isPackage.value = val;
                  if (!val) controller.packageItems.clear();
                },
              ),
            ],
          ),
        ));
  }

  Widget _buildPackageItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Item dalam Paket *'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              Obx(() {
                if (controller.packageItems.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Belum ada item. Tap "+ Tambah Item" untuk menambah produk ke paket.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.packageItems.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (_, i) {
                    final item = controller.packageItems[i];
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Text(item.productEmoji,
                          style: const TextStyle(fontSize: 24)),
                      title: Text(item.productName,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 20),
                            onPressed: () => controller.updatePackageItemQty(
                                item.productId, item.quantity - 1),
                          ),
                          SizedBox(
                            width: 28,
                            child: Text(
                              '${item.quantity}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 20),
                            onPressed: () => controller.updatePackageItemQty(
                                item.productId, item.quantity + 1),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 20, color: AppColors.error),
                            onPressed: () =>
                                controller.removePackageItem(item.productId),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
              const Divider(height: 1),
              TextButton.icon(
                onPressed: () => _showProductPickerDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Item'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showProductPickerDialog() {
    // Exclude the product being edited (can't add itself) and already-added items
    final currentId = controller.editingProduct?.id;
    final addedIds =
        controller.packageItems.map((i) => i.productId).toSet();
    final available = controller.products
        .where((p) => !p.isPackage && p.id != currentId && !addedIds.contains(p.id))
        .toList();

    Get.dialog(
      AlertDialog(
        title: const Text('Pilih Produk'),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: SizedBox(
          width: double.maxFinite,
          child: available.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Tidak ada produk tersedia.'),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: available.length,
                  itemBuilder: (_, i) {
                    final p = available[i];
                    return ListTile(
                      leading: Text(p.emoji,
                          style: const TextStyle(fontSize: 22)),
                      title: Text(p.name),
                      subtitle: Text(
                          'Rp ${p.price.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 12)),
                      onTap: () {
                        controller.addPackageItem(p);
                        Get.back();
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(), child: const Text('Batal')),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Obx(() {
      final cats = controller.formCategories;
      final currentId = controller.selectedCategoryId.value;
      // Ensure value is valid in current list; fallback to first
      final validId = cats.any((c) => c.id == currentId)
          ? currentId
          : (cats.isNotEmpty ? cats.first.id : currentId);
      return InputDecorator(
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.category_outlined),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
        child: DropdownButton<String>(
          value: validId,
          isExpanded: true,
          underline: const SizedBox(),
          items: cats
              .map((cat) => DropdownMenuItem(
                    value: cat.id,
                    child: Text('${cat.icon} ${cat.name}'),
                  ))
              .toList(),
          onChanged: (val) {
            if (val != null) controller.selectedCategoryId.value = val;
          },
        ),
      );
    });
  }
}
