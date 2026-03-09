import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class CustomerModel {
  final String id;
  String name;
  String phone;
  String address;
  String notes;
  final DateTime createdAt;

  // Computed (set by repository)
  int totalTransactions;
  double totalSpent;

  CustomerModel({
    String? id,
    required this.name,
    this.phone = '',
    this.address = '',
    this.notes = '',
    DateTime? createdAt,
    this.totalTransactions = 0,
    this.totalSpent = 0,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  factory CustomerModel.fromJson(Map<String, dynamic> json) => CustomerModel(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String? ?? '',
        address: json['address'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'address': address,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };
}
