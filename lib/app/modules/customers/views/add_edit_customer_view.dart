import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/constants/app_colors.dart';
import '../controllers/customers_controller.dart';

class AddEditCustomerView extends GetView<CustomersController> {
  const AddEditCustomerView({super.key});

  @override
  Widget build(BuildContext context) {
    final isEditing = controller.editingCustomer != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Pelanggan' : 'Tambah Pelanggan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () async {
              final success = await controller.saveCustomer();
              if (success) Get.back();
            },
            child: const Text(
              'Simpan',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCard(
              children: [
                _buildField(
                  controller: controller.nameController,
                  label: 'Nama Pelanggan',
                  hint: 'Contoh: Budi Santoso',
                  icon: Icons.person_rounded,
                  isRequired: true,
                  textCapitalization: TextCapitalization.words,
                ),
                const Divider(height: 1),
                _buildField(
                  controller: controller.phoneController,
                  label: 'No. Telepon',
                  hint: 'Contoh: 08123456789',
                  icon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                ),
                const Divider(height: 1),
                _buildField(
                  controller: controller.addressController,
                  label: 'Alamat',
                  hint: 'Alamat lengkap pelanggan',
                  icon: Icons.location_on_rounded,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                ),
                const Divider(height: 1),
                _buildField(
                  controller: controller.notesController,
                  label: 'Catatan',
                  hint: 'Catatan tambahan (opsional)',
                  icon: Icons.notes_rounded,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final success = await controller.saveCustomer();
                  if (success) Get.back();
                },
                icon: const Icon(Icons.save_rounded),
                label: Text(isEditing ? 'Simpan Perubahan' : 'Tambah Pelanggan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
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
      child: Column(children: children),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
    bool isRequired = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment:
            maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 14 : 0),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              textCapitalization: textCapitalization,
              maxLines: maxLines,
              decoration: InputDecoration(
                labelText: isRequired ? '$label *' : label,
                hintText: hint,
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
