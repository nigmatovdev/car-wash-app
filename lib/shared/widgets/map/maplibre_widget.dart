import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/colors.dart';

/// Map widget for displaying maps using flutter_map
class MapLibreWidget extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final double initialZoom;
  final bool enableCurrentLocation;
  final bool enableMarkerOnTap;
  final bool enableMarkerOnLongPress;
  final Function(double latitude, double longitude)? onLocationSelected;
  final Function(MapController)? onMapCreated;
  final List<MapMarker>? markers;
  final MapPolyline? polyline;
  final bool showMyLocationButton;
  final bool compassEnabled;
  final bool scrollGesturesEnabled;
  final bool zoomGesturesEnabled;
  final bool rotateGesturesEnabled;
  final bool tiltGesturesEnabled;

  const MapLibreWidget({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialZoom = 14.0,
    this.enableCurrentLocation = false,
    this.enableMarkerOnTap = false,
    this.enableMarkerOnLongPress = true,
    this.onLocationSelected,
    this.onMapCreated,
    this.markers,
    this.polyline,
    this.showMyLocationButton = true,
    this.compassEnabled = true,
    this.scrollGesturesEnabled = true,
    this.zoomGesturesEnabled = true,
    this.rotateGesturesEnabled = true,
    this.tiltGesturesEnabled = true,
  });

  @override
  State<MapLibreWidget> createState() => MapLibreWidgetState();
}

class MapLibreWidgetState extends State<MapLibreWidget> {
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];
  Marker? _washerMarker;
  Marker? _destinationMarker;
  bool _hasNetworkError = false;

  @override
  void initState() {
    super.initState();
    widget.onMapCreated?.call(_mapController);
    
    // Add initial markers if any
    if (widget.markers != null) {
      for (final marker in widget.markers!) {
        _addMarker(
          marker.latitude,
          marker.longitude,
          iconImage: marker.iconImage,
        );
      }
    }
    
    // Check for network errors after a short delay
    // This helps catch cases where the emulator has no internet
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_hasNetworkError) {
        // If we still haven't detected network, show fallback
        // This is a safety net for emulators without internet
        setState(() {
          _hasNetworkError = false; // Reset to allow map to try loading
        });
      }
    });
  }

  /// Move camera to a specific location
  Future<void> moveCamera(double latitude, double longitude, {double? zoom}) async {
    _mapController.move(
      LatLng(latitude, longitude),
      zoom ?? widget.initialZoom,
    );
  }

  /// Add a marker at a specific location
  Marker? addMarker(
    double latitude,
    double longitude, {
    String? iconImage,
    Map<String, dynamic>? data,
  }) {
    return _addMarker(latitude, longitude, iconImage: iconImage);
  }

  Marker _addMarker(double latitude, double longitude, {String? iconImage, Color? markerColor, IconData? icon}) {
    final color = markerColor ?? AppColors.error;
    final markerIcon = icon ?? Icons.location_on;
    
    final marker = Marker(
      point: LatLng(latitude, longitude),
      width: 40,
      height: 40,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Icon(markerIcon, color: Colors.white, size: 24),
      ),
    );
    
    setState(() {
      _markers.add(marker);
    });
    
    return marker;
  }
  
  /// Add a marker with custom color and icon
  Marker? addCustomMarker(
    double latitude,
    double longitude, {
    Color? color,
    IconData? icon,
  }) {
    return _addMarker(latitude, longitude, markerColor: color, icon: icon);
  }

  /// Remove a marker
  void removeMarker(Marker marker) {
    setState(() {
      _markers.remove(marker);
    });
  }

  /// Clear all markers
  void clearMarkers() {
    setState(() {
      _markers.clear();
      _washerMarker = null;
      _destinationMarker = null;
    });
  }

  /// Update selected marker
  void updateSelectedMarker(double latitude, double longitude) {
    clearMarkers();
    _addMarker(latitude, longitude);
  }
  
  /// Add washer location marker (for tracking) - replaces existing washer marker
  void addWasherMarker(double latitude, double longitude) {
    // Remove existing washer marker if it exists
    if (_washerMarker != null) {
      _markers.remove(_washerMarker);
    }
    // Add new washer marker
    _washerMarker = _addMarker(latitude, longitude, markerColor: AppColors.secondary, icon: Icons.directions_car);
    setState(() {});
  }
  
  /// Add destination marker (for booking location) - replaces existing destination marker
  void addDestinationMarker(double latitude, double longitude) {
    // Remove existing destination marker if it exists
    if (_destinationMarker != null) {
      _markers.remove(_destinationMarker);
    }
    // Add new destination marker
    _destinationMarker = _addMarker(latitude, longitude, markerColor: AppColors.error, icon: Icons.location_on);
    setState(() {});
  }

  /// Draw a polyline between points
  void drawPolyline(List<LatLng> points) {
    // Polylines are handled via widget.polyline
    setState(() {});
  }

  /// Clear polyline
  void clearPolyline() {
    setState(() {});
  }

  /// Get the map controller
  MapController get controller => _mapController;

  void _onTap(TapPosition position, LatLng point) {
    if (widget.enableMarkerOnTap) {
      updateSelectedMarker(point.latitude, point.longitude);
      widget.onLocationSelected?.call(point.latitude, point.longitude);
    }
  }

  void _onLongPress(TapPosition position, LatLng point) {
    if (widget.enableMarkerOnLongPress) {
      updateSelectedMarker(point.latitude, point.longitude);
      widget.onLocationSelected?.call(point.latitude, point.longitude);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Default to a central location if not provided
    final initialLat = widget.initialLatitude ?? 37.7749;
    final initialLng = widget.initialLongitude ?? -122.4194;

    return Stack(
      children: [
        // Show map or fallback UI
        if (_hasNetworkError)
          // Fallback UI when network fails
          Container(
            color: Colors.grey[200],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.wifi_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Map unavailable',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please check your internet connection',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Show location marker and coordinates even without map
                  if (widget.initialLatitude != null && widget.initialLongitude != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Lat: ${widget.initialLatitude!.toStringAsFixed(6)}\nLng: ${widget.initialLongitude!.toStringAsFixed(6)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )
        else
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(initialLat, initialLng),
            initialZoom: widget.initialZoom,
            onTap: widget.enableMarkerOnTap ? _onTap : null,
            onLongPress: widget.enableMarkerOnLongPress ? _onLongPress : null,
            interactionOptions: InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
              // OpenStreetMap tiles with error handling
              // Note: OSM recommends NOT using subdomains
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.carwash.app',
              maxZoom: 19,
                errorTileCallback: (tile, error, stackTrace) {
                  // Handle tile loading errors gracefully
                  // Check if it's a network/DNS error
                  final errorStr = error.toString().toLowerCase();
                  if (errorStr.contains('host lookup') || 
                      errorStr.contains('socket') ||
                      errorStr.contains('network') ||
                      errorStr.contains('failed')) {
                    if (mounted && !_hasNetworkError) {
                      // Set error state immediately for network issues
                      setState(() {
                        _hasNetworkError = true;
                      });
                    }
                  }
                  debugPrint('Tile loading error: $error');
                },
            ),
            
            // Polylines
            if (widget.polyline != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: widget.polyline!.points,
                    strokeWidth: widget.polyline!.width,
                    color: _parseColor(widget.polyline!.color),
                  ),
                ],
              ),
            
            // Markers
            MarkerLayer(
              markers: _markers,
            ),
          ],
        ),

        // Center marker overlay (always visible at center)
        if (widget.enableMarkerOnTap || widget.enableMarkerOnLongPress)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Icon(
                Icons.location_pin,
                size: 48,
                color: AppColors.error,
              ),
            ),
          ),
      ],
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppColors.primary;
    }
  }
}

/// Map marker model
class MapMarker {
  final double latitude;
  final double longitude;
  final String? iconImage;
  final Map<String, dynamic>? data;

  MapMarker({
    required this.latitude,
    required this.longitude,
    this.iconImage,
    this.data,
  });
}

/// Map polyline model
class MapPolyline {
  final List<LatLng> points;
  final String color;
  final double width;

  MapPolyline({
    required this.points,
    this.color = '#1976D2',
    this.width = 4.0,
  });
}
