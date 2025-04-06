import 'package:flutter/material.dart';

class JetBrainsTheme {
  // Primary colors
  static const Color primaryBlue = Color(0xFF049DD9);
  static const Color primaryDarkBlue = Color(0xFF055BA6);
  static const Color primaryDarkerBlue = Color(0xFF023E73);
  
  // Background colors
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF2B2B2B);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF3C3F41);
  
  // Accent colors
  static const Color accentGreen = Color(0xFF12E195);
  static const Color accentPurple = Color(0xFFAD88C6);
  static const Color accentOrange = Color(0xFFFFBE98);
  static const Color accentRed = Color(0xFFFF6B6B);
  
  // Text colors
  static const Color textPrimaryLight = Color(0xFF000000);
  static const Color textSecondaryLight = Color(0xFF666666);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFA7A7A7);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryDarkBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentGreen, accentPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Text styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );
  
  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );
  
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.2,
  );
  
  // Button styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryBlue,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    elevation: 2,
  );
  
  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: surfaceLight,
    foregroundColor: primaryBlue,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: primaryBlue),
    ),
    elevation: 0,
  );
  
  // Card style
  static BoxDecoration cardDecoration = BoxDecoration(
    color: surfaceLight,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
} 