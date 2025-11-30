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
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/dialogs/confirm_dialog.dart';
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
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  void _cancelBooking() {
    ConfirmDialog.show(
      context,
      title: 'Cancel Booking',
      message: 'Are you sure you want to cancel this booking?',
      confirmText: 'Cancel Booking',
      cancelText: 'Keep Booking',
      onConfirm: () {
        // TODO: Implement cancel booking API call
        Helpers.showSnackBar(context, 'Cancel booking functionality coming soon!');
      },
    );
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
                    child: Text(
                      _getStatusText(booking.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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

                  if (booking.address != null) ...[
                    const SizedBox(height: 24),
                    // Map View
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

                  // Washer Info (if assigned)
                  if (booking.user != null) ...[
                    const SizedBox(height: 24),
                    _buildSection(
                      context,
                      'Washer Information',
                      [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: booking.user!.avatar != null
                                  ? NetworkImage(booking.user!.avatar!)
                                  : null,
                              child: booking.user!.avatar == null
                                  ? Text(
                                      booking.user!.fullName[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
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
                                    booking.user!.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    booking.user!.phone ?? 'No phone',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.phone),
                              onPressed: () {
                                // TODO: Implement phone call
                                Helpers.showSnackBar(
                                  context,
                                  'Call functionality coming soon!',
                                );
                              },
                            ),
                          ],
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
                        'Status',
                        'Pending',
                        Icons.payment,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        context,
                        'Amount',
                        Formatters.formatCurrency(booking.totalAmount),
                        Icons.attach_money,
                        isAmount: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Actions
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
}

