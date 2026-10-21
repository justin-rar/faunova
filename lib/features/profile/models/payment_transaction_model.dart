// ==============================================================================
// FAUNOVA MODEL: PaymentTransactionModel
// Model data riwayat transaksi pembayaran Midtrans Sandbox (Plan 304, Plan 444)
// ==============================================================================

class PaymentTransactionModel {
  final String id;
  final String orderId;
  final int amountIdr;
  final String currency;
  final String status; // 'pending', 'settlement', 'capture', 'deny', 'expire', 'cancel'
  final String? snapToken;
  final String? redirectUrl;
  final DateTime? createdAt;
  final DateTime? processedAt;
  final int entitlementDays;

  const PaymentTransactionModel({
    required this.id,
    required this.orderId,
    required this.amountIdr,
    this.currency = 'IDR',
    required this.status,
    this.snapToken,
    this.redirectUrl,
    this.createdAt,
    this.processedAt,
    this.entitlementDays = 30,
  });

  bool get isSuccess => status == 'settlement' || status == 'capture';
  bool get isSettled => isSuccess;
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'deny' || status == 'expire' || status == 'cancel';

  String get formattedAmount =>
      'Rp ${amountIdr.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  String get statusLabel {
    switch (status) {
      case 'settlement':
      case 'capture':
        return 'Berhasil';
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'expire':
        return 'Kedaluwarsa';
      case 'cancel':
        return 'Dibatalkan';
      case 'deny':
        return 'Ditolak';
      default:
        return status;
    }
  }

  factory PaymentTransactionModel.fromJson(Map<String, dynamic> json) {
    return PaymentTransactionModel(
      id: json['id'] as String? ?? json['order_id'] as String? ?? '',
      orderId: json['order_id'] as String? ?? '',
      amountIdr: (json['amount_idr'] as num?)?.toInt() ?? 15000,
      currency: json['currency'] as String? ?? 'IDR',
      status: json['status'] as String? ?? 'pending',
      snapToken: json['snap_token'] as String?,
      redirectUrl: json['redirect_url'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      processedAt: json['processed_at'] != null ? DateTime.tryParse(json['processed_at'].toString()) : null,
      entitlementDays: (json['entitlement_days'] as num?)?.toInt() ?? 30,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'amount_idr': amountIdr,
      'currency': currency,
      'status': status,
      'snap_token': snapToken,
      'redirect_url': redirectUrl,
      'created_at': createdAt?.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
      'entitlement_days': entitlementDays,
    };
  }
}
