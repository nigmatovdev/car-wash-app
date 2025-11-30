import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'core/storage/local_storage.dart';
import 'shared/services/notification_service.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/home/presentation/providers/home_provider.dart';
import 'features/services/presentation/providers/service_provider.dart';
import 'features/bookings/presentation/providers/booking_provider.dart';
import 'features/profile/presentation/providers/profile_provider.dart';
import 'features/washer/presentation/providers/washer_provider.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => WasherProvider()),
      ],
      child: MaterialApp.router(
        title: 'CarWash Pro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        routerConfig: AppRouter.router,
      ),
    );
  }
  
  // Initialize app services
  static Future<void> initialize() async {
    // Initialize local storage
    await LocalStorage.init();
    
    // Initialize notifications
    await NotificationService.initialize();
    
    // TODO: Initialize other services
  }
  
  // Initialize providers after app starts
  static Future<void> initializeProviders(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initialize();
  }
}

