import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/colors.dart';
import '../../services/maplibre_service.dart';

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
  final MapLibreService _mapService = MapLibreService();
  final List<Marker> _markers = [];

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

  Marker _addMarker(double latitude, double longitude, {String? iconImage}) {
    final marker = Marker(
      point: LatLng(latitude, longitude),
      width: 40,
      height: 40,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.error,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: const Icon(Icons.location_on, color: Colors.white, size: 24),
      ),
    );
    
    setState(() {
      _markers.add(marker);
    });
    
    return marker;
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
    });
  }

  /// Update selected marker
  void updateSelectedMarker(double latitude, double longitude) {
    clearMarkers();
    _addMarker(latitude, longitude);
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
            // OpenStreetMap tiles
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.carwash.app',
              maxZoom: 19,
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
