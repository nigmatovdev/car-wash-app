import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/models/service_model.dart';
import '../../../../core/models/booking_model.dart';

class BookingProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  // Booking data
  ServiceModel? _selectedService;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  String? _selectedAddress;
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _notes;
  
  // State
  bool _isLoading = false;
  String? _errorMessage;
  BookingModel? _createdBooking;
  
  // Getters
  ServiceModel? get selectedService => _selectedService;
  DateTime? get selectedDate => _selectedDate;
  String? get selectedTimeSlot => _selectedTimeSlot;
  String? get selectedAddress => _selectedAddress;
  double? get selectedLatitude => _selectedLatitude;
  double? get selectedLongitude => _selectedLongitude;
  String? get notes => _notes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  BookingModel? get createdBooking => _createdBooking;
  
  // Check if booking is ready
  bool get isBookingReady {
    return _selectedService != null &&
        _selectedDate != null &&
        _selectedTimeSlot != null &&
        _selectedAddress != null &&
        _selectedLatitude != null &&
        _selectedLongitude != null;
  }
  
  // Calculate total price
  double get totalPrice {
    return _selectedService?.price ?? 0.0;
  }
  
  // Setters
  void setService(ServiceModel service) {
    _selectedService = service;
    notifyListeners();
  }
  
  void setDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }
  
  void setTimeSlot(String timeSlot) {
    _selectedTimeSlot = timeSlot;
    notifyListeners();
  }
  
  void setLocation({
    required String address,
    required double latitude,
    required double longitude,
  }) {
    _selectedAddress = address;
    _selectedLatitude = latitude;
    _selectedLongitude = longitude;
    notifyListeners();
  }
  
  void setNotes(String notes) {
    _notes = notes;
    notifyListeners();
  }
  
  // Create booking
  Future<bool> createBooking() async {
    if (!isBookingReady) {
      _errorMessage = 'Please complete all booking details';
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Format date as YYYY-MM-DD (backend expects date only, not full ISO string)
      final dateString = '${_selectedDate!.year.toString().padLeft(4, '0')}-'
          '${_selectedDate!.month.toString().padLeft(2, '0')}-'
          '${_selectedDate!.day.toString().padLeft(2, '0')}';
      
      // Time is already in HH:mm format
      final timeString = _selectedTimeSlot!;
      
      // Prepare request body exactly as API expects
      final requestBody = {
        'serviceId': _selectedService!.id, // UUID of the selected service
        'latitude': _selectedLatitude,
        'longitude': _selectedLongitude,
        'date': dateString, // Format: "2024-12-25"
        'time': timeString, // Format: "14:30"
      };
      
      print('🔵 [BOOKING] Creating booking...');
      print('🔵 [BOOKING] Request body: $requestBody');
      print('🔵 [BOOKING] Endpoint: ${ApiConstants.createBooking}');
      
      final response = await _apiClient.post(
        ApiConstants.createBooking, // POST /bookings
        data: requestBody,
      );
      
      print('🔵 [BOOKING] Response status: ${response.statusCode}');
      print('🔵 [BOOKING] Response data: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          _createdBooking = BookingModel.fromJson(response.data);
          print('✅ [BOOKING] Booking created successfully!');
          print('✅ [BOOKING] Booking ID: ${_createdBooking!.id}');
          _isLoading = false;
          notifyListeners();
          return true;
        } catch (e) {
          print('❌ [BOOKING] Error parsing booking response: $e');
          _errorMessage = 'Failed to parse booking response: $e';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        final data = response.data;
        _errorMessage = data['message'] ?? 'Failed to create booking';
        print('❌ [BOOKING] Failed to create booking: $_errorMessage');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ [BOOKING] Exception creating booking: $e');
      print('❌ [BOOKING] Stack trace: $stackTrace');
      _errorMessage = _extractErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Clear booking data
  void clear() {
    _selectedService = null;
    _selectedDate = null;
    _selectedTimeSlot = null;
    _selectedAddress = null;
    _selectedLatitude = null;
    _selectedLongitude = null;
    _notes = null;
    _createdBooking = null;
    _errorMessage = null;
    notifyListeners();
  }
  
  String _extractErrorMessage(dynamic error) {
    if (error.toString().contains('DioException')) {
      return 'Network error. Please check your connection.';
    }
    return error.toString();
  }
}

