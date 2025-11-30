import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/models/booking_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/map/maplibre_widget.dart';
import '../providers/washer_provider.dart';

class WasherBookingDetailsPage extends StatefulWidget {
  final String bookingId;

  const WasherBookingDetailsPage({
    super.key,
    required this.bookingId,
  });

  @override
  State<WasherBookingDetailsPage> createState() => _WasherBookingDetailsPageState();
}

class _WasherBookingDetailsPageState extends State<WasherBookingDetailsPage> {
  final ApiClient _apiClient = ApiClient();
  BookingModel? _booking;
  bool _isLoading = true;
  bool _isUpdatingStatus = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBooking();
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
      } else {
        throw Exception('Failed to load booking');
      }
    } catch (e) {
      _errorMessage = 'Failed to load booking details';
      print('❌ [WASHER_BOOKING_DETAILS] Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(BookingStatus newStatus) async {
    final confirmed = await _showStatusUpdateConfirmation(newStatus);
    if (confirmed != true) return;

    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      final provider = context.read<WasherProvider>();
      final success = await provider.updateBookingStatus(widget.bookingId, newStatus);
      
      if (success) {
        // Reload booking to get updated status
        await _loadBooking();
        
        if (mounted) {
          Helpers.showSuccessSnackBar(context, 'Status updated successfully');
        }
      } else {
        throw Exception(provider.errorMessage ?? 'Failed to update status');
      }
    } catch (e) {
      if (mounted) {
        Helpers.showErrorSnackBar(context, 'Failed to update status: ${e.toString()}');
      }
    } finally {
      setState(() {
        _isUpdatingStatus = false;
      });
    }
  }

  Future<bool?> _showStatusUpdateConfirmation(BookingStatus newStatus) {
    final statusText = _getStatusText(newStatus);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Status to $statusText?'),
        content: Text('Are you sure you want to update the booking status to $statusText?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToLocation() async {
    if (_booking?.latitude == null || _booking?.longitude == null) {
      Helpers.showErrorSnackBar(context, 'Location not available');
      return;
    }

    final lat = _booking!.latitude!;
    final lng = _booking!.longitude!;
    
    // Try to open in Google Maps or Apple Maps
    final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final appleMapsUrl = 'https://maps.apple.com/?q=$lat,$lng';
    
    try {
      final uri = Uri.parse(googleMapsUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        final appleUri = Uri.parse(appleMapsUrl);
        if (await canLaunchUrl(appleUri)) {
          await launchUrl(appleUri, mode: LaunchMode.externalApplication);
        } else {
          Helpers.showErrorSnackBar(context, 'Could not open maps');
        }
      }
    } catch (e) {
      Helpers.showErrorSnackBar(context, 'Failed to open maps: $e');
    }
  }

  Future<void> _contactCustomer() async {
    if (_booking?.user?.phone == null) {
      Helpers.showErrorSnackBar(context, 'Customer phone number not available');
      return;
    }

    final phone = _booking!.user!.phone!;
    final uri = Uri.parse('tel:$phone');
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        Helpers.showErrorSnackBar(context, 'Could not make phone call');
      }
    } catch (e) {
      Helpers.showErrorSnackBar(context, 'Failed to call: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Booking Details'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_booking == null || _errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Booking Details'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
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
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final booking = _booking!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: _getStatusColor(booking.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _getStatusColor(booking.status),
                    width: 2,
                  ),
                ),
                child: Text(
                  _getStatusText(booking.status),
                  style: TextStyle(
                    color: _getStatusColor(booking.status),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Service Details
            _buildSection(
              'Service Details',
              [
                if (booking.service != null) ...[
                  _buildInfoRow('Service', booking.service!.name, Icons.local_car_wash),
                  _buildInfoRow('Price', Formatters.formatCurrency(booking.totalAmount), Icons.attach_money),
                  if (booking.service!.duration > 0)
                    _buildInfoRow('Duration', '${booking.service!.duration} minutes', Icons.timer),
                ],
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Customer Info
            _buildSection(
              'Customer Information',
              [
                if (booking.user != null) ...[
                  _buildInfoRow('Name', booking.user!.fullName, Icons.person),
                  _buildInfoRow('Email', booking.user!.email, Icons.email),
                  if (booking.user!.phone != null)
                    _buildInfoRow('Phone', booking.user!.phone!, Icons.phone),
                ],
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Schedule
            _buildSection(
              'Schedule',
              [
                _buildInfoRow('Date', Formatters.formatDisplayDate(booking.scheduledDate), Icons.calendar_today),
                _buildInfoRow('Time', Formatters.formatDisplayTime(booking.scheduledDate), Icons.access_time),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Location
            if (booking.address != null || (booking.latitude != null && booking.longitude != null))
              _buildSection(
                'Location',
                [
                  if (booking.address != null)
                    _buildInfoRow('Address', booking.address!, Icons.location_on),
                  if (booking.latitude != null && booking.longitude != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _navigateToLocation,
                        icon: const Icon(Icons.navigation),
                        label: const Text('Navigate to Location'),
                      ),
                    ),
                  ],
                ],
              ),
            
            // Map View
            if (booking.latitude != null && booking.longitude != null) ...[
              const SizedBox(height: 24),
              Container(
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: MapLibreWidget(
                  initialLatitude: booking.latitude,
                  initialLongitude: booking.longitude,
                  initialZoom: 15.0,
                  enableMarkerOnTap: false,
                  enableMarkerOnLongPress: false,
                  markers: [
                    MapMarker(
                      latitude: booking.latitude!,
                      longitude: booking.longitude!,
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Status Update Buttons
            _buildStatusUpdateButtons(booking),
            
            const SizedBox(height: 16),
            
            // Contact Customer Button
            if (booking.user?.phone != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _contactCustomer,
                  icon: const Icon(Icons.phone),
                  label: const Text('Contact Customer'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
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
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusUpdateButtons(BookingModel booking) {
    final buttons = <Widget>[];

    // Status flow: ASSIGNED → EN_ROUTE → ARRIVED → IN_PROGRESS → COMPLETED
    
    // En Route button (from ASSIGNED)
    if (booking.status == BookingStatus.assigned || booking.status == BookingStatus.confirmed) {
      buttons.add(
        PrimaryButton(
          text: 'En Route',
          onPressed: _isUpdatingStatus
              ? null
              : () => _updateStatus(BookingStatus.enRoute),
        ),
      );
    }

    // Arrived button (from EN_ROUTE)
    if (booking.status == BookingStatus.enRoute) {
      buttons.add(
        PrimaryButton(
          text: 'Arrived',
          onPressed: _isUpdatingStatus
              ? null
              : () => _updateStatus(BookingStatus.arrived),
        ),
      );
    }

    // Start Service button (from ARRIVED)
    if (booking.status == BookingStatus.arrived) {
      buttons.add(
        PrimaryButton(
          text: 'Start Service',
          onPressed: _isUpdatingStatus
              ? null
              : () => _updateStatus(BookingStatus.inProgress),
        ),
      );
    }

    // Complete Service button (from IN_PROGRESS)
    if (booking.status == BookingStatus.inProgress) {
      buttons.add(
        const SizedBox(height: 12),
      );
      buttons.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isUpdatingStatus
                ? null
                : () => _updateStatus(BookingStatus.completed),
            icon: const Icon(Icons.check_circle),
            label: const Text('Complete Service'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      );
    }

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Text(
          'Update Status',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ...buttons,
      ],
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return AppColors.warning;
      case BookingStatus.assigned:
        return AppColors.primary;
      case BookingStatus.enRoute:
        return AppColors.secondary;
      case BookingStatus.arrived:
        return Colors.orange;
      case BookingStatus.confirmed:
        return AppColors.primary; // Backward compatibility
      case BookingStatus.inProgress:
        return AppColors.secondary;
      case BookingStatus.completed:
        return AppColors.success;
      case BookingStatus.cancelled:
        return AppColors.error;
    }
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.assigned:
        return 'Assigned';
      case BookingStatus.enRoute:
        return 'En Route';
      case BookingStatus.arrived:
        return 'Arrived';
      case BookingStatus.confirmed:
        return 'Assigned'; // Backward compatibility
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }
}

