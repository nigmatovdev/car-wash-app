import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/models/booking_model.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../providers/profile_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchUserProfile();
    });
  }

  void _navigateToTracking(BuildContext context) {
    final homeProvider = context.read<HomeProvider>();
    
    // Check if there's an active booking
    BookingModel? bookingToTrack = homeProvider.activeBooking;
    
    // If no active booking, check all bookings for any that can be tracked
    if (bookingToTrack == null) {
      final bookings = homeProvider.bookings;
      try {
        bookingToTrack = bookings.firstWhere(
          (b) => b.status != BookingStatus.completed && 
                 b.status != BookingStatus.cancelled &&
                 (b.washer != null || b.status == BookingStatus.assigned ||
                  b.status == BookingStatus.enRoute || 
                  b.status == BookingStatus.arrived ||
                  b.status == BookingStatus.inProgress),
        );
      } catch (e) {
        bookingToTrack = null;
      }
    }
    
    if (bookingToTrack != null) {
      // Navigate to tracking page with booking ID
      context.push(RouteConstants.locationPath(bookingToTrack.id));
    } else {
      // No trackable bookings - still allow navigation for demo mode
      // Use the most recent booking if available, or navigate without bookingId
      final recentBooking = homeProvider.bookings.isNotEmpty 
          ? homeProvider.bookings.first 
          : null;
      
      if (recentBooking != null) {
        context.push(RouteConstants.locationPath(recentBooking.id));
        Helpers.showSnackBar(
          context,
          'No active tracking available. Demo mode will be available.',
        );
      } else {
        // No bookings at all - navigate to location page
        context.push(RouteConstants.location);
        Helpers.showSnackBar(
          context,
          'No bookings found. Create a booking to track your washer.',
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authProvider = context.read<AuthProvider>();
      await authProvider.logout();
      if (mounted) {
        context.go(RouteConstants.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          if (profileProvider.isLoading && profileProvider.user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = profileProvider.user;

          return RefreshIndicator(
            onRefresh: () => profileProvider.fetchUserProfile(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Profile Picture
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              backgroundImage: user?.avatar != null
                                  ? NetworkImage(user!.avatar!)
                                  : null,
                              child: user?.avatar == null
                                  ? Text(
                                      Helpers.getInitials(user?.fullName ?? 'U'),
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // User Name
                        Text(
                          user?.fullName ?? 'User',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Email
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Edit Button
                        OutlinedButton.icon(
                          onPressed: () {
                            context.push(RouteConstants.editProfile);
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit Profile'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Menu Items
                  _buildMenuSection(
                    context,
                    title: 'Account',
                    items: [
                      _MenuItem(
                        icon: Icons.book_outlined,
                        title: 'My Bookings',
                        onTap: () => context.push(RouteConstants.bookings),
                      ),
                      _MenuItem(
                        icon: Icons.my_location,
                        title: 'Track Washer',
                        onTap: () => _navigateToTracking(context),
                      ),
                      _MenuItem(
                        icon: Icons.payment_outlined,
                        title: 'Payment Methods',
                        onTap: () => context.push(RouteConstants.payments),
                      ),
                      _MenuItem(
                        icon: Icons.location_on_outlined,
                        title: 'Addresses',
                        onTap: () => context.push(RouteConstants.location),
                      ),
                    ],
                  ),

                  _buildMenuSection(
                    context,
                    title: 'Preferences',
                    items: [
                      _MenuItem(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        onTap: () => context.push(RouteConstants.notifications),
                      ),
                      _MenuItem(
                        icon: Icons.settings_outlined,
                        title: 'Settings',
                        onTap: () => context.push(RouteConstants.settings),
                      ),
                    ],
                  ),

                  _buildMenuSection(
                    context,
                    title: 'Support',
                    items: [
                      _MenuItem(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        onTap: () {
                          // TODO: Navigate to help page
                          Helpers.showSnackBar(context, 'Help & Support coming soon!');
                        },
                      ),
                      _MenuItem(
                        icon: Icons.info_outline,
                        title: 'About',
                        onTap: () {
                          showAboutDialog(
                            context: context,
                            applicationName: 'CarWash Pro',
                            applicationVersion: '1.0.0',
                            applicationIcon: const Icon(
                              Icons.local_car_wash,
                              size: 48,
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Logout Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: OutlinedButton(
                      onPressed: _handleLogout,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Logout'),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuSection(
    BuildContext context, {
    required String title,
    required List<_MenuItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: items.map((item) {
              final isLast = items.last == item;
              return ListTile(
                leading: Icon(item.icon, color: AppColors.primary),
                title: Text(item.title),
                trailing: const Icon(Icons.chevron_right),
                onTap: item.onTap,
                shape: isLast
                    ? null
                    : const Border(
                        bottom: BorderSide(color: AppColors.divider),
                      ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}
