import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/attendance_controller.dart';
import '../../../data/models/employee_model.dart';
import '../../../utils/constants/app_colors.dart';

class ManageEmployeesView extends GetView<AttendanceController> {
  const ManageEmployeesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kelola Karyawan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Tambah Karyawan',
            onPressed: controller.openAddEmployee,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.employees.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline_rounded,
                    size: 64,
                    color: AppColors.textSecondary.withValues(alpha: 0.4)),
                const SizedBox(height: 12),
                const Text('Belum ada karyawan',
                    style: TextStyle(
                        fontSize: 16, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: controller.openAddEmployee,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Tambah Karyawan'),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: controller.employees.length,
          itemBuilder: (_, i) =>
              _buildEmployeeCard(controller.employees[i]),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.openAddEmployee,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Tambah Karyawan'),
      ),
    );
  }

  Widget _buildEmployeeCard(EmployeeModel emp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 6,
              offset: Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
            style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
        ),
        title: Text(
          emp.name,
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.textPrimary),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emp.role,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
            if (emp.phone.isNotEmpty)
              Text(emp.phone,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_rounded,
                  size: 20, color: AppColors.textSecondary),
              tooltip: 'Edit',
              onPressed: () => controller.openEditEmployee(emp),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded,
                  size: 20, color: Colors.red.shade400),
              tooltip: 'Hapus',
              onPressed: () => controller.deleteEmployee(emp),
            ),
          ],
        ),
      ),
    );
  }
}
