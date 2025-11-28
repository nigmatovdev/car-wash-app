import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/booking_provider.dart';

class Step4ReviewConfirm extends StatelessWidget {
  final VoidCallback onConfirm;

  const Step4ReviewConfirm({
    super.key,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, bookingProvider, child) {
        final service = bookingProvider.selectedService!;
        final date = bookingProvider.selectedDate!;
        final timeSlot = bookingProvider.selectedTimeSlot!;
        final address = bookingProvider.selectedAddress!;
        final totalPrice = bookingProvider.totalPrice;

        // Combine date and time
        final timeParts = timeSlot.split(':');
        final bookingDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Review Your Booking',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),

              // Service Details
              _buildSection(
                context,
                'Service',
                [
                  _buildInfoRow('Name', service.name),
                  _buildInfoRow('Description', service.description),
                  _buildInfoRow('Duration', '${service.duration} minutes'),
                ],
              ),

              const SizedBox(height: 24),

              // Date & Time
              _buildSection(
                context,
                'Date & Time',
                [
                  _buildInfoRow(
                    'Date',
                    DateFormat('EEEE, MMMM dd, yyyy').format(bookingDateTime),
                  ),
                  _buildInfoRow(
                    'Time',
                    DateFormat('hh:mm a').format(bookingDateTime),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Location
              _buildSection(
                context,
                'Location',
                [
                  _buildInfoRow('Address', address),
                ],
              ),

              const SizedBox(height: 24),

              // Price Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Service Price',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(
                          Formatters.formatCurrency(service.price),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          Formatters.formatCurrency(totalPrice),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Notes (Optional)
              TextField(
                decoration: InputDecoration(
                  labelText: 'Additional Notes (Optional)',
                  hintText: 'Any special instructions...',
                  prefixIcon: const Icon(Icons.note_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
                onChanged: (value) {
                  bookingProvider.setNotes(value);
                },
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

