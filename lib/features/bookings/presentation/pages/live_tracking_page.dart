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
  String? _statusMessage;
  final GlobalKey<MapLibreWidgetState> _mapKey =
      GlobalKey<MapLibreWidgetState>();
  
  // Demo mode
  bool _isDemoMode = false;
  Timer? _demoTimer;
  double? _demoWasherLat;
  double? _demoWasherLng;
  int _demoStep = 0;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _channel?.sink.close();
    _demoTimer?.cancel();
    super.dispose();
  }

  void _loadBooking() {
    final homeProvider = context.read<HomeProvider>();
    try {
      _booking = homeProvider.bookings.firstWhere(
        (b) => b.id == widget.bookingId,
      );
      setState(() {});
      _initializeMapMarkers();
      _connectWebSocket();
    } catch (e) {
      homeProvider.fetchBookings().then((_) {
        try {
          _booking = homeProvider.bookings.firstWhere(
            (b) => b.id == widget.bookingId,
          );
          setState(() {});
          _initializeMapMarkers();
          _connectWebSocket();
        } catch (e) {
          // Still not found
        }
      });
    }
  }
  
  void _initializeMapMarkers() {
    // Add destination marker (booking location) after map is ready
    if (_booking?.latitude != null && _booking?.longitude != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapKey.currentState?.addDestinationMarker(
          _booking!.latitude!,
          _booking!.longitude!,
        );
      });
    }
  }

  void _connectWebSocket() {
    if (_booking == null || _isDemoMode) return;

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
              _updateWasherLocation(lat, lng);
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
  
  void _updateWasherLocation(double lat, double lng) {
    setState(() {
      _statusMessage = 'Washer is on the way';
    });

    // Update washer marker (will replace existing washer marker)
    _mapKey.currentState?.addWasherMarker(lat, lng);
    
    // Ensure destination marker is still present
    if (_booking?.latitude != null && _booking?.longitude != null) {
      _mapKey.currentState?.addDestinationMarker(
        _booking!.latitude!,
        _booking!.longitude!,
      );
    }
    
    // Center map between washer and destination
    if (_booking?.latitude != null && _booking?.longitude != null) {
      final centerLat = (lat + _booking!.latitude!) / 2;
      final centerLng = (lng + _booking!.longitude!) / 2;
      _mapKey.currentState?.moveCamera(centerLat, centerLng, zoom: 14.0);
    } else {
      _mapKey.currentState?.moveCamera(lat, lng, zoom: 15.5);
    }
  }
  
  void _startDemoMode() {
    if (_booking?.latitude == null || _booking?.longitude == null) {
      Helpers.showSnackBar(context, 'Booking location not available for demo');
      return;
    }

    setState(() {
      _isDemoMode = true;
      _statusMessage = 'Demo Mode: Simulating washer movement';
      _demoStep = 0;
    });

    // Close WebSocket connection if open
    _wsSubscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _wsSubscription = null;

    // Set starting position (slightly offset from destination for demo)
    final destLat = _booking!.latitude!;
    final destLng = _booking!.longitude!;
    
    // Start from a point ~2km away (simulating washer starting location)
    _demoWasherLat = destLat + 0.018; // ~2km north
    _demoWasherLng = destLng + 0.018; // ~2km east
    
    // Add initial washer marker
    _mapKey.currentState?.addWasherMarker(_demoWasherLat!, _demoWasherLng!);
    
    // Center map between washer and destination
    final centerLat = (_demoWasherLat! + destLat) / 2;
    final centerLng = (_demoWasherLng! + destLng) / 2;
    _mapKey.currentState?.moveCamera(centerLat, centerLng, zoom: 13.0);

    // Start simulation timer (update every 2 seconds)
    _demoTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      _demoStep++;
      
      // Calculate progress (0.0 to 1.0)
      final progress = (_demoStep / 30).clamp(0.0, 1.0); // 30 steps = ~60 seconds
      
      // Interpolate position
      final currentLat = _demoWasherLat! + (destLat - _demoWasherLat!) * progress;
      final currentLng = _demoWasherLng! + (destLng - _demoWasherLng!) * progress;
      
      // Update status message based on progress
      String statusMsg;
      if (progress < 0.3) {
        statusMsg = 'Demo: Washer is on the way';
      } else if (progress < 0.7) {
        statusMsg = 'Demo: Washer is approaching';
      } else if (progress < 0.95) {
        statusMsg = 'Demo: Washer is nearby';
      } else {
        statusMsg = 'Demo: Washer has arrived';
        timer.cancel();
      }
      
      setState(() {
        _statusMessage = statusMsg;
      });
      
      // Update washer marker position (replaces existing washer marker)
      _mapKey.currentState?.addWasherMarker(currentLat, currentLng);
      
      // Ensure destination marker is still present
      _mapKey.currentState?.addDestinationMarker(destLat, destLng);
      
      // Center map between washer and destination
      final centerLat = (currentLat + destLat) / 2;
      final centerLng = (currentLng + destLng) / 2;
      _mapKey.currentState?.moveCamera(centerLat, centerLng, zoom: 14.0);
    });
  }
  
  void _stopDemoMode() {
    _demoTimer?.cancel();
    _demoTimer = null;
    
    setState(() {
      _isDemoMode = false;
      _demoWasherLat = null;
      _demoWasherLng = null;
      _demoStep = 0;
      _statusMessage = 'Demo mode stopped. Connect to real tracking?';
    });
    
    // Clear washer marker
    _mapKey.currentState?.clearMarkers();
    _initializeMapMarkers();
    
    // Try to reconnect to WebSocket
    _connectWebSocket();
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
        actions: [
          if (!_isDemoMode)
            IconButton(
              icon: const Icon(Icons.play_circle_outline),
              tooltip: 'Start Demo',
              onPressed: _startDemoMode,
            ),
        ],
      ),
      floatingActionButton: !_isDemoMode
          ? FloatingActionButton.extended(
              onPressed: _startDemoMode,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Demo'),
              backgroundColor: AppColors.warning,
            )
          : null,
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
                // Destination marker (red pin) - booking location
                if (booking.latitude != null && booking.longitude != null)
                  MapMarker(
                    latitude: booking.latitude!,
                    longitude: booking.longitude!,
                  ),
                ],
              showMyLocationButton: false,
            ),
          ),

          // Status Display (Top)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Status Card
                Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                    color: _isDemoMode ? AppColors.warning.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                    border: _isDemoMode ? Border.all(color: AppColors.warning, width: 2) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
                  child: Column(
                    children: [
                      Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                          Expanded(
                            child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                    children: [
                      Text(
                                      'Washer Status',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                                    ),
                                    if (_isDemoMode) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.warning,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'DEMO',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
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
                      if (_isDemoMode) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _stopDemoMode,
                            icon: const Icon(Icons.stop, size: 18),
                            label: const Text('Stop Demo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Legend
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem(
                        Icons.directions_car,
                        AppColors.secondary,
                        'Washer',
                      ),
                      const SizedBox(width: 16),
                      _buildLegendItem(
                        Icons.location_on,
                        AppColors.error,
                        'Destination',
                      ),
                    ],
                  ),
                ),
              ],
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

  Widget _buildLegendItem(IconData icon, Color color, String label) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(icon, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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

