import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/models/booking_model.dart';

class WasherStats {
  final int todayBookings;
  final double earningsToday;
  final int completedBookings;
  final double? rating;

  WasherStats({
    required this.todayBookings,
    required this.earningsToday,
    required this.completedBookings,
    this.rating,
  });

  factory WasherStats.fromJson(Map<String, dynamic> json) {
    return WasherStats(
      todayBookings: json['todayBookings'] as int? ?? 0,
      earningsToday: (json['earningsToday'] as num?)?.toDouble() ?? 0.0,
      completedBookings: json['completedBookings'] as int? ?? 0,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
    );
  }
}

class WasherProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  // State
  bool _isLoading = false;
  String? _errorMessage;
  WasherStats? _stats;
  List<BookingModel> _availableBookings = [];
  List<BookingModel> _activeBookings = [];
  List<BookingModel> _upcomingBookings = [];
  List<BookingModel> _todayBookings = [];
  List<BookingModel> _tomorrowBookings = [];
  List<BookingModel> _allBookings = []; // All bookings for history
  
  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  WasherStats? get stats => _stats;
  List<BookingModel> get availableBookings => _availableBookings;
  List<BookingModel> get activeBookings => _activeBookings;
  List<BookingModel> get upcomingBookings => _upcomingBookings;
  List<BookingModel> get todayBookings => _todayBookings;
  List<BookingModel> get tomorrowBookings => _tomorrowBookings;
  List<BookingModel> get allBookings => _allBookings;
  
  // Initialize and fetch all data
  Future<void> initialize() async {
    await Future.wait([
      fetchAvailableBookings(),
      fetchBookings(),
    ]);
    // Stats are calculated from bookings, so fetchBookings will update stats
  }
  
  // Fetch available bookings (PENDING status - not yet assigned)
  Future<void> fetchAvailableBookings() async {
    try {
      final response = await _apiClient.get(ApiConstants.availableBookings);
      if (response.statusCode == 200) {
        final data = response.data;
        List<BookingModel> bookings = [];
        
        if (data is List) {
          bookings = data.map((json) => BookingModel.fromJson(json)).toList();
        } else if (data is Map && data['bookings'] != null) {
          bookings = (data['bookings'] as List)
              .map((json) => BookingModel.fromJson(json))
              .toList();
        } else if (data is Map && data['data'] != null) {
          bookings = (data['data'] as List)
              .map((json) => BookingModel.fromJson(json))
              .toList();
        }
        
        _availableBookings = bookings;
        notifyListeners();
      }
    } catch (e) {
      print('❌ [WASHER_PROVIDER] Error fetching available bookings: $e');
      // Don't set error, just log it
    }
  }
  
  // Accept a booking (changes status from PENDING to ASSIGNED)
  Future<bool> acceptBooking(String bookingId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final endpoint = ApiConstants.acceptBooking.replaceAll('{id}', bookingId);
      final response = await _apiClient.patch(endpoint, data: {});
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Refresh both available and assigned bookings
        await Future.wait([
          fetchAvailableBookings(),
          fetchBookings(),
        ]);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception('Failed to accept booking');
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to accept booking: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  // Calculate stats from bookings
  void _calculateStats(List<BookingModel> allBookings) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Today's bookings
    final todayBookingsList = allBookings.where((booking) {
      final bookingDate = DateTime(
        booking.scheduledDate.year,
        booking.scheduledDate.month,
        booking.scheduledDate.day,
      );
      return bookingDate.isAtSameMomentAs(today);
    }).toList();
    
    // Completed bookings (all time, but we'll show today's completed)
    final completedToday = allBookings.where((booking) {
      final bookingDate = DateTime(
        booking.scheduledDate.year,
        booking.scheduledDate.month,
        booking.scheduledDate.day,
      );
      return booking.status == BookingStatus.completed &&
             bookingDate.isAtSameMomentAs(today);
    }).toList();
    
    // Calculate earnings today (from completed bookings today)
    double earningsToday = 0.0;
    for (final booking in completedToday) {
      earningsToday += booking.totalAmount;
    }
    
    // Calculate average rating (if available in booking data)
    // For now, we'll set it to null as rating might come from a different source
    double? rating;
    
    _stats = WasherStats(
      todayBookings: todayBookingsList.length,
      earningsToday: earningsToday,
      completedBookings: completedToday.length,
      rating: rating,
    );
  }
  
  // Fetch washer bookings (uses same endpoint as customers - server filters by role)
  Future<void> fetchBookings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Use /bookings/me endpoint - server automatically filters by user role
      // If user is a washer, they get bookings assigned to them
      final response = await _apiClient.get('${ApiConstants.bookings}/me');
      if (response.statusCode == 200) {
        final data = response.data;
        List<BookingModel> allBookings = [];
        
        if (data is List) {
          allBookings = data.map((json) => BookingModel.fromJson(json)).toList();
        } else if (data is Map && data['bookings'] != null) {
          allBookings = (data['bookings'] as List)
              .map((json) => BookingModel.fromJson(json))
              .toList();
        } else if (data is Map && data['data'] != null) {
          allBookings = (data['data'] as List)
              .map((json) => BookingModel.fromJson(json))
              .toList();
        }
        
        // Store all bookings for history
        _allBookings = allBookings;
        
        // Calculate stats from bookings
        _calculateStats(allBookings);
        
        // Filter bookings by status and date
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        
        _activeBookings = allBookings.where((booking) {
          return booking.status == BookingStatus.assigned ||
                 booking.status == BookingStatus.enRoute ||
                 booking.status == BookingStatus.arrived ||
                 booking.status == BookingStatus.inProgress;
        }).toList();
        
        _upcomingBookings = allBookings.where((booking) {
          return (booking.status == BookingStatus.assigned ||
                  booking.status == BookingStatus.enRoute ||
                  booking.status == BookingStatus.arrived) &&
                 booking.scheduledDate.isAfter(now);
        }).toList();
        
        _todayBookings = allBookings.where((booking) {
          final bookingDate = DateTime(
            booking.scheduledDate.year,
            booking.scheduledDate.month,
            booking.scheduledDate.day,
          );
          return bookingDate.isAtSameMomentAs(today);
        }).toList();
        
        _tomorrowBookings = allBookings.where((booking) {
          final bookingDate = DateTime(
            booking.scheduledDate.year,
            booking.scheduledDate.month,
            booking.scheduledDate.day,
          );
          return bookingDate.isAtSameMomentAs(tomorrow);
        }).toList();
        
        _isLoading = false;
        notifyListeners();
      } else {
        throw Exception('Failed to fetch bookings');
      }
    } catch (e) {
      print('❌ [WASHER_PROVIDER] Error fetching bookings: $e');
      _isLoading = false;
      _errorMessage = 'Failed to load bookings: ${e.toString()}';
      notifyListeners();
    }
  }
  
  // Update booking status
  Future<bool> updateBookingStatus(String bookingId, BookingStatus newStatus) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final statusMap = {
        BookingStatus.pending: 'PENDING',
        BookingStatus.assigned: 'ASSIGNED',
        BookingStatus.enRoute: 'EN_ROUTE',
        BookingStatus.arrived: 'ARRIVED',
        BookingStatus.confirmed: 'ASSIGNED', // Backward compatibility
        BookingStatus.inProgress: 'IN_PROGRESS',
        BookingStatus.completed: 'COMPLETED',
        BookingStatus.cancelled: 'CANCELLED',
      };
      
      final endpoint = ApiConstants.updateBookingStatus.replaceAll('{id}', bookingId);
      final response = await _apiClient.patch(
        endpoint,
        data: {
          'status': statusMap[newStatus],
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Refresh bookings
        await fetchBookings();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception('Failed to update booking status');
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to update status: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  // Refresh all data
  Future<void> refresh() async {
    await Future.wait([
      fetchAvailableBookings(),
      fetchBookings(),
    ]);
  }
}

