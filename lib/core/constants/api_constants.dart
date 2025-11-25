class ApiConstants {
  // Base URLs
  static const String baseUrl = 'http://170.64.168.79';
  static const String wsUrl = 'ws://170.64.168.79';
  
  // API Endpoints
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String logout = '/api/auth/logout';
  static const String refreshToken = '/api/auth/refresh';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String resetPassword = '/api/auth/reset-password';
  
  // User Endpoints
  static const String userProfile = '/api/users/profile';
  static const String updateProfile = '/api/users/profile';
  static const String changePassword = '/api/users/change-password';
  
  // Services Endpoints
  static const String services = '/api/services';
  static const String serviceDetails = '/api/services/{id}';
  
  // Bookings Endpoints
  static const String bookings = '/api/bookings';
  static const String bookingDetails = '/api/bookings/{id}';
  static const String createBooking = '/api/bookings';
  static const String cancelBooking = '/api/bookings/{id}/cancel';
  static const String updateBooking = '/api/bookings/{id}';
  
  // Payments Endpoints
  static const String payments = '/api/payments';
  static const String paymentDetails = '/api/payments/{id}';
  static const String processPayment = '/api/payments/process';
  
  // Location Endpoints
  static const String locations = '/api/locations';
  static const String nearbyLocations = '/api/locations/nearby';
  
  // Admin Endpoints
  static const String adminUsers = '/api/admin/users';
  static const String adminBookings = '/api/admin/bookings';
  static const String adminServices = '/api/admin/services';
  static const String adminStats = '/api/admin/stats';
  
  // Headers
  static const String contentType = 'application/json';
  static const String authorization = 'Authorization';
  static const String bearer = 'Bearer';
}

