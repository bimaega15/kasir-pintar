import 'package:get/get.dart';
import '../models/attendance_model.dart';
import '../providers/storage_provider.dart';

class AttendanceRepository {
  final DatabaseProvider _db = Get.find<DatabaseProvider>();

  Future<List<AttendanceModel>> getByDate(DateTime date) =>
      _db.getAttendancesByDate(date);

  Future<List<AttendanceModel>> getByEmployee(
    String employeeId, {
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      _db.getAttendancesByEmployee(employeeId,
          startDate: startDate, endDate: endDate);

  Future<AttendanceModel?> getByEmployeeDate(
          String employeeId, DateTime date) =>
      _db.getAttendanceByEmployeeDate(employeeId, date);

  Future<void> save(AttendanceModel a) => _db.insertAttendance(a);

  Future<void> update(AttendanceModel a) => _db.updateAttendance(a);

  Future<void> delete(String id) => _db.deleteAttendance(id);

  Future<Map<String, int>> getSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) =>
      _db.getAttendanceSummary(startDate: startDate, endDate: endDate);
}
