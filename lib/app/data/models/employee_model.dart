import 'package:uuid/uuid.dart';

class EmployeeModel {
  final String id;
  final String name;
  final String role;
  final String phone;
  final bool isActive;
  final DateTime createdAt;

  const EmployeeModel({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    required this.isActive,
    required this.createdAt,
  });

  static const List<String> roles = [
    'Kasir',
    'Pelayan',
    'Koki',
    'Supervisor',
    'Manajer',
    'Kebersihan',
    'Keamanan',
    'Lainnya',
  ];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'role': role,
        'phone': phone,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory EmployeeModel.fromMap(Map<String, dynamic> map) => EmployeeModel(
        id: map['id'] as String,
        name: map['name'] as String,
        role: map['role'] as String,
        phone: map['phone'] as String,
        isActive: (map['is_active'] as int) == 1,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  factory EmployeeModel.create({
    required String name,
    required String role,
    String phone = '',
  }) =>
      EmployeeModel(
        id: const Uuid().v4(),
        name: name,
        role: role,
        phone: phone,
        isActive: true,
        createdAt: DateTime.now(),
      );

  EmployeeModel copyWith({
    String? name,
    String? role,
    String? phone,
    bool? isActive,
  }) =>
      EmployeeModel(
        id: id,
        name: name ?? this.name,
        role: role ?? this.role,
        phone: phone ?? this.phone,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
      );
}
