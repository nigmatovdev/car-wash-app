import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/route_constants.dart';
import '../core/storage/secure_storage.dart';

class RouteGuards {
  static final SecureStorage _storage = SecureStorage();
  
  // Global redirect - checks authentication
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
      return RouteConstants.home;
    }
    
    return null; // No redirect needed
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
        path == RouteConstants.splash;
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

