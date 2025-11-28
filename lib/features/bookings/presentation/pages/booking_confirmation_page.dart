import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../providers/booking_provider.dart';

class BookingConfirmationPage extends StatelessWidget {
  final String bookingId;

  const BookingConfirmationPage({
    super.key,
    required this.bookingId,
  });

  @override
  Widget build(BuildContext context) {
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

              // Success Message
              Text(
                'Booking Confirmed!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Your booking has been successfully created',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Booking Details Card
              Consumer<BookingProvider>(
                builder: (context, bookingProvider, child) {
                  final booking = bookingProvider.createdBooking;
                  if (booking == null) {
                    return const SizedBox();
                  }

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Booking ID
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Booking ID',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    booking.id.substring(0, 8).toUpperCase(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                        ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.share),
                                onPressed: () {
                                  // TODO: Implement share
                                  Helpers.showSnackBar(
                                    context,
                                    'Share functionality coming soon!',
                                  );
                                },
                              ),
                            ],
                          ),

                          const Divider(height: 32),

                          // Service Details
                          if (booking.service != null) ...[
                            _buildInfoRow(
                              context,
                              'Service',
                              booking.service!.name,
                              Icons.local_car_wash,
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Date & Time
                          _buildInfoRow(
                            context,
                            'Date & Time',
                            Formatters.formatDisplayDateTime(booking.scheduledDate),
                            Icons.calendar_today,
                          ),

                          const SizedBox(height: 12),

                          // Location
                          if (booking.address != null)
                            _buildInfoRow(
                              context,
                              'Location',
                              booking.address!,
                              Icons.location_on,
                            ),

                          const SizedBox(height: 12),

                          // Total Amount
                          _buildInfoRow(
                            context,
                            'Total',
                            Formatters.formatCurrency(booking.totalAmount),
                            Icons.payment,
                            isAmount: true,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Action Buttons
              Column(
                children: [
                  PrimaryButton(
                    text: 'View Booking',
                    onPressed: () {
                      context.push(RouteConstants.bookingDetailsPath(bookingId));
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      context.go(RouteConstants.home);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Go Home'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Additional Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      // TODO: Add to calendar
                      Helpers.showSnackBar(
                        context,
                        'Add to calendar coming soon!',
                      );
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Add to Calendar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool isAmount = false,
  }) {
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: isAmount ? FontWeight.bold : FontWeight.normal,
                      color: isAmount ? AppColors.primary : AppColors.textPrimary,
                      fontSize: isAmount ? 18 : 14,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

