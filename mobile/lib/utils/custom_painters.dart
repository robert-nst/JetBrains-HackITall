import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mobile/utils/jetbrains_brand_theme.dart';

class GlowingGradientPainter extends CustomPainter {
  final Offset? touchPoint;
  final double touchRadius;
  final double animationValue;

  GlowingGradientPainter({
    this.touchPoint,
    required this.touchRadius,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    
    // Base gradient
    final baseGradient = LinearGradient(
      colors: [
        JetBrandTheme.backgroundDark,
        JetBrandTheme.backgroundDark.withOpacity(0.8),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(rect);
    
    canvas.drawRect(rect, Paint()..shader = baseGradient);

    // Animated circles
    final circleCount = 3;
    for (var i = 0; i < circleCount; i++) {
      final progress = (animationValue + i / circleCount) % 1.0;
      final center = Offset(
        size.width * (0.3 + 0.4 * math.cos(progress * 2 * math.pi)),
        size.height * (0.3 + 0.4 * math.sin(progress * 2 * math.pi)),
      );
      
      final gradient = RadialGradient(
        colors: [
          JetBrandTheme.orangeStart.withOpacity(0.1),
          JetBrandTheme.magentaEnd.withOpacity(0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(
        center: center,
        radius: size.width * 0.3,
      ));
      
      canvas.drawCircle(
        center,
        size.width * 0.3,
        Paint()..shader = gradient,
      );
    }

    // Interactive touch effect
    if (touchPoint != null && touchRadius > 0) {
      final touchGradient = RadialGradient(
        colors: [
          JetBrandTheme.orangeMiddle.withOpacity(0.2),
          JetBrandTheme.magentaEnd.withOpacity(0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(
        center: touchPoint!,
        radius: touchRadius,
      ));
      
      canvas.drawCircle(
        touchPoint!,
        touchRadius,
        Paint()..shader = touchGradient,
      );
    }
  }

  @override
  bool shouldRepaint(GlowingGradientPainter oldDelegate) {
    return oldDelegate.touchPoint != touchPoint ||
           oldDelegate.touchRadius != touchRadius ||
           oldDelegate.animationValue != animationValue;
  }
} 