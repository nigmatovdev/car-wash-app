import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../../core/models/booking_model.dart';
import '../../../../shared/widgets/map/maplibre_widget.dart';

class LiveTrackingPage extends StatefulWidget {
  final String bookingId;

  const LiveTrackingPage({
    super.key,
    required this.bookingId,
  });

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  BookingModel? _booking;
  WebSocketChannel? _channel;
  StreamSubscription? _wsSubscription;
  double? _washerLat;
  double? _washerLng;
  String? _statusMessage;
  final GlobalKey<MapLibreWidgetState> _mapKey =
      GlobalKey<MapLibreWidgetState>();

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  void _loadBooking() {
    final homeProvider = context.read<HomeProvider>();
    try {
      _booking = homeProvider.bookings.firstWhere(
        (b) => b.id == widget.bookingId,
      );
      setState(() {});
      _connectWebSocket();
    } catch (e) {
      homeProvider.fetchBookings().then((_) {
        try {
          _booking = homeProvider.bookings.firstWhere(
            (b) => b.id == widget.bookingId,
          );
          setState(() {});
          _connectWebSocket();
        } catch (e) {
          // Still not found
        }
      });
    }
  }

  void _connectWebSocket() {
    if (_booking == null) return;

    try {
      final uri = Uri.parse('${ApiConstants.wsUrl}/ws/location');
      _channel = WebSocketChannel.connect(uri);

      _wsSubscription = _channel!.stream.listen((event) {
        try {
          final data = jsonDecode(event as String);
          if (data is Map &&
              data['event'] == 'washer:locationUpdated' &&
              data['data'] is Map) {
            final eventData = data['data'] as Map;

            // Optional: filter by bookingId if provided in payload
            if (eventData['bookingId'] != null &&
                eventData['bookingId'] != widget.bookingId) {
              return;
            }

            final lat = (eventData['latitude'] as num?)?.toDouble();
            final lng = (eventData['longitude'] as num?)?.toDouble();
            if (lat != null && lng != null) {
              setState(() {
                _washerLat = lat;
                _washerLng = lng;
                _statusMessage = 'Washer is on the way';
              });

              // Move map marker to new washer location
              _mapKey.currentState?.updateSelectedMarker(lat, lng);
              _mapKey.currentState?.moveCamera(lat, lng, zoom: 15.5);
            }
          }
        } catch (_) {
          // Ignore JSON / parsing errors
        }
      }, onError: (error) {
        setState(() {
          _statusMessage = 'Disconnected from live tracking';
        });
      });

      setState(() {
        _statusMessage = 'Connected to live tracking';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Unable to connect to live tracking';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Tracking')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final booking = _booking!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Washer'),
      ),
      body: Stack(
        children: [
          // Map View
          Positioned.fill(
            child: MapLibreWidget(
              key: _mapKey,
              initialLatitude: booking.latitude,
              initialLongitude: booking.longitude,
              initialZoom: 14.5,
              enableMarkerOnTap: false,
              enableMarkerOnLongPress: false,
              markers: [
                if (booking.latitude != null && booking.longitude != null)
                  MapMarker(
                    latitude: booking.latitude!,
                    longitude: booking.longitude!,
                  ),
              ],
              showMyLocationButton: false,
            ),
          ),

          // ETA / status Display (Top)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Washer Status',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _statusMessage ?? 'Waiting for live location...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.directions_car,
                      color: AppColors.success,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Washer Info Card (Bottom Sheet)
          DraggableScrollableSheet(
            initialChildSize: 0.35,
            minChildSize: 0.25,
            maxChildSize: 0.7,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          // Washer Info
                          if (booking.user != null) ...[
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
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.success.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'En Route',
                                              style: TextStyle(
                                                color: AppColors.success,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.phone),
                                  onPressed: () {
                                    Helpers.showSnackBar(
                                      context,
                                      'Call functionality coming soon!',
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Status Timeline
                          Text(
                            'Status',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          _buildTimelineItem(
                            'Booking Created',
                            Formatters.formatDisplayDateTime(booking.createdAt ?? DateTime.now()),
                            true,
                          ),
                          _buildTimelineItem(
                            'Washer Assigned',
                            'Just now',
                            true,
                          ),
                          _buildTimelineItem(
                            'Washer En Route',
                            'In progress',
                            true,
                          ),
                          _buildTimelineItem(
                            'Washer Arrived',
                            'Pending',
                            false,
                          ),
                          _buildTimelineItem(
                            'Service In Progress',
                            'Pending',
                            false,
                          ),
                          _buildTimelineItem(
                            'Service Completed',
                            'Pending',
                            false,
                          ),

                          const SizedBox(height: 24),

                          // Service Info
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (booking.service != null) ...[
                                  Text(
                                    booking.service!.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Duration: ${booking.service!.duration} minutes',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String time, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? AppColors.success : AppColors.border,
            ),
            child: isCompleted
                ? const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                    color: isCompleted ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

