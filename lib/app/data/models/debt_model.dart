import 'package:uuid/uuid.dart';

class DebtPaymentEntry {
  final int? id;
  final String debtId;
  double amount;
  String method;
  final DateTime paidAt;
  String notes;

  DebtPaymentEntry({
    this.id,
    required this.debtId,
    required this.amount,
    this.method = 'Tunai',
    DateTime? paidAt,
    this.notes = '',
  }) : paidAt = paidAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'debt_id': debtId,
        'amount': amount,
        'method': method,
        'paid_at': paidAt.toIso8601String(),
        'notes': notes,
      };

  static DebtPaymentEntry fromMap(Map<String, dynamic> m) => DebtPaymentEntry(
        id: m['id'] as int?,
        debtId: m['debt_id'] as String,
        amount: (m['amount'] as num).toDouble(),
        method: m['method'] as String? ?? 'Tunai',
        paidAt: DateTime.parse(m['paid_at'] as String),
        notes: m['notes'] as String? ?? '',
      );
}

class DebtModel {
  final String id;
  String invoiceNumber;
  String customerName;
  double totalAmount;
  double dpAmount;
  double remainingAmount;
  String status; // 'unpaid' | 'partial' | 'paid'
  final DateTime createdAt;
  DateTime? paidAt;
  String notes;
  List<DebtPaymentEntry> payments;

  DebtModel({
    String? id,
    required this.invoiceNumber,
    this.customerName = '',
    required this.totalAmount,
    this.dpAmount = 0,
    required this.remainingAmount,
    this.status = 'unpaid',
    DateTime? createdAt,
    this.paidAt,
    this.notes = '',
    List<DebtPaymentEntry>? payments,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        payments = payments ?? [];

  bool get isFullyPaid => remainingAmount <= 0;

  String get statusLabel {
    switch (status) {
      case 'paid':
        return 'Lunas';
      case 'partial':
        return 'Sebagian';
      default:
        return 'Belum Lunas';
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'invoice_number': invoiceNumber,
        'customer_name': customerName,
        'total_amount': totalAmount,
        'dp_amount': dpAmount,
        'remaining_amount': remainingAmount,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'paid_at': paidAt?.toIso8601String(),
        'notes': notes,
      };

  static DebtModel fromMap(Map<String, dynamic> m) => DebtModel(
        id: m['id'] as String,
        invoiceNumber: m['invoice_number'] as String,
        customerName: m['customer_name'] as String? ?? '',
        totalAmount: (m['total_amount'] as num).toDouble(),
        dpAmount: (m['dp_amount'] as num?)?.toDouble() ?? 0,
        remainingAmount: (m['remaining_amount'] as num).toDouble(),
        status: m['status'] as String? ?? 'unpaid',
        createdAt: DateTime.parse(m['created_at'] as String),
        paidAt: m['paid_at'] != null
            ? DateTime.parse(m['paid_at'] as String)
            : null,
        notes: m['notes'] as String? ?? '',
      );
}
