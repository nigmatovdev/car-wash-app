import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking_step_indicator.dart';
import '../widgets/step1_select_service.dart';
import '../widgets/step2_select_datetime.dart';
import '../widgets/step3_select_location.dart';
import '../widgets/step4_review_confirm.dart';

class CreateBookingPage extends StatefulWidget {
  final String? serviceId;

  const CreateBookingPage({
    super.key,
    this.serviceId,
  });

  @override
  State<CreateBookingPage> createState() => _CreateBookingPageState();
}

class _CreateBookingPageState extends State<CreateBookingPage> {
  int _currentStep = 1;
  final int _totalSteps = 4;

  void _nextStep() {
    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    }
  }

  bool _canProceedToNextStep() {
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    
    switch (_currentStep) {
      case 1:
        return bookingProvider.selectedService != null;
      case 2:
        return bookingProvider.selectedDate != null &&
            bookingProvider.selectedTimeSlot != null;
      case 3:
        return bookingProvider.selectedAddress != null;
      case 4:
        return bookingProvider.isBookingReady;
      default:
        return false;
    }
  }

  Future<void> _confirmBooking() async {
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    
    final success = await bookingProvider.createBooking();
    
    if (!mounted) return;

    if (success) {
      // Navigate to booking confirmation
      final bookingId = bookingProvider.createdBooking!.id;
      context.pushReplacement(RouteConstants.bookingConfirmationPath(bookingId));
    } else {
      final error = bookingProvider.errorMessage;
      if (error != null) {
        Helpers.showErrorSnackBar(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure services are loaded when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      if (homeProvider.services.isEmpty && !homeProvider.isLoading) {
        homeProvider.fetchServices();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Booking'),
      ),
      body: Column(
        children: [
          // Step Indicator
          BookingStepIndicator(
            currentStep: _currentStep,
            totalSteps: _totalSteps,
          ),

          // Step Content
          Expanded(
            child: _buildStepContent(),
          ),

          // Navigation Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (_currentStep > 1)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        child: const Text('Previous'),
                      ),
                    ),
                  if (_currentStep > 1) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Consumer<BookingProvider>(
                      builder: (context, bookingProvider, child) {
                        if (_currentStep == _totalSteps) {
                          return PrimaryButton(
                            text: 'Confirm Booking',
                            onPressed: bookingProvider.isLoading
                                ? null
                                : _confirmBooking,
                            isLoading: bookingProvider.isLoading,
                          );
                        }
                        return PrimaryButton(
                          text: 'Next',
                          onPressed: _canProceedToNextStep() ? _nextStep : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return Step1SelectService(
          preselectedServiceId: widget.serviceId,
        );
      case 2:
        return const Step2SelectDateTime();
      case 3:
        return const Step3SelectLocation();
      case 4:
        return Step4ReviewConfirm(
          onConfirm: _confirmBooking,
        );
      default:
        return const Center(child: Text('Invalid step'));
    }
  }
}

