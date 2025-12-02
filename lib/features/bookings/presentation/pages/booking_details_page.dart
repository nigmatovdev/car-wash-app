import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/models/booking_model.dart';
import '../../../../shared/services/notification_service.dart';
import '../../../../core/models/user_model.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/dialogs/confirm_dialog.dart';
import '../../../../shared/widgets/map/maplibre_widget.dart';
import '../../../home/presentation/providers/home_provider.dart';

class BookingDetailsPage extends StatefulWidget {
  final String bookingId;

  const BookingDetailsPage({
    super.key,
    required this.bookingId,
  });

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  BookingModel? _booking;
  bool _isLoading = true;
  String? _errorMessage;
  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    print('🔵 [BOOKING_DETAILS] Loading booking with ID: ${widget.bookingId}');
    
    // Validate booking ID
    if (widget.bookingId.isEmpty || widget.bookingId == 'create' || widget.bookingId.contains('create')) {
      print('❌ [BOOKING_DETAILS] Invalid booking ID: ${widget.bookingId}');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid booking ID';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // First try to get from local list
      final homeProvider = context.read<HomeProvider>();
      try {
        _booking = homeProvider.bookings.firstWhere(
          (b) => b.id == widget.bookingId,
        );
        print('✅ [BOOKING_DETAILS] Found booking in local list');
        setState(() {
          _isLoading = false;
        });
        return;
      } catch (e) {
        print('🔵 [BOOKING_DETAILS] Booking not in local list, fetching from API...');
        // Not in list, fetch from API
      }

      // Fetch directly from API
      final endpoint = ApiConstants.bookingDetails.replaceAll('{id}', widget.bookingId);
      print('🔵 [BOOKING_DETAILS] Fetching from endpoint: $endpoint');
      
      final response = await _apiClient.get(endpoint);
      
      print('🔵 [BOOKING_DETAILS] Response status: ${response.statusCode}');
      print('🔵 [BOOKING_DETAILS] Response data type: ${response.data.runtimeType}');
      print('🔵 [BOOKING_DETAILS] Response data: ${response.data}');
      
      if (response.statusCode == 200) {
        try {
          // Check if this is the ignored response from interceptor
          if (response.data is Map && (response.data as Map)['ignored'] == true) {
            print('⚠️ [BOOKING_DETAILS] Received ignored response, booking not found');
            setState(() {
              _isLoading = false;
              _errorMessage = 'Booking not found. Please try again.';
            });
            return;
          }
          
          // Ensure response.data is a Map
          final data = response.data is Map<String, dynamic> 
              ? response.data 
              : response.data as Map<String, dynamic>;
          
          // Validate that this is actually a booking response
          if (!data.containsKey('id') || data['id'] == null) {
            print('❌ [BOOKING_DETAILS] Invalid booking response: missing ID');
            setState(() {
              _isLoading = false;
              _errorMessage = 'Invalid booking data received';
            });
            return;
          }
          
          print('🔵 [BOOKING_DETAILS] Parsing booking data...');
          print('🔵 [BOOKING_DETAILS] Booking ID in response: ${data['id']}');
          print('🔵 [BOOKING_DETAILS] User ID in response: ${data['userId']}');
          print('🔵 [BOOKING_DETAILS] Service ID in response: ${data['serviceId']}');
          print('🔵 [BOOKING_DETAILS] Status in response: ${data['status']}');
          
          _booking = BookingModel.fromJson(data);
          print('✅ [BOOKING_DETAILS] Booking loaded successfully');
          setState(() {
            _isLoading = false;
          });
        } catch (e, stackTrace) {
          print('❌ [BOOKING_DETAILS] Error parsing booking: $e');
          print('❌ [BOOKING_DETAILS] Stack trace: $stackTrace');
          setState(() {
            _isLoading = false;
            _errorMessage = 'Failed to parse booking data: ${e.toString()}';
          });
        }
      } else {
        print('❌ [BOOKING_DETAILS] Failed to load booking. Status: ${response.statusCode}');
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load booking details';
        });
      }
    } catch (e, stackTrace) {
      print('❌ [BOOKING_DETAILS] Exception loading booking: $e');
      print('❌ [BOOKING_DETAILS] Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Booking not found. Please try again.';
      });
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
  
  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.assigned:
        return Colors.blue;
      case BookingStatus.enRoute:
        return Colors.purple;
      case BookingStatus.arrived:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.blue; // Backward compatibility
      case BookingStatus.inProgress:
        return Colors.purple;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
    }
  }

  Future<void> _deleteBooking() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Booking',
      message: 'Are you sure you want to delete this cancelled booking? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Keep',
    );
    
    if (confirmed != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final endpoint = ApiConstants.deleteBooking.replaceAll('{id}', widget.bookingId);
      print('🔵 [BOOKING_DETAILS] Deleting booking: $endpoint');
      
      final response = await _apiClient.delete(endpoint);
      
      print('🔵 [BOOKING_DETAILS] Delete response: ${response.statusCode}');
      print('🔵 [BOOKING_DETAILS] Delete response data: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Refresh bookings list
        final homeProvider = context.read<HomeProvider>();
        homeProvider.fetchBookings();
        
        if (mounted) {
          Helpers.showSuccessSnackBar(context, 'Booking deleted successfully');
          NotificationService.showNotification(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: 'Booking deleted',
            body: 'Your cancelled booking has been removed.',
          );
          // Navigate back after a short delay
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              context.pop();
            }
          });
        }
      } else {
        throw Exception('Failed to delete booking: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [BOOKING_DETAILS] Error deleting booking: $e');
      String errorMessage = 'Failed to delete booking. Please try again.';
      
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('403') || errorStr.contains('forbidden')) {
        errorMessage = 'You do not have permission to delete this booking.';
      } else if (errorStr.contains('404')) {
        errorMessage = 'Booking not found.';
      }
      
      if (mounted) {
        Helpers.showErrorSnackBar(context, errorMessage);
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelBooking() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Cancel Booking',
      message: 'Are you sure you want to cancel this booking? This action cannot be undone.',
      confirmText: 'Cancel Booking',
      cancelText: 'Keep Booking',
    );
    
    if (confirmed != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Use the customer-facing cancel endpoint
      // This allows customers to cancel their own bookings
      final endpoint = ApiConstants.cancelBooking.replaceAll('{id}', widget.bookingId);
      print('🔵 [BOOKING_DETAILS] Cancelling booking: $endpoint');
      
      // Cancel endpoint uses PATCH method
      final response = await _apiClient.patch(
        endpoint,
        data: {}, // Empty body or specific cancel data if required
      );
      
      print('🔵 [BOOKING_DETAILS] Cancel response: ${response.statusCode}');
      print('🔵 [BOOKING_DETAILS] Cancel response data: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Update booking status immediately in UI
        if (_booking != null) {
          setState(() {
            // Create a new booking model with cancelled status
            _booking = BookingModel(
              id: _booking!.id,
              userId: _booking!.userId,
              serviceId: _booking!.serviceId,
              service: _booking!.service,
              user: _booking!.user,
              scheduledDate: _booking!.scheduledDate,
              address: _booking!.address,
              latitude: _booking!.latitude,
              longitude: _booking!.longitude,
              status: BookingStatus.cancelled,
              totalAmount: _booking!.totalAmount,
              notes: _booking!.notes,
              createdAt: _booking!.createdAt,
              updatedAt: DateTime.now(),
            );
            _isLoading = false;
          });
        }
        
        // Reload booking to get full updated data from server
        _loadBooking();
        
        // Refresh bookings list
        final homeProvider = context.read<HomeProvider>();
        homeProvider.fetchBookings();
        
        if (mounted) {
          Helpers.showSuccessSnackBar(context, 'Booking cancelled successfully');
          NotificationService.showNotification(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: 'Booking cancelled',
            body: 'Your booking has been cancelled successfully.',
          );
        }
      } else {
        throw Exception('Failed to cancel booking: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [BOOKING_DETAILS] Error cancelling booking: $e');
      String errorMessage = 'Failed to cancel booking. Please try again.';
      
      // Provide more specific error messages
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('washer') || errorStr.contains('admin') || errorStr.contains('access required')) {
        errorMessage = 'You do not have permission to cancel this booking. Only the booking creator can cancel it.';
      } else if (errorStr.contains('403') || errorStr.contains('forbidden')) {
        errorMessage = 'You do not have permission to cancel this booking.';
      } else if (errorStr.contains('404')) {
        errorMessage = 'Booking not found.';
      } else if (errorStr.contains('400') || errorStr.contains('bad request')) {
        errorMessage = 'Cannot cancel this booking. It may already be completed or cancelled.';
      }
      
      if (mounted) {
        Helpers.showErrorSnackBar(context, errorMessage);
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_booking == null || _errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Booking not found',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Retry',
                onPressed: _loadBooking,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
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
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Helpers.showSnackBar(context, 'Share functionality coming soon!');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: Column(
                children: [
                  Text(
                    'Booking ID',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    booking.id.substring(0, 8).toUpperCase(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getStatusColor(booking.status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getStatusText(booking.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (booking.createdAt != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Created: ${Formatters.formatDisplayDate(booking.createdAt!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Info
                  _buildSection(
                    context,
                    'Service Information',
                    [
                      if (booking.service != null) ...[
                        _buildInfoCard(
                          context,
                          'Service',
                          booking.service!.name,
                          Icons.local_car_wash,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          context,
                          'Description',
                          booking.service!.description,
                          Icons.description,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          context,
                          'Duration',
                          '${booking.service!.duration} minutes',
                          Icons.access_time,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          context,
                          'Price',
                          Formatters.formatCurrency(booking.service!.price),
                          Icons.attach_money,
                          isAmount: true,
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Booking Details
                  _buildSection(
                    context,
                    'Booking Details',
                    [
                      _buildInfoCard(
                        context,
                        'Date',
                        Formatters.formatDisplayDate(booking.scheduledDate),
                        Icons.calendar_today,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        context,
                        'Time',
                        Formatters.formatDisplayTime(booking.scheduledDate),
                        Icons.access_time,
                      ),
                      if (booking.address != null) ...[
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          context,
                          'Location',
                          booking.address!,
                          Icons.location_on,
                        ),
                      ],
                    ],
                  ),

                  if (booking.latitude != null && booking.longitude != null) ...[
                    const SizedBox(height: 24),
                    // Map View
                    _buildSection(
                      context,
                      'Location Map',
                      [
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
                    ),
                  ],

                  // Customer Info
                  if (booking.user != null) ...[
                    const SizedBox(height: 24),
                    _buildSection(
                      context,
                      'Customer Information',
                      [
                        _buildUserCard(
                          context,
                          booking.user!,
                          showContact: false, // Customer viewing their own booking
                        ),
                      ],
                    ),
                  ],

                  // Washer Info (if assigned)
                  if (booking.washer != null) ...[
                    const SizedBox(height: 24),
                    _buildSection(
                      context,
                      'Assigned Washer',
                      [
                        _buildUserCard(
                          context,
                          booking.washer!,
                          showContact: true,
                        ),
                      ],
                    ),
                  ] else if (booking.status != BookingStatus.pending && 
                             booking.status != BookingStatus.cancelled) ...[
                    const SizedBox(height: 24),
                    _buildSection(
                      context,
                      'Assigned Washer',
                      [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: AppColors.warning),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Washer information will be available once assigned',
                                  style: TextStyle(
                                    color: AppColors.warning,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Payment Info
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    'Payment Information',
                    [
                      _buildInfoCard(
                        context,
                        'Total Amount',
                        Formatters.formatCurrency(booking.totalAmount),
                        Icons.attach_money,
                        isAmount: true,
                      ),
                      if (booking.service != null) ...[
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          context,
                          'Service Price',
                          Formatters.formatCurrency(booking.service!.price),
                          Icons.local_car_wash,
                        ),
                      ],
                    ],
                  ),

                  // Booking Metadata
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    'Booking Information',
                    [
                      _buildInfoCard(
                        context,
                        'Booking ID',
                        booking.id,
                        Icons.tag,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        context,
                        'Status',
                        _getStatusText(booking.status),
                        Icons.info,
                      ),
                      if (booking.createdAt != null) ...[
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          context,
                          'Created At',
                          Formatters.formatDisplayDateTime(booking.createdAt!),
                          Icons.calendar_today,
                        ),
                      ],
                      if (booking.updatedAt != null) ...[
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          context,
                          'Last Updated',
                          Formatters.formatDisplayDateTime(booking.updatedAt!),
                          Icons.update,
                        ),
                      ],
                      if (booking.latitude != null && booking.longitude != null) ...[
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          context,
                          'Coordinates',
                          '${booking.latitude!.toStringAsFixed(6)}, ${booking.longitude!.toStringAsFixed(6)}',
                          Icons.location_on,
                        ),
                      ],
                    ],
                  ),
                  
                  // Notes Section
                  if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSection(
                      context,
                      'Additional Notes',
                      [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            booking.notes!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Actions
                  // Cancel button - only show if NOT cancelled and NOT completed
                  if (booking.status != BookingStatus.cancelled &&
                      booking.status != BookingStatus.completed) ...[
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        text: 'Cancel Booking',
                        onPressed: _cancelBooking,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Delete button - only show for cancelled bookings
                  if (booking.status == BookingStatus.cancelled) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _deleteBooking,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete Booking'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: AppColors.error,
                          side: BorderSide(color: AppColors.error),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Track Washer button - only show for in-progress bookings
                  if (booking.status == BookingStatus.inProgress) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.push('${RouteConstants.location}?bookingId=${booking.id}');
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
                    const SizedBox(height: 12),
                  ],

                  // Contact Support button - show for all bookings
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Helpers.showSnackBar(
                          context,
                          'Contact support functionality coming soon!',
                        );
                      },
                      icon: const Icon(Icons.support_agent),
                      label: const Text('Contact Support'),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
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
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
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

  Widget _buildUserCard(
    BuildContext context,
    UserModel user, {
    bool showContact = true,
  }) {
    return Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: user.avatar != null
                  ? NetworkImage(user.avatar!)
                  : null,
              child: user.avatar == null
                  ? Text(
                      user.fullName.isNotEmpty
                          ? user.fullName[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 20,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  if (user.phone != null && user.phone!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          user.phone!,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (user.role.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        user.role.toUpperCase(),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showContact && user.phone != null && user.phone!.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.phone),
                color: AppColors.primary,
                onPressed: () {
                  // TODO: Implement phone call using url_launcher
                  Helpers.showSnackBar(
                    context,
                    'Call functionality coming soon!',
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}

