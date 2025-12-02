import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/models/booking_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';

class PaymentPage extends StatefulWidget {
  final String bookingId;

  const PaymentPage({
    super.key,
    required this.bookingId,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final ApiClient _apiClient = ApiClient();
  BookingModel? _booking;
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _isPayingWithCredit = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadBooking() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final endpoint = ApiConstants.bookingDetails.replaceAll('{id}', widget.bookingId);
      final response = await _apiClient.get(endpoint);
      
      if (response.statusCode == 200) {
        _booking = BookingModel.fromJson(response.data);
        setState(() {
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load booking');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load booking details';
      });
    }
  }

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      print('🔵 [PAYMENT] Confirming demo payment for booking: ${widget.bookingId}');
      
      // Use demo payment endpoint
      final response = await _apiClient.post(
        ApiConstants.confirmDemoPayment,
        data: {
          'bookingId': widget.bookingId,
        },
      );

      print('🔵 [PAYMENT] Demo payment response: ${response.statusCode}');
      print('🔵 [PAYMENT] Demo payment data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        final paymentData = responseData['payment'] as Map<String, dynamic>;
        
        // Extract payment ID from response
        final paymentId = paymentData['id'] as String;
        
        if (mounted) {
          // Navigate to payment success page with booking ID
          context.pushReplacement(
            RouteConstants.paymentSuccessPath(paymentId, bookingId: widget.bookingId),
          );
        }
      } else {
        throw Exception('Payment confirmation failed');
      }
    } catch (e) {
      print('❌ [PAYMENT] Error processing payment: $e');
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Payment failed. Please try again.';
      });
      
      if (mounted) {
        String errorMessage = 'Payment failed. Please try again.';
        final errorStr = e.toString().toLowerCase();
        
        if (errorStr.contains('already completed') || errorStr.contains('400')) {
          errorMessage = 'Payment already completed for this booking.';
        } else if (errorStr.contains('404') || errorStr.contains('not found')) {
          errorMessage = 'Booking not found.';
        } else if (errorStr.contains('403') || errorStr.contains('forbidden')) {
          errorMessage = 'You do not have permission to process this payment.';
        }
        
        Helpers.showErrorSnackBar(context, errorMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final creditBalance = authProvider.user?.creditBalance ?? 0.0;
    final bookingAmount = _booking?.totalAmount ?? 0.0;
    final canPayWithCredit = creditBalance >= bookingAmount && bookingAmount > 0;
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_booking == null || _errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Booking not found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Go Back',
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Demo Payment Notice
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Demo Payment Mode',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Booking Summary
            _buildBookingSummary(),
            
            const SizedBox(height: 24),
            
            // Total Amount
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Total Amount',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Formatters.formatCurrency(_booking!.totalAmount),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Credit balance info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet,
                          color: AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Credit Balance: ${Formatters.formatCurrency(creditBalance)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    canPayWithCredit
                        ? 'You can pay for this booking using your credit balance.'
                        : 'Insufficient credit balance to cover this booking.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Demo Payment Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.credit_card, color: AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This is a demo payment. No actual payment will be processed.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.success, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Click "Confirm Payment" to complete the demo transaction.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Pay with Card (Demo) Button
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                text: _isProcessing ? 'Processing...' : 'Pay with Card (Demo)',
                onPressed: _isProcessing || _isPayingWithCredit
                    ? null
                    : _processPayment,
              ),
            ),
            
            const SizedBox(height: 12),

            // Pay with Credit Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: (!canPayWithCredit || _isProcessing || _isPayingWithCredit)
                    ? null
                    : () => _payWithCredit(authProvider),
                icon: const Icon(Icons.account_balance_wallet),
                label: Text(
                  _isPayingWithCredit
                      ? 'Processing...'
                      : 'Pay with Credit Balance',
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Cancel Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isProcessing ? null : () => context.pop(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _payWithCredit(AuthProvider authProvider) async {
    if (_booking == null) return;

    setState(() {
      _isPayingWithCredit = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.post(
        ApiConstants.payWithCredit,
        data: {
          'bookingId': widget.bookingId,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        String? paymentId;
        if (data is Map<String, dynamic>) {
          if (data['payment'] != null && data['payment'] is Map) {
            paymentId =
                (data['payment'] as Map<String, dynamic>)['id'] as String?;
          } else if (data['id'] != null) {
            paymentId = data['id'] as String;
          }
        }

        // Refresh user to update credit balance
        await authProvider.getCurrentUser();

        if (paymentId == null || paymentId.isEmpty) {
          paymentId = widget.bookingId; // fallback
        }

        context.pushReplacement(
          RouteConstants.paymentSuccessPath(
            paymentId,
            bookingId: widget.bookingId,
          ),
        );
      } else {
        throw Exception('Failed to pay with credit');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isPayingWithCredit = false;
      });
      Helpers.showErrorSnackBar(
        context,
        'Failed to pay with credit: ${e.toString()}',
      );
    }
  }

  Widget _buildBookingSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          if (_booking!.service != null) ...[
            _buildSummaryRow('Service', _booking!.service!.name),
            const SizedBox(height: 8),
            _buildSummaryRow('Date', Formatters.formatDisplayDate(_booking!.scheduledDate)),
            const SizedBox(height: 8),
            _buildSummaryRow('Time', Formatters.formatDisplayTime(_booking!.scheduledDate)),
            if (_booking!.address != null) ...[
              const SizedBox(height: 8),
              _buildSummaryRow('Location', _booking!.address!),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

}

