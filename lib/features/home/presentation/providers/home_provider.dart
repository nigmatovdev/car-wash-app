import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/service_model.dart';
import '../../../../core/models/booking_model.dart';

class HomeProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  UserModel? _user;
  List<ServiceModel> _services = [];
  List<BookingModel> _bookings = [];
  BookingModel? _activeBooking;
  bool _isLoading = false;
  String? _errorMessage;
  
  UserModel? get user => _user;
  List<ServiceModel> get services => _services;
  List<BookingModel> get bookings => _bookings;
  BookingModel? get activeBooking => _activeBooking;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Fetch user info
  Future<void> fetchUserInfo() async {
    try {
      final response = await _apiClient.get(ApiConstants.userProfile);
      if (response.statusCode == 200) {
        _user = UserModel.fromJson(response.data);
        notifyListeners();
      }
    } catch (e) {
      // Handle error silently
    }
  }
  
  // Fetch services
  Future<void> fetchServices() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiClient.get(ApiConstants.services);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['data'] ?? response.data['services'] ?? []);
        
        _services = data
            .map((json) => ServiceModel.fromJson(json))
            .where((service) => service.isActive && service.name.isNotEmpty)
            .toList();
        
        _isLoading = false;
        notifyListeners();
      } else {
        _errorMessage = 'Failed to load services';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to load services: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Fetch user bookings
  Future<void> fetchBookings() async {
    try {
      final response = await _apiClient.get('${ApiConstants.bookings}/me');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['data'] ?? response.data['bookings'] ?? []);
        
        _bookings = data
            .map((json) => BookingModel.fromJson(json))
            .toList();
        
        // Find active booking
        try {
          _activeBooking = _bookings.firstWhere(
            (booking) => booking.status == BookingStatus.inProgress ||
                booking.status == BookingStatus.confirmed,
          );
        } catch (e) {
          _activeBooking = null;
        }
        
        notifyListeners();
      }
    } catch (e) {
      // Handle error silently
    }
  }
  
  // Initialize home data
  Future<void> initialize() async {
    await Future.wait([
      fetchUserInfo(),
      fetchServices(),
      fetchBookings(),
    ]);
  }
  
  // Refresh all data
  Future<void> refresh() async {
    await initialize();
  }
}

