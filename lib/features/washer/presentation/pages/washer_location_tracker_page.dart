import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/helpers.dart';

class WasherLocationTrackerPage extends StatefulWidget {
  const WasherLocationTrackerPage({super.key});

  @override
  State<WasherLocationTrackerPage> createState() =>
      _WasherLocationTrackerPageState();
}

class _WasherLocationTrackerPageState extends State<WasherLocationTrackerPage> {
  WebSocketChannel? _channel;
  StreamSubscription<Position>? _positionSub;
  bool _isTracking = false;
  bool _isConnecting = false;
  Position? _lastPosition;
  String? _error;

  @override
  void dispose() {
    _positionSub?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  Future<void> _toggleTracking() async {
    if (_isTracking) {
      await _stopTracking();
    } else {
      await _startTracking();
    }
  }

  Future<void> _startTracking() async {
    setState(() {
      _isConnecting = true;
      _error = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permissions are permanently denied. Please enable them in settings.',
        );
      }

      // Open WebSocket connection
      final uri = Uri.parse('${ApiConstants.wsUrl}/ws/location');
      _channel = WebSocketChannel.connect(uri);

      // Start listening to position updates
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((position) {
        _lastPosition = position;
        _sendLocation(position);
        setState(() {});
      });

      setState(() {
        _isTracking = true;
        _isConnecting = false;
      });

      Helpers.showSuccessSnackBar(
        context,
        'Location tracking started.',
      );
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _error = e.toString();
      });
      Helpers.showErrorSnackBar(
        context,
        'Failed to start tracking: ${e.toString()}',
      );
    }
  }

  Future<void> _stopTracking() async {
    await _positionSub?.cancel();
    await _channel?.sink.close();

    setState(() {
      _isTracking = false;
      _isConnecting = false;
      _positionSub = null;
      _channel = null;
    });

    Helpers.showInfoSnackBar(
      context,
      'Location tracking stopped.',
    );
  }

  void _sendLocation(Position position) {
    if (_channel == null) return;

    try {
      final payload = jsonEncode({
        'event': 'washer:updateLocation',
        'data': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': DateTime.now().toIso8601String(),
        },
      });
      _channel!.sink.add(payload);
    } catch (_) {
      // Ignore JSON / send errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Tracking'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share your live location',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'When tracking is enabled, your location is sent periodically so customers can see you on the map.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isTracking ? Icons.location_on : Icons.location_off,
                        color: _isTracking ? AppColors.success : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isTracking
                              ? 'Tracking is active'
                              : 'Tracking is currently disabled',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_lastPosition != null) ...[
                    Text(
                      'Last position:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lat: ${_lastPosition!.latitude.toStringAsFixed(6)}, '
                      'Lng: ${_lastPosition!.longitude.toStringAsFixed(6)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                          ),
                    ),
                  ] else ...[
                    Text(
                      'No location sent yet.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.error,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isConnecting ? null : _toggleTracking,
                icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
                label: Text(
                  _isTracking
                      ? 'Stop Tracking'
                      : _isConnecting
                          ? 'Starting...'
                          : 'Start Tracking',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor:
                      _isTracking ? AppColors.error : AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

