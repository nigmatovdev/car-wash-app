class ApiConstants {
  // Base URLs
  static const String baseUrl = 'http://170.64.168.79';
  static const String wsUrl = 'ws://170.64.168.79';
  
  // API Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  
  // User Endpoints
  static const String userProfile = '/users/profile';
  static const String userMe = '/users/me';
  static const String updateProfile = '/users/me';
  static const String changePassword = '/users/change-password';
  
  // Services Endpoints
  static const String services = '/services';
  static const String serviceDetails = '/services/{id}';
  
  // Bookings Endpoints
  static const String bookings = '/bookings';
  static const String bookingDetails = '/bookings/{id}';
  static const String createBooking = '/bookings'; // POST /bookings
  static const String cancelBooking = '/bookings/{id}/cancel';
  static const String updateBooking = '/bookings/{id}';
  
  // Payments Endpoints
  static const String payments = '/payments';
  static const String paymentDetails = '/payments/{id}';
  static const String processPayment = '/payments/process';
  
  // Location Endpoints
  static const String locations = '/locations';
  static const String nearbyLocations = '/locations/nearby';
  
  // Admin Endpoints
  static const String adminUsers = '/admin/users';
  static const String adminBookings = '/admin/bookings';
  static const String adminServices = '/admin/services';
  static const String adminStats = '/admin/stats';
  
  // Headers
  static const String contentType = 'application/json';
  static const String authorization = 'Authorization';
  static const String bearer = 'Bearer';
}

