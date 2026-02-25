class SplitTransactionModel {
  final int? id;
  final String transactionId;
  final int splitNumber;
  final double totalSplitAmount;
  final double amountPaid;
  final double changeAmount;
  final String paymentMethod;
  final String notes;
  final DateTime createdAt;

  SplitTransactionModel({
    this.id,
    required this.transactionId,
    required this.splitNumber,
    required this.totalSplitAmount,
    required this.amountPaid,
    required this.changeAmount,
    required this.paymentMethod,
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isPaid => amountPaid >= totalSplitAmount;
  double get remaining =>
      (totalSplitAmount - amountPaid).clamp(0.0, double.infinity);
  double get change => changeAmount;

  Map<String, Object?> toMap() => {
        'transaction_id': transactionId,
        'split_number': splitNumber,
        'total_split_amount': totalSplitAmount,
        'amount_paid': amountPaid,
        'change_amount': changeAmount,
        'payment_method': paymentMethod,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory SplitTransactionModel.fromMap(Map<String, Object?> m) =>
      SplitTransactionModel(
        id: m['id'] as int?,
        transactionId: m['transaction_id'] as String,
        splitNumber: m['split_number'] as int,
        totalSplitAmount: (m['total_split_amount'] as num).toDouble(),
        amountPaid: (m['amount_paid'] as num).toDouble(),
        changeAmount: (m['change_amount'] as num).toDouble(),
        paymentMethod: m['payment_method'] as String,
        notes: m['notes'] as String? ?? '',
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  SplitTransactionModel copyWith({
    int? id,
    String? transactionId,
    int? splitNumber,
    double? totalSplitAmount,
    double? amountPaid,
    double? changeAmount,
    String? paymentMethod,
    String? notes,
    DateTime? createdAt,
  }) =>
      SplitTransactionModel(
        id: id ?? this.id,
        transactionId: transactionId ?? this.transactionId,
        splitNumber: splitNumber ?? this.splitNumber,
        totalSplitAmount: totalSplitAmount ?? this.totalSplitAmount,
        amountPaid: amountPaid ?? this.amountPaid,
        changeAmount: changeAmount ?? this.changeAmount,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
      );
}
