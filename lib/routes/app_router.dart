import 'package:go_router/go_router.dart';
import '../../core/constants/route_constants.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/services/presentation/pages/services_list_page.dart';
import '../../features/services/presentation/pages/service_details_page.dart';
import '../../features/bookings/presentation/pages/create_booking_page.dart';
import '../../features/bookings/presentation/pages/booking_confirmation_page.dart';
import '../../features/bookings/presentation/pages/booking_details_page.dart';
import '../../features/bookings/presentation/pages/my_bookings_page.dart';
import '../../features/bookings/presentation/pages/live_tracking_page.dart';
import '../../features/payments/presentation/pages/payments_page.dart';
import '../../features/payments/presentation/pages/payment_page.dart';
import '../../features/payments/presentation/pages/payment_success_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/settings_page.dart';
import '../../features/location/presentation/pages/location_page.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/washer/presentation/pages/washer_dashboard_page.dart';
import '../../features/washer/presentation/pages/washer_booking_details_page.dart';
import '../../features/washer/presentation/pages/washer_profile_page.dart';
import '../../features/washer/presentation/pages/washer_history_page.dart';
import '../../features/washer/presentation/pages/washer_location_tracker_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import 'route_guards.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: RouteConstants.splash,
    redirect: (context, state) async => await RouteGuards.globalRedirect(context, state),
    routes: [
      // Splash
      GoRoute(
        path: RouteConstants.splash,
        builder: (context, state) => const SplashPage(),
      ),
      
      // Onboarding
      GoRoute(
        path: RouteConstants.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      
      // Auth Routes
      GoRoute(
        path: RouteConstants.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RouteConstants.register,
        builder: (context, state) => const RegisterPage(),
      ),
      
      // Main Routes
      GoRoute(
        path: RouteConstants.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: RouteConstants.services,
        builder: (context, state) => const ServicesListPage(),
      ),
      GoRoute(
        path: RouteConstants.serviceDetails,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ServiceDetailsPage(serviceId: id);
        },
      ),
      GoRoute(
        path: RouteConstants.bookings,
        builder: (context, state) => const MyBookingsPage(),
      ),
      // IMPORTANT: createBooking must come BEFORE bookingDetails to avoid route conflict
      // Otherwise /bookings/create matches /bookings/:id with id="create"
      GoRoute(
        path: RouteConstants.createBooking,
        builder: (context, state) {
          final serviceId = state.uri.queryParameters['serviceId'];
          return CreateBookingPage(serviceId: serviceId);
        },
      ),
      GoRoute(
        path: RouteConstants.bookingDetails,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BookingDetailsPage(bookingId: id);
        },
      ),
      GoRoute(
        path: RouteConstants.bookingConfirmation,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BookingConfirmationPage(bookingId: id);
        },
      ),
      GoRoute(
        path: RouteConstants.payments,
        builder: (context, state) => const PaymentsPage(),
      ),
      GoRoute(
        path: RouteConstants.paymentPage,
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId']!;
          return PaymentPage(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: RouteConstants.paymentSuccess,
        builder: (context, state) {
          final paymentId = state.pathParameters['paymentId']!;
          final bookingId = state.uri.queryParameters['bookingId'];
          return PaymentSuccessPage(
            paymentId: paymentId,
            bookingId: bookingId,
          );
        },
      ),
      GoRoute(
        path: RouteConstants.profile,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: RouteConstants.editProfile,
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: RouteConstants.settings,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: RouteConstants.notifications,
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: RouteConstants.location,
        builder: (context, state) {
          final bookingId = state.uri.queryParameters['bookingId'];
          if (bookingId != null) {
            return LiveTrackingPage(bookingId: bookingId);
          }
          return const LocationPage();
        },
      ),
      
      // Admin Routes
      GoRoute(
        path: RouteConstants.adminDashboard,
        builder: (context, state) => const AdminDashboardPage(),
      ),
      
      // Washer Routes
      GoRoute(
        path: RouteConstants.washerDashboard,
        builder: (context, state) => const WasherDashboardPage(),
      ),
      GoRoute(
        path: RouteConstants.washerBookingDetails,
        builder: (context, state) {
          final bookingId = state.pathParameters['id']!;
          return WasherBookingDetailsPage(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: RouteConstants.washerProfile,
        builder: (context, state) => const WasherProfilePage(),
      ),
      GoRoute(
        path: RouteConstants.washerHistory,
        builder: (context, state) => const WasherHistoryPage(),
      ),
      GoRoute(
        path: RouteConstants.washerLocationTracker,
        builder: (context, state) => const WasherLocationTrackerPage(),
      ),
    ],
  );
}
