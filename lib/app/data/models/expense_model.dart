import 'package:uuid/uuid.dart';

class ExpenseModel {
  final String id;
  final String category;
  final String description;
  final double amount;
  final String paymentMethod;
  final DateTime date;
  final String createdBy;
  final String notes;
  final DateTime createdAt;

  const ExpenseModel({
    required this.id,
    required this.category,
    required this.description,
    required this.amount,
    required this.paymentMethod,
    required this.date,
    required this.createdBy,
    required this.notes,
    required this.createdAt,
  });

  static const List<String> categories = [
    'Gaji Karyawan',
    'Sewa Tempat',
    'Listrik & Air',
    'Bahan Bakar',
    'Transportasi',
    'Perlengkapan',
    'Pemasaran & Iklan',
    'Pemeliharaan',
    'Lain-lain',
  ];

  static const List<String> paymentMethods = [
    'Tunai',
    'Transfer Bank',
    'QRIS',
    'Kartu Debit',
    'Kartu Kredit',
  ];

  Map<String, dynamic> toMap() => {
        'id': id,
        'category': category,
        'description': description,
        'amount': amount,
        'payment_method': paymentMethod,
        'date': date.toIso8601String(),
        'created_by': createdBy,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory ExpenseModel.fromMap(Map<String, dynamic> map) => ExpenseModel(
        id: map['id'] as String,
        category: map['category'] as String,
        description: map['description'] as String,
        amount: (map['amount'] as num).toDouble(),
        paymentMethod: map['payment_method'] as String,
        date: DateTime.parse(map['date'] as String),
        createdBy: map['created_by'] as String,
        notes: map['notes'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  factory ExpenseModel.create({
    required String category,
    required String description,
    required double amount,
    required String paymentMethod,
    required DateTime date,
    String createdBy = 'Kasir',
    String notes = '',
  }) =>
      ExpenseModel(
        id: const Uuid().v4(),
        category: category,
        description: description,
        amount: amount,
        paymentMethod: paymentMethod,
        date: date,
        createdBy: createdBy,
        notes: notes,
        createdAt: DateTime.now(),
      );

  ExpenseModel copyWith({
    String? category,
    String? description,
    double? amount,
    String? paymentMethod,
    DateTime? date,
    String? createdBy,
    String? notes,
  }) =>
      ExpenseModel(
        id: id,
        category: category ?? this.category,
        description: description ?? this.description,
        amount: amount ?? this.amount,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        date: date ?? this.date,
        createdBy: createdBy ?? this.createdBy,
        notes: notes ?? this.notes,
        createdAt: createdAt,
      );
}
