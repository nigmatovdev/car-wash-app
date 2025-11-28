import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/colors.dart';

class QuickActions extends StatelessWidget {
  final bool hasActiveBooking;
  final VoidCallback? onTrackWasher;

  const QuickActions({
    super.key,
    this.hasActiveBooking = false,
    this.onTrackWasher,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Book Now Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push(RouteConstants.services);
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Book Now'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // My Bookings Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.push(RouteConstants.bookings);
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('My Bookings'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
          if (hasActiveBooking) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onTrackWasher ?? () {
                  context.push(RouteConstants.location);
                },
                icon: const Icon(Icons.location_on),
                label: const Text('Track Washer'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

