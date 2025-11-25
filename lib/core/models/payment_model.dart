import 'booking_model.dart';

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  refunded,
}

enum PaymentMethod {
  card,
  cash,
  wallet,
  bankTransfer,
}

class PaymentModel {
  final String id;
  final String bookingId;
  final BookingModel? booking;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? transactionId;
  final String? receiptUrl;
  final DateTime? paidAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  PaymentModel({
    required this.id,
    required this.bookingId,
    this.booking,
    required this.amount,
    required this.method,
    required this.status,
    this.transactionId,
    this.receiptUrl,
    this.paidAt,
    this.createdAt,
    this.updatedAt,
  });
  
  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      bookingId: json['bookingId'] as String,
      booking: json['booking'] != null
          ? BookingModel.fromJson(json['booking'] as Map<String, dynamic>)
          : null,
      amount: (json['amount'] as num).toDouble(),
      method: _parseMethod(json['method'] as String),
      status: _parseStatus(json['status'] as String),
      transactionId: json['transactionId'] as String?,
      receiptUrl: json['receiptUrl'] as String?,
      paidAt: json['paidAt'] != null
          ? DateTime.parse(json['paidAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }
  
  static PaymentMethod _parseMethod(String method) {
    switch (method.toLowerCase()) {
      case 'card':
        return PaymentMethod.card;
      case 'cash':
        return PaymentMethod.cash;
      case 'wallet':
        return PaymentMethod.wallet;
      case 'banktransfer':
      case 'bank_transfer':
        return PaymentMethod.bankTransfer;
      default:
        return PaymentMethod.card;
    }
  }
  
  static PaymentStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return PaymentStatus.pending;
      case 'processing':
        return PaymentStatus.processing;
      case 'completed':
        return PaymentStatus.completed;
      case 'failed':
        return PaymentStatus.failed;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.pending;
    }
  }
  
  String get methodString {
    switch (method) {
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.wallet:
        return 'wallet';
      case PaymentMethod.bankTransfer:
        return 'bank_transfer';
    }
  }
  
  String get statusString {
    switch (status) {
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.processing:
        return 'processing';
      case PaymentStatus.completed:
        return 'completed';
      case PaymentStatus.failed:
        return 'failed';
      case PaymentStatus.refunded:
        return 'refunded';
    }
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'booking': booking?.toJson(),
      'amount': amount,
      'method': methodString,
      'status': statusString,
      'transactionId': transactionId,
      'receiptUrl': receiptUrl,
      'paidAt': paidAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
  
  PaymentModel copyWith({
    String? id,
    String? bookingId,
    BookingModel? booking,
    double? amount,
    PaymentMethod? method,
    PaymentStatus? status,
    String? transactionId,
    String? receiptUrl,
    DateTime? paidAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      booking: booking ?? this.booking,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

