import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/models/employee_model.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../../data/repositories/employee_repository.dart';
import '../../../services/user_session.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/helpers/currency_helper.dart';

class AttendanceController extends GetxController {
  final _attendanceRepo = Get.find<AttendanceRepository>();
  final _employeeRepo = Get.find<EmployeeRepository>();
  final _session = Get.find<UserSession>();

  // ── State ─────────────────────────────────────────────────────────────────
  final selectedDate = DateTime.now().obs;
  final attendances = <AttendanceModel>[].obs;
  final employees = <EmployeeModel>[].obs;
  final isLoading = false.obs;

  // Summary counts
  final countHadir = 0.obs;
  final countTerlambat = 0.obs;
  final countIzin = 0.obs;
  final countSakit = 0.obs;
  final countAlpa = 0.obs;
  final countBelumAbsen = 0.obs;

  String get currentUsername => _session.currentUsername.value;
  bool get isAdmin => _session.isAdmin;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    try {
      employees.assignAll(await _employeeRepo.getAllFromAppUsers());
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

  // ── Attendance sheet entry point ──────────────────────────────────────────

  void showAttendanceSheet(BuildContext context, EmployeeModel employee) {
    final isSelf = employee.id == currentUsername;

    if (!isSelf && !isAdmin) {
      Get.snackbar(
        'Tidak Diizinkan',
        'Kamu hanya bisa mengatur presensimu sendiri',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade900,
      );
      return;
    }

    if (isSelf) {
      _showSelfSheet(context, employee);
    } else {
      _showAdminSheet(context, employee);
    }
  }

  // ── Self-service sheet (check-in / check-out) ─────────────────────────────

  void _showSelfSheet(BuildContext context, EmployeeModel employee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final existing = attendanceFor(employee.id);
          final now = DateTime.now();
          final nowStr =
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
          final hasIn = existing?.checkIn != null;
          final hasOut = existing?.checkOut != null;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              left: 20,
              right: 20,
              top: 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
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

                // Header
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.12),
                      child: Text(
                        employee.name.isNotEmpty
                            ? employee.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${employee.role}  ·  ${CurrencyHelper.formatDate(selectedDate.value)}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Current time chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Waktu sekarang: $nowStr',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Existing time info
                if (hasIn || hasOut)
                  Row(
                    children: [
                      if (hasIn)
                        Expanded(
                          child: _timeTile('Masuk', existing!.checkIn!,
                              Icons.login_rounded, Colors.green),
                        ),
                      if (hasIn && hasOut) const SizedBox(width: 8),
                      if (hasOut)
                        Expanded(
                          child: _timeTile('Keluar', existing!.checkOut!,
                              Icons.logout_rounded, Colors.orange),
                        ),
                    ],
                  ),
                if (hasIn || hasOut) const SizedBox(height: 16),

                // Action buttons
                if (!hasIn) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _saveAttendance(
                          employee: employee,
                          existing: existing,
                          status: AttendanceStatus.hadir,
                          checkIn: nowStr,
                          checkOut: null,
                          notes: '',
                        );
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      },
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('Check In Sekarang'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ] else if (!hasOut) ...[
                  _statusInfo('Sudah check in pukul ${existing!.checkIn}',
                      Colors.green, Icons.check_circle_rounded),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _saveAttendance(
                          employee: employee,
                          existing: existing,
                          status: existing.status,
                          checkIn: existing.checkIn,
                          checkOut: nowStr,
                          notes: existing.notes,
                        );
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Check Out Sekarang'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ] else ...[
                  _statusInfo(
                      'Presensi hari ini sudah lengkap ✓',
                      Colors.blue,
                      Icons.verified_rounded),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Admin full-form sheet ─────────────────────────────────────────────────

  void _showAdminSheet(BuildContext context, EmployeeModel employee) {
    final existing = attendanceFor(employee.id);
    final statusObs =
        (existing?.status ?? AttendanceStatus.hadir).obs;
    final checkInCtrl =
        TextEditingController(text: existing?.checkIn ?? '');
    final checkOutCtrl =
        TextEditingController(text: existing?.checkOut ?? '');
    final notesCtrl =
        TextEditingController(text: existing?.notes ?? '');

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
              Text(employee.name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Text(employee.role,
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Text(
                CurrencyHelper.formatDate(selectedDate.value),
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade500),
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
                              color: selected ? Colors.white : color,
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
                      onTap: () => _pickTime(
                          ctx, checkInCtrl, existing?.checkIn),
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
                      onTap: () => _pickTime(
                          ctx, checkOutCtrl, existing?.checkOut),
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
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
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
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
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
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
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

  // ── Shared helpers ────────────────────────────────────────────────────────

  Future<void> _pickTime(
      BuildContext context,
      TextEditingController ctrl,
      String? initial) async {
    TimeOfDay initialTime = TimeOfDay.now();
    if (initial != null && initial.contains(':')) {
      final parts = initial.split(':');
      initialTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0);
    }
    final picked =
        await showTimePicker(context: context, initialTime: initialTime);
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

  Widget _timeTile(
      String label, String time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 10, color: color)),
              Text(time,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusInfo(String msg, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
