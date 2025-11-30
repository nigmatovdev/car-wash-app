import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/models/location_model.dart';

/// MapLibre service for map operations
class MapLibreService {
  static MapLibreService? _instance;
  
  // Default map style URL (OpenStreetMap style)
  static const String defaultStyleUrl = 
      'https://demotiles.maplibre.org/style.json';
  
  // Alternative style URLs
  static const String osmBrightStyle = 
      'https://tiles.stadiamaps.com/styles/osm_bright.json';

  factory MapLibreService() {
    _instance ??= MapLibreService._internal();
    return _instance!;
  }

  MapLibreService._internal();

  /// Get the map style URL
  String get styleUrl => defaultStyleUrl;

  /// Reverse geocode coordinates to address using Nominatim (OpenStreetMap)
  Future<LocationModel> reverseGeocode(double latitude, double longitude) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$latitude&lon=$longitude&format=json&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'CarWashApp/1.0',
          'Accept-Language': 'en',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;

        return LocationModel(
          latitude: latitude,
          longitude: longitude,
          address: data['display_name'] as String?,
          street: address?['road'] as String? ?? address?['street'] as String?,
          city: address?['city'] as String? ?? 
                address?['town'] as String? ?? 
                address?['village'] as String?,
          state: address?['state'] as String?,
          postalCode: address?['postcode'] as String?,
          country: address?['country'] as String?,
          timestamp: DateTime.now(),
        );
      } else {
        throw Exception('Failed to reverse geocode: ${response.statusCode}');
      }
    } catch (e) {
      // Return basic location on error
      return LocationModel(
        latitude: latitude,
        longitude: longitude,
        address: 'Lat: ${latitude.toStringAsFixed(4)}, Lng: ${longitude.toStringAsFixed(4)}',
        timestamp: DateTime.now(),
      );
    }
  }

  /// Search for an address and return locations
  Future<List<LocationModel>> searchAddress(String query) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=5',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'CarWashApp/1.0',
          'Accept-Language': 'en',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((item) {
          final address = item['address'] as Map<String, dynamic>?;
          return LocationModel(
            latitude: double.parse(item['lat'] as String),
            longitude: double.parse(item['lon'] as String),
            address: item['display_name'] as String?,
            street: address?['road'] as String? ?? address?['street'] as String?,
            city: address?['city'] as String? ?? 
                  address?['town'] as String? ?? 
                  address?['village'] as String?,
            state: address?['state'] as String?,
            postalCode: address?['postcode'] as String?,
            country: address?['country'] as String?,
            timestamp: DateTime.now(),
          );
        }).toList();
      } else {
        throw Exception('Failed to search address: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  /// Calculate estimated time of arrival (ETA) in minutes
  /// Based on average driving speed
  double calculateETA(
    double startLat,
    double startLng,
    double endLat,
    double endLng, {
    double averageSpeedKmh = 30, // Average city driving speed
  }) {
    // Calculate distance using Haversine formula (simplified)
    final distanceKm = _calculateDistanceKm(startLat, startLng, endLat, endLng);
    final timeHours = distanceKm / averageSpeedKmh;
    final timeMinutes = timeHours * 60;
    return timeMinutes;
  }

  double _calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371;
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat1)) * _cos(_toRadians(lat2)) *
        _sin(dLon / 2) * _sin(dLon / 2);
    
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    
    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) => degrees * 3.14159265359 / 180;
  double _sin(double x) => _sine(x);
  double _cos(double x) => _sine(x + 3.14159265359 / 2);
  double _sqrt(double x) => _power(x, 0.5);
  double _atan2(double y, double x) => _arctangent2(y, x);
  
  // Simple Taylor series approximations
  double _sine(double x) {
    x = x % (2 * 3.14159265359);
    if (x > 3.14159265359) x -= 2 * 3.14159265359;
    double result = x;
    double term = x;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }
  
  double _power(double base, double exp) {
    if (exp == 0.5) {
      // Newton's method for square root
      double guess = base / 2;
      for (int i = 0; i < 20; i++) {
        guess = (guess + base / guess) / 2;
      }
      return guess;
    }
    return base;
  }
  
  double _arctangent2(double y, double x) {
    if (x > 0) return _arctan(y / x);
    if (x < 0 && y >= 0) return _arctan(y / x) + 3.14159265359;
    if (x < 0 && y < 0) return _arctan(y / x) - 3.14159265359;
    if (x == 0 && y > 0) return 3.14159265359 / 2;
    if (x == 0 && y < 0) return -3.14159265359 / 2;
    return 0;
  }
  
  double _arctan(double x) {
    double result = 0;
    double term = x;
    for (int i = 0; i < 50; i++) {
      result += (i % 2 == 0 ? 1 : -1) * term / (2 * i + 1);
      term *= x * x;
    }
    return result;
  }
}

