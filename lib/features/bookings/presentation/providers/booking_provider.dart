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
      // Format date as ISO string with time 00:00:00 (backend expects full ISO string)
      final dateString = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
      ).toIso8601String();
      
      // Time is already in HH:mm format
      final timeString = _selectedTimeSlot!;
      
      final response = await _apiClient.post(
        ApiConstants.createBooking,
        data: {
          'serviceId': _selectedService!.id,
          'date': dateString,
          'time': timeString,
          'latitude': _selectedLatitude,
          'longitude': _selectedLongitude,
          if (_selectedAddress != null && _selectedAddress!.isNotEmpty) 'address': _selectedAddress,
          if (_notes != null && _notes!.isNotEmpty) 'notes': _notes,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        _createdBooking = BookingModel.fromJson(response.data);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = response.data;
        _errorMessage = data['message'] ?? 'Failed to create booking';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
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

