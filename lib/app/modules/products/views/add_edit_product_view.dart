import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/products_controller.dart';
import '../../../data/models/category_model.dart';
import '../../../utils/constants/app_colors.dart';

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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

  Widget _buildCategoryDropdown() {
    final cats = CategoryModel.defaultCategories
        .where((c) => c.id != 'all')
        .toList();
    return Obx(() => InputDecorator(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.category_outlined),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
          child: DropdownButton<String>(
            value: controller.selectedCategoryId.value,
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
        ));
  }
}
