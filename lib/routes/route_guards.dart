import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/constants/route_constants.dart';
import '../core/storage/secure_storage.dart';
import '../features/auth/presentation/providers/auth_provider.dart';

class RouteGuards {
  static final SecureStorage _storage = SecureStorage();
  
  // Global redirect - checks authentication and role
  static Future<String?> globalRedirect(
    BuildContext context,
    GoRouterState state,
  ) async {
    // Don't redirect from splash screen - let it handle navigation
    if (state.uri.path == RouteConstants.splash) {
      return null;
    }
    
    final isLoggedIn = await _isAuthenticated();
    final isAuthRoute = _isAuthRoute(state.uri.path);
    
    // If not logged in and trying to access protected route
    if (!isLoggedIn && !isAuthRoute) {
      return RouteConstants.login;
    }
    
    // If logged in and trying to access auth routes (except splash)
    if (isLoggedIn && isAuthRoute && state.uri.path != RouteConstants.splash) {
      // Check user role and redirect accordingly
      return _getRoleBasedHomeRoute(context);
    }
    
    // Role-based routing for home route
    if (isLoggedIn && state.uri.path == RouteConstants.home) {
      // Try to get user from AuthProvider
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        // If user is not loaded, try to load it
        if (authProvider.user == null && !authProvider.isLoading) {
          await authProvider.getCurrentUser();
          // Wait a bit for user to load
          int retries = 0;
          while (authProvider.isLoading && retries < 10) {
            await Future.delayed(const Duration(milliseconds: 100));
            retries++;
          }
        }
        
        // Check role and redirect
        if (authProvider.user != null) {
          final role = authProvider.user!.role.toLowerCase();
          if (role == 'washer' || role == 'washers') {
            return RouteConstants.washerDashboard;
          }
          if (role == 'admin' || role == 'administrator') {
            return RouteConstants.adminDashboard;
          }
        }
      } catch (e) {
        // Provider not available or error, continue to home
      }
    }
    
    return null; // No redirect needed
  }
  
  // Get home route based on user role
  static Future<String?> _getRoleBasedHomeRoute(BuildContext context) async {
    try {
      // Try to get user from AuthProvider if available
      // Use try-catch because Provider might not be available in redirect context
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.user != null) {
          final role = authProvider.user!.role.toLowerCase();
          if (role == 'washer' || role == 'washers') {
            return RouteConstants.washerDashboard;
          }
          if (role == 'admin' || role == 'administrator') {
            return RouteConstants.adminDashboard;
          }
        }
      } catch (e) {
        // Provider not available, will try API fallback
      }
      
      // Fallback: default to customer home
      // The splash page will handle role-based navigation on app start
      return RouteConstants.home;
    } catch (e) {
      // If we can't determine role, default to customer home
      return RouteConstants.home;
    }
  }
  
  // Check if user is authenticated
  static Future<bool> _isAuthenticated() async {
    try {
      final token = await _storage.getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  // Check if route is an auth route
  static bool _isAuthRoute(String path) {
    return path == RouteConstants.login ||
        path == RouteConstants.register ||
        path == RouteConstants.forgotPassword ||
        path == RouteConstants.resetPassword ||
        path == RouteConstants.splash ||
        path == RouteConstants.onboarding;
  }
  
  // Check if user is admin
  static bool isAdmin() {
    // TODO: Implement admin check
    return false;
  }
  
  // Admin route guard
  static String? adminGuard(BuildContext context, GoRouterState state) {
    if (!isAdmin()) {
      return RouteConstants.home;
    }
    return null;
  }
}

