import 'service_model.dart';
import 'user_model.dart';

enum BookingStatus {
  pending,
  assigned,
  enRoute,
  arrived,
  confirmed, // Keep for backward compatibility (maps to ASSIGNED)
  inProgress,
  completed,
  cancelled,
}

class BookingModel {
  final String id;
  final String userId;
  final String serviceId;
  final ServiceModel? service;
  final UserModel? user;
  final UserModel? washer; // Washer assigned to this booking
  final DateTime scheduledDate;
  final String? address;
  final double? latitude;
  final double? longitude;
  final BookingStatus status;
  final double totalAmount;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  BookingModel({
    required this.id,
    required this.userId,
    required this.serviceId,
    this.service,
    this.user,
    this.washer,
    required this.scheduledDate,
    this.address,
    this.latitude,
    this.longitude,
    required this.status,
    required this.totalAmount,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });
  
  factory BookingModel.fromJson(Map<String, dynamic> json) {
    try {
      print('🔵 [BOOKING_MODEL] Parsing booking from JSON: $json');
      
      // Parse scheduledDate from date and time fields, or use scheduledDate if available
      DateTime scheduledDate;
      if (json['scheduledDate'] != null) {
        scheduledDate = DateTime.parse(json['scheduledDate'] as String);
      } else if (json['date'] != null && json['time'] != null) {
        final dateStr = json['date'] as String;
        final timeStr = json['time'] as String;
        // Parse date (format: 2024-12-25T00:00:00.000Z or 2024-12-25)
        final datePart = dateStr.split('T')[0];
        final dateParts = datePart.split('-');
        final timeParts = timeStr.split(':');
        scheduledDate = DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
          int.parse(timeParts[0]),
          timeParts.length > 1 ? int.parse(timeParts[1]) : 0,
        );
      } else {
        // Fallback to current date if neither is available
        scheduledDate = DateTime.now();
      }
      
      // Get totalAmount from payment.amount or totalAmount field
      double totalAmount = 0.0;
      if (json['payment'] != null && json['payment']['amount'] != null) {
        totalAmount = (json['payment']['amount'] as num).toDouble();
      } else if (json['totalAmount'] != null) {
        totalAmount = (json['totalAmount'] as num).toDouble();
      } else if (json['service'] != null && json['service']['price'] != null) {
        totalAmount = (json['service']['price'] as num).toDouble();
      }
      
      // Safely parse required fields with null checks
      final id = json['id'] as String? ?? '';
      final userId = json['userId'] as String? ?? '';
      final serviceId = json['serviceId'] as String? ?? '';
      final statusStr = json['status'] as String? ?? 'pending';
      
      if (id.isEmpty) {
        throw Exception('Booking ID is required but was null or empty');
      }
      if (serviceId.isEmpty) {
        throw Exception('Service ID is required but was null or empty');
      }
      
      final booking = BookingModel(
        id: id,
        userId: userId,
        serviceId: serviceId,
        service: json['service'] != null
            ? ServiceModel.fromJson(json['service'] as Map<String, dynamic>)
            : null,
        user: json['user'] != null
            ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
            : null,
        washer: json['washer'] != null
            ? UserModel.fromJson(json['washer'] as Map<String, dynamic>)
            : null,
        scheduledDate: scheduledDate,
        address: json['address'] as String?,
        latitude: json['latitude'] != null
            ? (json['latitude'] as num).toDouble()
            : null,
        longitude: json['longitude'] != null
            ? (json['longitude'] as num).toDouble()
            : null,
        status: _parseStatus(statusStr),
        totalAmount: totalAmount,
        notes: json['notes'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
      );
      
      print('✅ [BOOKING_MODEL] Booking parsed successfully. ID: ${booking.id}');
      return booking;
    } catch (e, stackTrace) {
      print('❌ [BOOKING_MODEL] Error parsing booking: $e');
      print('❌ [BOOKING_MODEL] Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  static BookingStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return BookingStatus.pending;
      case 'ASSIGNED':
        return BookingStatus.assigned;
      case 'EN_ROUTE':
        return BookingStatus.enRoute;
      case 'ARRIVED':
        return BookingStatus.arrived;
      case 'CONFIRMED':
        // Backward compatibility: CONFIRMED maps to ASSIGNED
        return BookingStatus.assigned;
      case 'IN_PROGRESS':
      case 'INPROGRESS':
        return BookingStatus.inProgress;
      case 'COMPLETED':
        return BookingStatus.completed;
      case 'CANCELLED':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.pending;
    }
  }
  
  String get statusString {
    switch (status) {
      case BookingStatus.pending:
        return 'PENDING';
      case BookingStatus.assigned:
        return 'ASSIGNED';
      case BookingStatus.enRoute:
        return 'EN_ROUTE';
      case BookingStatus.arrived:
        return 'ARRIVED';
      case BookingStatus.confirmed:
        // Backward compatibility
        return 'ASSIGNED';
      case BookingStatus.inProgress:
        return 'IN_PROGRESS';
      case BookingStatus.completed:
        return 'COMPLETED';
      case BookingStatus.cancelled:
        return 'CANCELLED';
    }
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'serviceId': serviceId,
      'service': service?.toJson(),
      'user': user?.toJson(),
      'washer': washer?.toJson(),
      'scheduledDate': scheduledDate.toIso8601String(),
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'status': statusString,
      'totalAmount': totalAmount,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
  
  BookingModel copyWith({
    String? id,
    String? userId,
    String? serviceId,
    ServiceModel? service,
    UserModel? user,
    UserModel? washer,
    DateTime? scheduledDate,
    String? address,
    double? latitude,
    double? longitude,
    BookingStatus? status,
    double? totalAmount,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      serviceId: serviceId ?? this.serviceId,
      service: service ?? this.service,
      user: user ?? this.user,
      washer: washer ?? this.washer,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

