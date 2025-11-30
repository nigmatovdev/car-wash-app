import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/models/booking_model.dart';
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
            
            // Confirm Payment Button
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                text: _isProcessing ? 'Processing...' : 'Confirm Payment',
                onPressed: _isProcessing ? null : _processPayment,
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

