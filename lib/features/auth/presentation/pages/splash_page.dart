import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/theme/colors.dart';
import '../providers/auth_provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  final SecureStorage _storage = SecureStorage();

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );
    
    // Start animation
    _animationController.forward();
    
    // Check authentication and navigate
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for animation to complete
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (!mounted) return;
    
    // Check if user is authenticated
    final token = await _storage.getToken();
    final isAuthenticated = token != null && token.isNotEmpty;
    
    if (!mounted) return;
    
    // Check if onboarding is completed
    final onboardingCompleted = await LocalStorage.getBool('onboarding_completed') ?? false;
    
    if (!mounted) return;
    
    // Navigate based on authentication and onboarding status
    if (isAuthenticated) {
      // Get user role and navigate to appropriate dashboard
      final authProvider = context.read<AuthProvider>();
      
      // Ensure user data is loaded
      if (authProvider.user == null) {
        await authProvider.getCurrentUser();
      }
      
      // Wait a bit more if still loading
      int retries = 0;
      while (authProvider.isLoading && retries < 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        retries++;
        if (!mounted) return;
      }
      
      if (!mounted) return;
      
      final user = authProvider.user;
      if (user != null) {
        final role = user.role.toLowerCase();
        if (role == 'washer' || role == 'washers') {
          if (mounted) context.go(RouteConstants.washerDashboard);
        } else if (role == 'admin' || role == 'administrator') {
          if (mounted) context.go(RouteConstants.adminDashboard);
        } else {
          if (mounted) context.go(RouteConstants.home);
        }
      } else {
        // Fallback to home if user can't be fetched
        if (mounted) context.go(RouteConstants.home);
      }
    } else if (!onboardingCompleted) {
      if (mounted) context.go(RouteConstants.onboarding);
    } else {
      if (mounted) context.go(RouteConstants.login);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Animation
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_car_wash,
                          size: 60,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              // App Name
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Tagline
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'Professional Car Wash Services',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    letterSpacing: 1,
                  ),
                ),
              ),
              
              const SizedBox(height: 80),
              
              // Loading Indicator
              FadeTransition(
                opacity: _fadeAnimation,
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // App Version
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Version ${AppConstants.appVersion}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

