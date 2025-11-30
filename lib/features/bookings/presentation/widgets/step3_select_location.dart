import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/services/location_service.dart';
import '../../../../core/utils/helpers.dart';
import '../providers/booking_provider.dart';

class Step3SelectLocation extends StatefulWidget {
  const Step3SelectLocation({super.key});

  @override
  State<Step3SelectLocation> createState() => _Step3SelectLocationState();
}

class _Step3SelectLocationState extends State<Step3SelectLocation> {
  final TextEditingController _addressController = TextEditingController();
  final LocationService _locationService = LocationService();
  bool _isLoadingLocation = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Get GPS position first
      final position = await _locationService.getCurrentPosition();
      
      // Try to get address (with retry and fallback built-in)
      String address;
      try {
        address = await _locationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
      } catch (e) {
        // If address lookup fails, use coordinates as fallback
        address = 'Location: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        if (mounted) {
          Helpers.showInfoSnackBar(
            context, 
            'Location retrieved, but address lookup failed. You can edit the address manually.',
          );
        }
      }

      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      bookingProvider.setLocation(
        address: address,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      _addressController.text = address;

      if (mounted) {
        // Check if address is just coordinates (fallback case)
        if (address.startsWith('Location:')) {
          Helpers.showInfoSnackBar(
            context, 
            'Location set. Please verify or edit the address.',
          );
        } else {
          Helpers.showSuccessSnackBar(context, 'Location set successfully');
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString();
        String userMessage;
        
        if (errorMessage.contains('permission')) {
          userMessage = 'Location permission denied. Please grant location access in settings.';
        } else if (errorMessage.contains('disabled')) {
          userMessage = 'Location services are disabled. Please enable them in settings.';
        } else if (errorMessage.contains('timeout') || errorMessage.contains('network')) {
          userMessage = 'Network timeout. Please check your internet connection and try again.';
        } else {
          userMessage = 'Failed to get location. Please try again or enter address manually.';
        }
        
        Helpers.showErrorSnackBar(context, userMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _confirmAddress() {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      Helpers.showErrorSnackBar(context, 'Please enter an address');
      return;
    }

    // For now, use a default location (in production, you'd geocode the address)
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    bookingProvider.setLocation(
      address: address,
      latitude: 0.0, // TODO: Geocode address to get coordinates
      longitude: 0.0,
    );

    Helpers.showSuccessSnackBar(context, 'Address confirmed');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, bookingProvider, child) {
        if (bookingProvider.selectedAddress != null) {
          _addressController.text = bookingProvider.selectedAddress!;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Location Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                  icon: _isLoadingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(_isLoadingLocation ? 'Getting location...' : 'Use Current Location'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 24),

              // Address Input
              Text(
                'Enter Address',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  hintText: 'Enter your address',
                  prefixIcon: const Icon(Icons.location_on),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check_circle),
                    onPressed: _confirmAddress,
                    color: AppColors.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              // Selected Location Display
              if (bookingProvider.selectedAddress != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selected Location',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bookingProvider.selectedAddress!,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Map Placeholder
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map, size: 48, color: AppColors.primary),
                      SizedBox(height: 8),
                      Text(
                        'Map View',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '(Map integration coming soon)',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

