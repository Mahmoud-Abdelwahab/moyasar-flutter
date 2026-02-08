/// Represents a payment split for dividing payment amount among recipients.
/// 
/// Payment splitting allows a merchant or platform to divide the payment amount
/// along multiple recipients programmatically, ensuring compliance with SAMA and ZATCA regulations.
class PaymentSplit {

  /// The recipient ID (entity_id, platform_id, or beneficiary_id)
  final String recipientId;

  /// The amount to be split to this recipient (in smallest currency unit)
  final int amount;

  /// The type of recipient: "Entity", "Platform", or "Beneficiary"
  final String? recipientType;

  /// Optional description for this split
  final String? description;

  /// Optional reference for this split
  final String? reference;

  /// Whether this split is the fee source (only one split can be fee_source)
  final bool feeSource;

  /// Whether this split is refundable
  final bool refundable;

  const PaymentSplit({
    required this.recipientId,
    required this.amount,
    this.recipientType,
    this.description,
    this.reference,
    this.feeSource = false,
    this.refundable = true,
  });

  Map<String, dynamic> toJson() => {
        'recipient_type': recipientType,
        'recipient_id': recipientId,
        'amount': amount,
        if (description != null) 'description': description,
        if (reference != null) 'reference': reference,
        'fee_source': feeSource,
        'refundable': refundable,
      };

  factory PaymentSplit.fromJson(Map<String, dynamic> json) {
    return PaymentSplit(
      recipientType: json['recipient_type'] as String?,
      recipientId: json['recipient_id'] as String,
      amount: json['amount'] as int,
      description: json['description'] as String?,
      reference: json['reference'] as String?,
      feeSource: json['fee_source'] as bool? ?? false,
      refundable: json['refundable'] as bool? ?? true,
    );
  }
}
