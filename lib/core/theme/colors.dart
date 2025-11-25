import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF050A30);
  static const Color primaryDark = Color(0xFF090979);
  static const Color primaryLight = Color(0xFF1B1B3A);
  
  // Secondary Colors
  static const Color secondary = Color(0xFF00D4FF);
  static const Color secondaryDark = Color(0xFF0099CC);
  static const Color secondaryLight = Color(0xFF66E5FF);
  
  // Accent Colors
  static const Color accent = Color(0xFFFF6B35);
  static const Color accentLight = Color(0xFFFF8C61);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  
  // Neutral Colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);
  
  // Border Colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFE0E0E0);
  
  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF050A30),
      Color(0xFF090979),
      Color(0xFF1B1B3A),
    ],
  );
}

