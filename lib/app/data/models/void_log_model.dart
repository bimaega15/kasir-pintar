class VoidLogModel {
  final int? id;
  final String orderId;
  final String invoiceNumber;
  final double orderTotal;
  final String reason;
  final String voidedBy;
  final DateTime voidedAt;

  VoidLogModel({
    this.id,
    required this.orderId,
    required this.invoiceNumber,
    required this.orderTotal,
    required this.reason,
    required this.voidedBy,
    DateTime? voidedAt,
  }) : voidedAt = voidedAt ?? DateTime.now();

  Map<String, Object?> toMap() => {
        'order_id': orderId,
        'invoice_number': invoiceNumber,
        'order_total': orderTotal,
        'reason': reason,
        'voided_by': voidedBy,
        'voided_at': voidedAt.toIso8601String(),
      };

  factory VoidLogModel.fromMap(Map<String, Object?> m) => VoidLogModel(
        id: m['id'] as int?,
        orderId: m['order_id'] as String,
        invoiceNumber: m['invoice_number'] as String,
        orderTotal: (m['order_total'] as num).toDouble(),
        reason: m['reason'] as String,
        voidedBy: m['voided_by'] as String? ?? 'Kasir',
        voidedAt: DateTime.parse(m['voided_at'] as String),
      );
}
