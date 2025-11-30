import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }
  
  // Check location permissions
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }
  
  // Request location permissions
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }
  
  // Get current position
  Future<Position> getCurrentPosition() async {
    try {
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable location services in your device settings.');
      }
      
      LocationPermission permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied. Please grant location permissions to use this feature.');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied. Please enable them in your device settings.');
      }
      
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      // Re-throw with more context if it's not already our custom exception
      if (e.toString().contains('permission') || e.toString().contains('location')) {
        rethrow;
      }
      throw Exception('Failed to get current location: ${e.toString()}');
    }
  }
  
  // Get address from coordinates with retry and timeout handling
  Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    const maxRetries = 3;
    const timeoutDuration = Duration(seconds: 15);
    
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        // Use timeout to prevent hanging
        final placemarks = await placemarkFromCoordinates(
          latitude,
          longitude,
        ).timeout(
          timeoutDuration,
          onTimeout: () {
            throw TimeoutException(
              'Address lookup timed out after ${timeoutDuration.inSeconds} seconds',
              timeoutDuration,
            );
          },
        );
        
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          // Build address string, handling null values
          final parts = <String>[];
          if (place.street != null && place.street!.isNotEmpty) {
            parts.add(place.street!);
          }
          if (place.locality != null && place.locality!.isNotEmpty) {
            parts.add(place.locality!);
          }
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
            parts.add(place.administrativeArea!);
          }
          if (place.postalCode != null && place.postalCode!.isNotEmpty) {
            parts.add(place.postalCode!);
          }
          
          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
          
          // Fallback: use country or coordinates
          if (place.country != null && place.country!.isNotEmpty) {
            return '${place.country} (${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)})';
          }
        }
        
        // If we got here, no placemarks or empty placemarks
        return _formatCoordinatesAsAddress(latitude, longitude);
      } on TimeoutException {
        if (attempt == maxRetries - 1) {
          // Last attempt failed, return coordinates as address
          return _formatCoordinatesAsAddress(latitude, longitude);
        }
        // Wait before retry (exponential backoff)
        await Future.delayed(Duration(seconds: attempt + 1));
        continue;
      } catch (e) {
        // Check if it's a network/IO error
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('timeout') || 
            errorString.contains('deadline') ||
            errorString.contains('io_error') ||
            errorString.contains('network')) {
          if (attempt == maxRetries - 1) {
            // Last attempt failed, return coordinates as address
            return _formatCoordinatesAsAddress(latitude, longitude);
          }
          // Wait before retry
          await Future.delayed(Duration(seconds: attempt + 1));
          continue;
        }
        // For other errors, throw immediately
        throw Exception('Failed to get address: $e');
      }
    }
    
    // Should never reach here, but just in case
    return _formatCoordinatesAsAddress(latitude, longitude);
  }
  
  // Format coordinates as a readable address when geocoding fails
  String _formatCoordinatesAsAddress(double latitude, double longitude) {
    return 'Location: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }
  
  // Get coordinates from address
  Future<Position> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return Position(
          latitude: locations[0].latitude,
          longitude: locations[0].longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }
      throw Exception('No location found for address');
    } catch (e) {
      throw Exception('Failed to get coordinates: $e');
    }
  }
  
  // Calculate distance between two points
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
}

