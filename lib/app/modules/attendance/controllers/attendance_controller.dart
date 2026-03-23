import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/models/employee_model.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../../data/repositories/employee_repository.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/helpers/currency_helper.dart';

class AttendanceController extends GetxController {
  final _attendanceRepo = Get.find<AttendanceRepository>();
  final _employeeRepo = Get.find<EmployeeRepository>();

  // ── Attendance state ──────────────────────────────────────────────────────
  final selectedDate = DateTime.now().obs;
  final attendances = <AttendanceModel>[].obs;
  final employees = <EmployeeModel>[].obs;
  final isLoading = false.obs;

  // Summary counts for selected date
  final countHadir = 0.obs;
  final countTerlambat = 0.obs;
  final countIzin = 0.obs;
  final countSakit = 0.obs;
  final countAlpa = 0.obs;
  final countBelumAbsen = 0.obs;

  // ── Employee management state ─────────────────────────────────────────────
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final selectedRole = EmployeeModel.roles.first.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    try {
      employees.assignAll(await _employeeRepo.getAll(activeOnly: true));
      await _loadAttendancesForDate(selectedDate.value);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadAttendancesForDate(DateTime date) async {
    final list = await _attendanceRepo.getByDate(date);
    attendances.assignAll(list);
    _recalcSummary();
  }

  void _recalcSummary() {
    final map = <String, int>{};
    for (final a in attendances) {
      map[a.status.name] = (map[a.status.name] ?? 0) + 1;
    }
    countHadir.value = map['hadir'] ?? 0;
    countTerlambat.value = map['terlambat'] ?? 0;
    countIzin.value = map['izin'] ?? 0;
    countSakit.value = map['sakit'] ?? 0;
    countAlpa.value = map['alpa'] ?? 0;
    countBelumAbsen.value = employees.length -
        attendances
            .where((a) => employees.any((e) => e.id == a.employeeId))
            .length;
  }

  // Returns the attendance record for an employee on the selected date, or null
  AttendanceModel? attendanceFor(String employeeId) {
    try {
      return attendances.firstWhere((a) => a.employeeId == employeeId);
    } catch (_) {
      return null;
    }
  }

  Future<void> changeDate(DateTime date) async {
    selectedDate.value = date;
    isLoading.value = true;
    try {
      await _loadAttendancesForDate(date);
    } finally {
      isLoading.value = false;
    }
  }

  // ── Attendance form / bottom-sheet ────────────────────────────────────────

  void showAttendanceSheet(BuildContext context, EmployeeModel employee) {
    final existing = attendanceFor(employee.id);
    final statusObs = (existing?.status ?? AttendanceStatus.hadir).obs;
    final checkInCtrl =
        TextEditingController(text: existing?.checkIn ?? '');
    final checkOutCtrl =
        TextEditingController(text: existing?.checkOut ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                employee.name,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                employee.role,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyHelper.formatDate(selectedDate.value),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 16),
              const Text('Status Kehadiran',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Obx(() => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AttendanceStatus.values.map((s) {
                      final selected = statusObs.value == s;
                      final color = _statusColor(s);
                      return GestureDetector(
                        onTap: () => statusObs.value = s,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? color
                                : color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? color
                                  : color.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            '${s.emoji} ${s.label}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color:
                                  selected ? Colors.white : color,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  )),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: checkInCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Jam Masuk',
                        hintText: '08:00',
                        prefixIcon:
                            Icon(Icons.login_rounded, size: 18),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      onTap: () =>
                          _pickTime(ctx, checkInCtrl, existing?.checkIn),
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: checkOutCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Jam Keluar',
                        hintText: '17:00',
                        prefixIcon:
                            Icon(Icons.logout_rounded, size: 18),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      onTap: () =>
                          _pickTime(ctx, checkOutCtrl, existing?.checkOut),
                      readOnly: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  prefixIcon: Icon(Icons.notes_rounded, size: 18),
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _saveAttendance(
                      employee: employee,
                      existing: existing,
                      status: statusObs.value,
                      checkIn: checkInCtrl.text.trim().isEmpty
                          ? null
                          : checkInCtrl.text.trim(),
                      checkOut: checkOutCtrl.text.trim().isEmpty
                          ? null
                          : checkOutCtrl.text.trim(),
                      notes: notesCtrl.text.trim(),
                    );
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: Text(existing != null
                      ? 'Perbarui Presensi'
                      : 'Simpan Presensi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              if (existing != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await _deleteAttendance(existing);
                    },
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.red),
                    label: const Text('Hapus Presensi',
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime(
      BuildContext context, TextEditingController ctrl, String? initial) async {
    TimeOfDay initialTime = TimeOfDay.now();
    if (initial != null && initial.contains(':')) {
      final parts = initial.split(':');
      initialTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0);
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      ctrl.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _saveAttendance({
    required EmployeeModel employee,
    required AttendanceModel? existing,
    required AttendanceStatus status,
    String? checkIn,
    String? checkOut,
    required String notes,
  }) async {
    if (existing != null) {
      await _attendanceRepo.update(existing.copyWith(
        status: status,
        checkIn: checkIn,
        checkOut: checkOut,
        notes: notes,
      ));
    } else {
      await _attendanceRepo.save(AttendanceModel.create(
        employeeId: employee.id,
        employeeName: employee.name,
        employeeRole: employee.role,
        date: selectedDate.value,
        status: status,
        checkIn: checkIn,
        checkOut: checkOut,
        notes: notes,
      ));
    }
    await _loadAttendancesForDate(selectedDate.value);
    Get.snackbar(
      'Presensi Disimpan',
      '${employee.name} — ${status.emoji} ${status.label}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade900,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _deleteAttendance(AttendanceModel a) async {
    await _attendanceRepo.delete(a.id);
    await _loadAttendancesForDate(selectedDate.value);
    Get.snackbar('Dihapus', 'Presensi berhasil dihapus',
        snackPosition: SnackPosition.BOTTOM);
  }

  // ── Employee CRUD ─────────────────────────────────────────────────────────

  void openAddEmployee() {
    _resetEmployeeForm();
    Get.toNamed(AppRoutes.addEditEmployee);
  }

  void openEditEmployee(EmployeeModel emp) {
    nameController.text = emp.name;
    phoneController.text = emp.phone;
    selectedRole.value = emp.role;
    Get.toNamed(AppRoutes.addEditEmployee, arguments: emp);
  }

  Future<void> saveEmployee() async {
    if (!formKey.currentState!.validate()) return;
    final existing = Get.arguments as EmployeeModel?;

    if (existing != null) {
      await _employeeRepo.update(existing.copyWith(
        name: nameController.text.trim(),
        role: selectedRole.value,
        phone: phoneController.text.trim(),
      ));
    } else {
      await _employeeRepo.add(EmployeeModel.create(
        name: nameController.text.trim(),
        role: selectedRole.value,
        phone: phoneController.text.trim(),
      ));
    }
    Get.back();
    await loadData();
    Get.snackbar(
      existing != null ? 'Karyawan Diperbarui' : 'Karyawan Ditambahkan',
      existing != null
          ? 'Data karyawan berhasil diperbarui'
          : '${nameController.text.trim()} berhasil ditambahkan',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade900,
    );
  }

  Future<void> toggleEmployeeActive(EmployeeModel emp) async {
    await _employeeRepo.update(emp.copyWith(isActive: !emp.isActive));
    await loadData();
  }

  Future<void> deleteEmployee(EmployeeModel emp) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Karyawan'),
        content: Text(
            'Hapus karyawan "${emp.name}"? Seluruh data presensinya juga akan dihapus.'),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _employeeRepo.delete(emp.id);
      await loadData();
      Get.snackbar('Dihapus', '${emp.name} berhasil dihapus',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _resetEmployeeForm() {
    nameController.clear();
    phoneController.clear();
    selectedRole.value = EmployeeModel.roles.first;
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

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    super.onClose();
  }
}
