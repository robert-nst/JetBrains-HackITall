import 'package:flutter/material.dart';

class JetBrandTheme {
  // Brand Colors from the logo
  static const Color orangeStart = Color(0xFFFF8A00);
  static const Color orangeMiddle = Color(0xFFFF4E50);
  static const Color magentaEnd = Color(0xFFFF00A0);
  
  // Background and Surface Colors
  static const Color backgroundDark = Color(0xFF1E1E1E);
  static const Color surfaceDark = Color(0xFF2B2B2B);
  static const Color elevatedSurfaceDark = Color(0xFF3C3F41);
  
  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFAFB1B3);
  
  // Brand Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [orangeStart, orangeMiddle, magentaEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [orangeMiddle, magentaEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  
  // Text Styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -0.5,
  );
  
  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    letterSpacing: 0.1,
  );
  
  // Input Decoration
  static InputDecoration inputDecoration({required String label, required Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: textSecondary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: elevatedSurfaceDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: orangeMiddle,
          width: 2,
        ),
      ),
    );
  }
  
  // Button Style
  static ButtonStyle primaryButtonStyle = ButtonStyle(
    padding: MaterialStateProperty.all(
      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    ),
    shape: MaterialStateProperty.all(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevation: MaterialStateProperty.all(0),
    backgroundColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.disabled)) {
        return elevatedSurfaceDark;
      }
      return orangeMiddle;
    }),
    foregroundColor: MaterialStateProperty.all(textPrimary),
  );
} 