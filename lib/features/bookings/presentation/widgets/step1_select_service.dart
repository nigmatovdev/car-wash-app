import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../providers/booking_provider.dart';

class Step1SelectService extends StatelessWidget {
  final String? preselectedServiceId;

  const Step1SelectService({
    super.key,
    this.preselectedServiceId,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure services are loaded when widget builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final homeProvider = Provider.of<HomeProvider>(context, listen: false);
        // Always fetch services if empty and not currently loading
        if (homeProvider.services.isEmpty && !homeProvider.isLoading) {
          homeProvider.fetchServices();
        }
        
        // If service is preselected, set it
        if (preselectedServiceId != null) {
          final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
          if (bookingProvider.selectedService == null && homeProvider.services.isNotEmpty) {
            try {
              final service = homeProvider.services.firstWhere(
                (s) => s.id == preselectedServiceId,
              );
              bookingProvider.setService(service);
            } catch (e) {
              // Service not found, user will need to select manually
            }
          }
        }
      } catch (e) {
        // Provider not available or other error
      }
    });

    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        // Show loading if currently loading services
        if (homeProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Show error if there's an error and no services
        if (homeProvider.errorMessage != null && homeProvider.services.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  homeProvider.errorMessage ?? 'Failed to load services',
                  style: const TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => homeProvider.fetchServices(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Show empty state if no services and not loading
        if (homeProvider.services.isEmpty && !homeProvider.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                const Text('No services available'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => homeProvider.fetchServices(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return Consumer<BookingProvider>(
          builder: (context, bookingProvider, child) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: homeProvider.services.length,
              itemBuilder: (context, index) {
                final service = homeProvider.services[index];
                final isSelected = bookingProvider.selectedService?.id == service.id;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
                  child: InkWell(
                    onTap: () {
                      bookingProvider.setService(service);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Service Icon/Image
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: service.image != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      service.image!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.local_car_wash, color: AppColors.primary),
                                    ),
                                  )
                                : const Icon(Icons.local_car_wash, color: AppColors.primary),
                          ),
                          const SizedBox(width: 16),
                          // Service Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  service.description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      Formatters.formatCurrency(service.price),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      '${service.duration} min',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Selection Indicator
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                              size: 28,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

