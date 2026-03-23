import 'package:uuid/uuid.dart';

enum AttendanceStatus { hadir, terlambat, izin, sakit, alpa }

extension AttendanceStatusExt on AttendanceStatus {
  String get label {
    switch (this) {
      case AttendanceStatus.hadir:
        return 'Hadir';
      case AttendanceStatus.terlambat:
        return 'Terlambat';
      case AttendanceStatus.izin:
        return 'Izin';
      case AttendanceStatus.sakit:
        return 'Sakit';
      case AttendanceStatus.alpa:
        return 'Alpa';
    }
  }

  String get emoji {
    switch (this) {
      case AttendanceStatus.hadir:
        return '✅';
      case AttendanceStatus.terlambat:
        return '⏰';
      case AttendanceStatus.izin:
        return '📝';
      case AttendanceStatus.sakit:
        return '🤒';
      case AttendanceStatus.alpa:
        return '❌';
    }
  }

  static AttendanceStatus fromString(String s) {
    return AttendanceStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => AttendanceStatus.hadir,
    );
  }
}

class AttendanceModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final String employeeRole;
  final DateTime date;
  final AttendanceStatus status;
  final String? checkIn;
  final String? checkOut;
  final String notes;
  final DateTime createdAt;

  const AttendanceModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeRole,
    required this.date,
    required this.status,
    this.checkIn,
    this.checkOut,
    required this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'employee_id': employeeId,
        'employee_name': employeeName,
        'employee_role': employeeRole,
        'date': date.toIso8601String(),
        'status': status.name,
        'check_in': checkIn,
        'check_out': checkOut,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory AttendanceModel.fromMap(Map<String, dynamic> map) => AttendanceModel(
        id: map['id'] as String,
        employeeId: map['employee_id'] as String,
        employeeName: map['employee_name'] as String,
        employeeRole: map['employee_role'] as String,
        date: DateTime.parse(map['date'] as String),
        status: AttendanceStatusExt.fromString(map['status'] as String),
        checkIn: map['check_in'] as String?,
        checkOut: map['check_out'] as String?,
        notes: map['notes'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  factory AttendanceModel.create({
    required String employeeId,
    required String employeeName,
    required String employeeRole,
    required DateTime date,
    required AttendanceStatus status,
    String? checkIn,
    String? checkOut,
    String notes = '',
  }) =>
      AttendanceModel(
        id: const Uuid().v4(),
        employeeId: employeeId,
        employeeName: employeeName,
        employeeRole: employeeRole,
        date: date,
        status: status,
        checkIn: checkIn,
        checkOut: checkOut,
        notes: notes,
        createdAt: DateTime.now(),
      );

  AttendanceModel copyWith({
    AttendanceStatus? status,
    String? checkIn,
    String? checkOut,
    String? notes,
    String? employeeName,
    String? employeeRole,
  }) =>
      AttendanceModel(
        id: id,
        employeeId: employeeId,
        employeeName: employeeName ?? this.employeeName,
        employeeRole: employeeRole ?? this.employeeRole,
        date: date,
        status: status ?? this.status,
        checkIn: checkIn ?? this.checkIn,
        checkOut: checkOut ?? this.checkOut,
        notes: notes ?? this.notes,
        createdAt: createdAt,
      );
}
