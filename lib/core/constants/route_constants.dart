class RouteConstants {
  // Auth Routes
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  
  // Main Routes
  static const String home = '/home';
  static const String services = '/services';
  static const String serviceDetails = '/services/:id';
  static String serviceDetailsPath(String id) => '/services/$id';
  static const String bookings = '/bookings';
  static const String bookingDetails = '/bookings/:id';
  static String bookingDetailsPath(String id) => '/bookings/$id';
  static const String createBooking = '/bookings/create';
  static const String bookingConfirmation = '/booking-confirmation/:id';
  static String bookingConfirmationPath(String id) => '/booking-confirmation/$id';
  static const String payments = '/payments';
  static const String paymentPage = '/payment/:bookingId';
  static String paymentPagePath(String bookingId) => '/payment/$bookingId';
  static const String paymentSuccess = '/payment-success/:paymentId';
  static String paymentSuccessPath(String paymentId, {String? bookingId}) {
    if (bookingId != null) {
      return '/payment-success/$paymentId?bookingId=$bookingId';
    }
    return '/payment-success/$paymentId';
  }
  static const String paymentDetails = '/payments/:id';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String location = '/location';
  static String locationPath(String? bookingId) => bookingId != null 
      ? '/location?bookingId=$bookingId' 
      : '/location';
  
  // Admin Routes
  static const String admin = '/admin';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static const String adminBookings = '/admin/bookings';
  static const String adminServices = '/admin/services';
  
  // Washer Routes
  static const String washerDashboard = '/washer/dashboard';
  static const String washerBookingDetails = '/washer/bookings/:id';
  static String washerBookingDetailsPath(String id) => '/washer/bookings/$id';
  static const String washerProfile = '/washer/profile';
  static const String washerHistory = '/washer/history';
  static const String washerLocationTracker = '/washer/location-tracker';
  
  // Settings
  static const String settings = '/settings';
  static const String notifications = '/notifications';
}

