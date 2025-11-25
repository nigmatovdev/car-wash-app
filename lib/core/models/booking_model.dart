import 'service_model.dart';
import 'user_model.dart';

enum BookingStatus {
  pending,
  confirmed,
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
    return BookingModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      serviceId: json['serviceId'] as String,
      service: json['service'] != null
          ? ServiceModel.fromJson(json['service'] as Map<String, dynamic>)
          : null,
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      address: json['address'] as String?,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      status: _parseStatus(json['status'] as String),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }
  
  static BookingStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return BookingStatus.pending;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'inprogress':
      case 'in_progress':
        return BookingStatus.inProgress;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.pending;
    }
  }
  
  String get statusString {
    switch (status) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.inProgress:
        return 'in_progress';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
    }
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'serviceId': serviceId,
      'service': service?.toJson(),
      'user': user?.toJson(),
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

