import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/route_constants.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/services/presentation/pages/services_page.dart';
import '../../features/bookings/presentation/pages/bookings_page.dart';
import '../../features/payments/presentation/pages/payments_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/location/presentation/pages/location_page.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
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
        builder: (context, state) => const ServicesPage(),
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
        builder: (context, state) => const BookingsPage(),
      ),
      GoRoute(
        path: RouteConstants.bookingDetails,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BookingDetailsPage(bookingId: id);
        },
      ),
      GoRoute(
        path: RouteConstants.createBooking,
        builder: (context, state) => const CreateBookingPage(),
      ),
      GoRoute(
        path: RouteConstants.payments,
        builder: (context, state) => const PaymentsPage(),
      ),
      GoRoute(
        path: RouteConstants.profile,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: RouteConstants.location,
        builder: (context, state) => const LocationPage(),
      ),
      
      // Admin Routes
      GoRoute(
        path: RouteConstants.adminDashboard,
        builder: (context, state) => const AdminDashboardPage(),
      ),
    ],
  );
}

// Placeholder pages that need to be created
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Register Page'),
      ),
    );
  }
}

class ServiceDetailsPage extends StatelessWidget {
  final String serviceId;
  
  const ServiceDetailsPage({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service Details')),
      body: Center(
        child: Text('Service ID: $serviceId'),
      ),
    );
  }
}

class BookingDetailsPage extends StatelessWidget {
  final String bookingId;
  
  const BookingDetailsPage({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: Center(
        child: Text('Booking ID: $bookingId'),
      ),
    );
  }
}

class CreateBookingPage extends StatelessWidget {
  const CreateBookingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Booking')),
      body: const Center(
        child: Text('Create Booking Page'),
      ),
    );
  }
}

