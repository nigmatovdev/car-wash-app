import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/models/payment_model.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/services/notification_service.dart';

class PaymentSuccessPage extends StatefulWidget {
  final String paymentId;
  final String? bookingId;

  const PaymentSuccessPage({
    super.key,
    required this.paymentId,
    this.bookingId,
  });

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  final ApiClient _apiClient = ApiClient();
  PaymentModel? _payment;
  bool _isLoading = true;
  String? _errorMessage;
  double? _bookingAmount;

  @override
  void initState() {
    super.initState();
    _loadPayment();

    // Fire a local notification for payment success
    NotificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Payment successful',
      body: 'Your payment has been completed.',
    );
  }

  Future<void> _loadPayment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Load booking amount if booking ID is available
    String? bookingIdToUse = widget.bookingId;
    if (bookingIdToUse == null || bookingIdToUse.isEmpty) {
      // Try to extract from payment response if available
      bookingIdToUse = null; // Will be set from response if available
    }
    
    if (bookingIdToUse != null && bookingIdToUse.isNotEmpty) {
      await _loadBookingAmount(bookingIdToUse);
    }

    try {
      // Try to get payment details from API
      final endpoint = ApiConstants.paymentDetails.replaceAll('{id}', widget.paymentId);
      final response = await _apiClient.get(endpoint);
      
      if (response.statusCode == 200) {
        final data = response.data;
        // Handle both direct payment object and nested payment object
        if (data is Map<String, dynamic>) {
          if (data.containsKey('payment')) {
            // Demo payment response format
            final paymentData = data['payment'] as Map<String, dynamic>;
            _payment = _createPaymentFromDemoResponse(paymentData, data);
          } else {
            // Direct payment object
            _payment = PaymentModel.fromJson(data);
            // Update amount if we loaded it from booking
            if (_bookingAmount != null) {
              _payment = _payment!.copyWith(amount: _bookingAmount);
            }
          }
        }
        setState(() {
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load payment details');
      }
    } catch (e) {
      // If payment details endpoint fails, create a basic payment from the ID
      // This handles the case where we only have the payment ID from demo response
      print('⚠️ [PAYMENT_SUCCESS] Could not load payment details, creating from ID: $e');
      _payment = PaymentModel(
        id: widget.paymentId,
        bookingId: widget.bookingId ?? '',
        amount: _bookingAmount ?? 0.0,
        method: PaymentMethod.card,
        status: PaymentStatus.completed,
        paidAt: DateTime.now(),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  PaymentModel _createPaymentFromDemoResponse(
    Map<String, dynamic> paymentData,
    Map<String, dynamic> fullResponse,
  ) {
    // Extract booking ID from response if available, otherwise use widget bookingId
    final bookingId = fullResponse['bookingId'] as String? ?? widget.bookingId ?? '';
    
    // Try to get booking amount if booking ID is available
    if (bookingId.isNotEmpty) {
      _loadBookingAmount(bookingId);
    }
    
    // Parse payment date
    DateTime? paidAt;
    if (paymentData['paymentDate'] != null) {
      try {
        paidAt = DateTime.parse(paymentData['paymentDate'] as String);
      } catch (e) {
        paidAt = DateTime.now();
      }
    } else {
      paidAt = DateTime.now();
    }
    
    // Parse status
    PaymentStatus status = PaymentStatus.completed;
    final statusStr = paymentData['status'] as String?;
    if (statusStr != null) {
      switch (statusStr.toUpperCase()) {
        case 'PAID':
        case 'COMPLETED':
          status = PaymentStatus.completed;
          break;
        case 'PENDING':
          status = PaymentStatus.pending;
          break;
        case 'FAILED':
          status = PaymentStatus.failed;
          break;
        default:
          status = PaymentStatus.completed;
      }
    }
    
    return PaymentModel(
      id: paymentData['id'] as String? ?? widget.paymentId,
      bookingId: bookingId,
      amount: _bookingAmount ?? 0.0,
      method: PaymentMethod.card,
      status: status,
      transactionId: paymentData['id'] as String?,
      paidAt: paidAt,
      createdAt: paidAt,
      updatedAt: paidAt,
    );
  }
  
  Future<void> _loadBookingAmount(String bookingId) async {
    try {
      final endpoint = ApiConstants.bookingDetails.replaceAll('{id}', bookingId);
      final response = await _apiClient.get(endpoint);
      if (response.statusCode == 200) {
        final booking = response.data as Map<String, dynamic>;
        final amount = booking['totalAmount'] as num?;
        if (amount != null) {
          setState(() {
            _bookingAmount = amount.toDouble();
            if (_payment != null) {
              _payment = _payment!.copyWith(amount: _bookingAmount);
            }
          });
        }
      }
    } catch (e) {
      print('⚠️ [PAYMENT_SUCCESS] Could not load booking amount: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_payment == null || _errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Payment not found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Go Home',
                onPressed: () => context.go(RouteConstants.home),
              ),
            ],
          ),
        ),
      );
    }

    final payment = _payment!;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // Success Icon/Animation
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 80,
                  color: AppColors.success,
                ),
              ),

              const SizedBox(height: 32),

              // Success Title
              Text(
                'Payment Successful!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                'Your payment has been processed successfully',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Payment Confirmation Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Confirmation',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Transaction ID
                    _buildInfoRow(
                      'Transaction ID',
                      payment.transactionId ?? payment.id.substring(0, 8).toUpperCase(),
                      Icons.receipt,
                    ),
                    const SizedBox(height: 16),
                    
                    // Amount Paid
                    _buildInfoRow(
                      'Amount Paid',
                      Formatters.formatCurrency(_bookingAmount ?? payment.amount),
                      Icons.attach_money,
                      isAmount: true,
                    ),
                    const SizedBox(height: 16),
                    
                    // Payment Date
                    _buildInfoRow(
                      'Payment Date',
                      payment.paidAt != null
                          ? Formatters.formatDisplayDate(payment.paidAt!)
                          : Formatters.formatDisplayDate(DateTime.now()),
                      Icons.calendar_today,
                    ),
                    const SizedBox(height: 16),
                    
                    // Payment Method
                    _buildInfoRow(
                      'Payment Method',
                      _getPaymentMethodText(payment.method),
                      Icons.payment,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Action Buttons
              Column(
                children: [
                  PrimaryButton(
                    text: 'View Booking',
                    onPressed: () {
                      context.pushReplacement(
                        RouteConstants.bookingDetailsPath(payment.bookingId),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      context.go(RouteConstants.home);
                    },
                    child: const Text('Go Home'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Receipt Options
              if (payment.receiptUrl != null && payment.receiptUrl!.isNotEmpty) ...[
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        // TODO: Implement receipt download
                        Helpers.showInfoSnackBar(
                          context,
                          'Receipt download coming soon!',
                        );
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Download Receipt'),
                    ),
                    const SizedBox(width: 16),
                    TextButton.icon(
                      onPressed: () {
                        // TODO: Implement email receipt
                        Helpers.showInfoSnackBar(
                          context,
                          'Email receipt coming soon!',
                        );
                      },
                      icon: const Icon(Icons.email),
                      label: const Text('Email Receipt'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {bool isAmount = false}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontWeight: isAmount ? FontWeight.bold : FontWeight.normal,
                  fontSize: isAmount ? 18 : 14,
                  color: isAmount ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getPaymentMethodText(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.card:
        return 'Credit/Debit Card';
      case PaymentMethod.wallet:
        return 'Digital Wallet';
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
    }
  }
}

