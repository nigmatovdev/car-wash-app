import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'core/storage/local_storage.dart';
import 'shared/services/notification_service.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CarWash Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: AppRouter.router,
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
}

