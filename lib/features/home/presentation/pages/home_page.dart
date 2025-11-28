import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/home_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/home_header.dart';
import '../widgets/quick_actions.dart';
import '../widgets/active_booking_card.dart';
import '../widgets/services_list.dart';
import '../widgets/recent_bookings_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final homeProvider = context.read<HomeProvider>();
      
      // If user is not in AuthProvider, fetch it
      if (authProvider.user == null) {
        authProvider.getCurrentUser();
      }
      
      homeProvider.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<HomeProvider>(
        builder: (context, homeProvider, child) {
          return RefreshIndicator(
            onRefresh: () => homeProvider.refresh(),
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return HomeHeader(
                        userName: authProvider.user?.fullName ?? 
                                 homeProvider.user?.fullName,
                        userAvatar: authProvider.user?.avatar ?? 
                                   homeProvider.user?.avatar,
                      );
                    },
                  ),
                ),

                // Quick Actions
                SliverToBoxAdapter(
                  child: QuickActions(
                    hasActiveBooking: homeProvider.activeBooking != null,
                  ),
                ),

                // Active Booking Card
                if (homeProvider.activeBooking != null)
                  SliverToBoxAdapter(
                    child: ActiveBookingCard(
                      booking: homeProvider.activeBooking!,
                    ),
                  ),

                // Services List
                SliverToBoxAdapter(
                  child: ServicesList(
                    services: homeProvider.services,
                    isLoading: homeProvider.isLoading,
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 24),
                ),

                // Recent Bookings
                SliverToBoxAdapter(
                  child: RecentBookingsList(
                    bookings: homeProvider.bookings,
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 24),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
