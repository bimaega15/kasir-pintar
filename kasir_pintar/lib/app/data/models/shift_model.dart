import 'package:uuid/uuid.dart';

class ShiftModel {
  final String id;
  final String cashierName;
  final double openingBalance;
  final double? closingBalance;
  final double? expectedCash;
  final double? difference;
  final String notes;
  final DateTime openedAt;
  final DateTime? closedAt;

  ShiftModel({
    String? id,
    required this.cashierName,
    required this.openingBalance,
    this.closingBalance,
    this.expectedCash,
    this.difference,
    this.notes = '',
    DateTime? openedAt,
    this.closedAt,
  })  : id = id ?? const Uuid().v4(),
        openedAt = openedAt ?? DateTime.now();

  bool get isOpen => closedAt == null;

  Map<String, Object?> toMap() => {
        'id': id,
        'cashier_name': cashierName,
        'opening_balance': openingBalance,
        'closing_balance': closingBalance,
        'expected_cash': expectedCash,
        'difference': difference,
        'notes': notes,
        'opened_at': openedAt.toIso8601String(),
        'closed_at': closedAt?.toIso8601String(),
      };

  factory ShiftModel.fromMap(Map<String, Object?> m) => ShiftModel(
        id: m['id'] as String,
        cashierName: m['cashier_name'] as String,
        openingBalance: (m['opening_balance'] as num).toDouble(),
        closingBalance: (m['closing_balance'] as num?)?.toDouble(),
        expectedCash: (m['expected_cash'] as num?)?.toDouble(),
        difference: (m['difference'] as num?)?.toDouble(),
        notes: m['notes'] as String? ?? '',
        openedAt: DateTime.parse(m['opened_at'] as String),
        closedAt: m['closed_at'] != null
            ? DateTime.parse(m['closed_at'] as String)
            : null,
      );
}
