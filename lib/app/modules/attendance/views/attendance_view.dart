import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/attendance_controller.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/models/employee_model.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/helpers/currency_helper.dart';
import '../../../routes/app_routes.dart';

class AttendanceView extends GetView<AttendanceController> {
  const AttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Presensi Karyawan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.people_rounded),
            tooltip: 'Kelola Karyawan',
            onPressed: () => Get.toNamed(AppRoutes.manageEmployees),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateSelector(context),
          _buildSummaryRow(),
          Expanded(child: _buildEmployeeList(context)),
        ],
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Obx(() => GestureDetector(
            onTap: () => _pickDate(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    CurrencyHelper.formatDate(controller.selectedDate.value),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_drop_down_rounded,
                      color: AppColors.primary, size: 20),
                ],
              ),
            ),
          )),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate.value,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) controller.changeDate(picked);
  }

  Widget _buildSummaryRow() {
    return Obx(() {
      final chips = [
        _SummaryChip('Hadir', controller.countHadir.value,
            const Color(0xFF2E7D32), Icons.check_circle_rounded),
        _SummaryChip('Terlambat', controller.countTerlambat.value,
            const Color(0xFFF57C00), Icons.access_time_rounded),
        _SummaryChip('Izin', controller.countIzin.value,
            const Color(0xFF1565C0), Icons.assignment_rounded),
        _SummaryChip('Sakit', controller.countSakit.value,
            const Color(0xFF6A1B9A), Icons.sick_rounded),
        _SummaryChip('Alpa', controller.countAlpa.value,
            const Color(0xFFC62828), Icons.cancel_rounded),
        _SummaryChip('Belum', controller.countBelumAbsen.value,
            Colors.grey.shade500, Icons.radio_button_unchecked_rounded),
      ];
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: chips
                .map((c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildSummaryChip(c),
                    ))
                .toList(),
          ),
        ),
      );
    });
  }

  Widget _buildSummaryChip(_SummaryChip c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(c.icon, size: 13, color: c.color),
          const SizedBox(width: 4),
          Text(
            '${c.label} ${c.count}',
            style: TextStyle(
              fontSize: 11,
              color: c.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeList(BuildContext context) {
    return Obx(() {
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
                onPressed: () => Get.toNamed(AppRoutes.manageEmployees),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Tambah Karyawan'),
              ),
            ],
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: controller.loadData,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          itemCount: controller.employees.length,
          itemBuilder: (_, i) => _buildEmployeeCard(
              context, controller.employees[i]),
        ),
      );
    });
  }

  Widget _buildEmployeeCard(BuildContext context, EmployeeModel emp) {
    return Obx(() {
      final att = controller.attendanceFor(emp.id);
      final color = att != null
          ? _statusColor(att.status)
          : Colors.grey.shade400;

      return GestureDetector(
        onTap: () => controller.showAttendanceSheet(context, emp),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Text(
                emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                style: TextStyle(
                    color: color,
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
                        fontSize: 11, color: AppColors.textSecondary)),
                if (att != null && (att.checkIn != null || att.checkOut != null))
                  Text(
                    [
                      if (att.checkIn != null) 'Masuk: ${att.checkIn}',
                      if (att.checkOut != null) 'Keluar: ${att.checkOut}',
                    ].join('  ·  '),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
              ],
            ),
            trailing: att != null
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${att.status.emoji} ${att.status.label}',
                      style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w600),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Text(
                      'Belum Absen',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
          ),
        ),
      );
    });
  }

  Color _statusColor(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.hadir:
        return const Color(0xFF2E7D32);
      case AttendanceStatus.terlambat:
        return const Color(0xFFF57C00);
      case AttendanceStatus.izin:
        return const Color(0xFF1565C0);
      case AttendanceStatus.sakit:
        return const Color(0xFF6A1B9A);
      case AttendanceStatus.alpa:
        return const Color(0xFFC62828);
    }
  }
}

class _SummaryChip {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  const _SummaryChip(this.label, this.count, this.color, this.icon);
}
