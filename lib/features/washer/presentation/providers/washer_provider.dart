import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/models/booking_model.dart';
import '../../../../shared/services/notification_service.dart';

class WasherStats {
  final int todayBookings;
  final double earningsToday;
  final int completedBookings;
  final double totalEarnings;
  final double? rating;

  WasherStats({
    required this.todayBookings,
    required this.earningsToday,
    required this.completedBookings,
    required this.totalEarnings,
    this.rating,
  });

  factory WasherStats.fromJson(Map<String, dynamic> json) {
    return WasherStats(
      todayBookings: json['todayBookings'] as int? ?? 0,
      earningsToday: (json['earningsToday'] as num?)?.toDouble() ?? 0.0,
      completedBookings: json['completedBookings'] as int? ?? 0,
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0.0,
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
  List<BookingModel> _completedBookings = []; // Recently completed bookings
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
  List<BookingModel> get completedBookings => _completedBookings;
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
        _availableBookings = _parseBookingsResponse(response.data);
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
        // This will move the accepted booking from available to active
        await Future.wait([
          fetchAvailableBookings(),
          fetchBookings(),
        ]);
        _isLoading = false;
        notifyListeners();

        // Local notification
        NotificationService.showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: 'Booking accepted',
          body: 'You have accepted a new booking.',
        );

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
    
    // Today's bookings (any status)
    final todayBookingsList = allBookings.where((booking) {
      final bookingDate = DateTime(
        booking.scheduledDate.year,
        booking.scheduledDate.month,
        booking.scheduledDate.day,
      );
      return bookingDate.isAtSameMomentAs(today);
    }).toList();
    
    // Completed bookings today
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

    // Total earnings from all completed bookings
    double totalEarnings = 0.0;
    for (final booking in allBookings) {
      if (booking.status == BookingStatus.completed) {
        totalEarnings += booking.totalAmount;
      }
    }
    
    // Calculate average rating (if available in booking data)
    // For now, we'll set it to null as rating might come from a different source
    double? rating;
    
    _stats = WasherStats(
      todayBookings: todayBookingsList.length,
      earningsToday: earningsToday,
      completedBookings: completedToday.length,
      totalEarnings: totalEarnings,
      rating: rating,
    );
  }
  
  // Fetch washer bookings using dedicated washer endpoints
  Future<void> fetchBookings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Fetch active bookings and full history in parallel
      final responses = await Future.wait([
        _apiClient.get(ApiConstants.washerActiveBookings),
        _apiClient.get(ApiConstants.washerHistory),
      ]);

      final activeResponse = responses[0];
      final historyResponse = responses[1];

      if (activeResponse.statusCode == 200 && historyResponse.statusCode == 200) {
        final activeData = activeResponse.data;
        final historyData = historyResponse.data;

        final activeBookings = _parseBookingsResponse(activeData);
        final historyBookings = _parseBookingsResponse(historyData);

        // Merge active + history, de-duplicate by ID
        final Map<String, BookingModel> allMap = {};
        for (final booking in [...historyBookings, ...activeBookings]) {
          allMap[booking.id] = booking;
        }
        final allBookings = allMap.values.toList();
        
        // Store all bookings for history & filters
        _allBookings = allBookings;
        
        // Calculate stats from all bookings (completed & today)
        _calculateStats(allBookings);
        
        // Filter bookings by status and date
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        final last7Days = today.subtract(const Duration(days: 7));
        
        // Active Bookings: use active endpoint result (safety filter by status)
        _activeBookings = activeBookings.where((booking) {
          return booking.status == BookingStatus.assigned ||
                 booking.status == BookingStatus.enRoute ||
                 booking.status == BookingStatus.arrived ||
                 booking.status == BookingStatus.inProgress;
        }).toList();
        
        // Upcoming Bookings: assigned/enRoute/arrived status and scheduled in the future
        _upcomingBookings = allBookings.where((booking) {
          return (booking.status == BookingStatus.assigned ||
                  booking.status == BookingStatus.enRoute ||
                  booking.status == BookingStatus.arrived) &&
                 booking.scheduledDate.isAfter(now);
        }).toList();
        
        // Today's Schedule: all bookings scheduled for today (including completed, excluding cancelled)
        _todayBookings = allBookings.where((booking) {
          final bookingDate = DateTime(
            booking.scheduledDate.year,
            booking.scheduledDate.month,
            booking.scheduledDate.day,
          );
          return bookingDate.isAtSameMomentAs(today) &&
                 booking.status != BookingStatus.cancelled;
        }).toList();
        
        // Tomorrow's Schedule: all bookings scheduled for tomorrow (excluding cancelled)
        _tomorrowBookings = allBookings.where((booking) {
          final bookingDate = DateTime(
            booking.scheduledDate.year,
            booking.scheduledDate.month,
            booking.scheduledDate.day,
          );
          return bookingDate.isAtSameMomentAs(tomorrow) &&
                 booking.status != BookingStatus.cancelled;
        }).toList();
        
        // Completed Bookings: recently completed (last 7 days, limit to 10 most recent)
        _completedBookings = allBookings.where((booking) {
          return booking.status == BookingStatus.completed &&
                 booking.scheduledDate.isAfter(last7Days);
        }).toList()
          ..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate)); // Most recent first
        if (_completedBookings.length > 10) {
          _completedBookings = _completedBookings.take(10).toList();
        }
        
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
        // Refresh bookings to update status in lists
        await Future.wait([
          fetchAvailableBookings(),
          fetchBookings(),
        ]);
        _isLoading = false;
        notifyListeners();
        // Local notification for status change
        NotificationService.showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: 'Booking status updated',
          body: 'Status changed to ${newStatus.name.toUpperCase()}.',
        );
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

  // Helper: parse bookings response that can be list or wrapped in map
  List<BookingModel> _parseBookingsResponse(dynamic data) {
    if (data is List) {
      return data.map((json) => BookingModel.fromJson(json)).toList();
    } else if (data is Map && data['bookings'] != null) {
      return (data['bookings'] as List)
          .map((json) => BookingModel.fromJson(json))
          .toList();
    } else if (data is Map && data['data'] != null) {
      return (data['data'] as List)
          .map((json) => BookingModel.fromJson(json))
          .toList();
    }
    return [];
  }
}

