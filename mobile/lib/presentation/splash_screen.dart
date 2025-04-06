import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile/presentation/connect_screen.dart';
import 'package:mobile/utils/jetbrains_brand_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _networkLinesAnimation;
  
  // Interactive background animation
  Offset? _touchPoint;
  double _touchRadius = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    _networkLinesAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
    ));

    _animationController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const ConnectScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoSize = size.width * 0.3;

    return Scaffold(
      backgroundColor: JetBrandTheme.backgroundDark,
      body: Stack(
        children: [
          // Animated Background
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return CustomPaint(
                size: Size(size.width, size.height),
                painter: SplashGradientPainter(
                  touchPoint: _touchPoint,
                  touchRadius: _touchRadius,
                  animationValue: _animationController.value,
                ),
              );
            },
          ),
          // Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Container
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          width: logoSize,
                          height: logoSize,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                JetBrandTheme.orangeStart,
                                JetBrandTheme.orangeMiddle,
                                JetBrandTheme.magentaEnd,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: JetBrandTheme.orangeMiddle.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Network Lines
                              AnimatedBuilder(
                                animation: _networkLinesAnimation,
                                builder: (context, child) {
                                  return CustomPaint(
                                    size: Size(logoSize, logoSize),
                                    painter: NetworkLinesPainter(
                                      progress: _networkLinesAnimation.value,
                                    ),
                                  );
                                },
                              ),
                              // Connection Dots
                              ...List.generate(4, (index) {
                                final angle = (index * math.pi / 2) + math.pi / 4;
                                final radius = logoSize * 0.3;
                                return Positioned(
                                  left: logoSize / 2 + radius * math.cos(angle) - 6,
                                  top: logoSize / 2 + radius * math.sin(angle) - 6,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.5),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: size.height * 0.04),
                // App Name
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Text(
                        'JetBrains Connect',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size.width * 0.06,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NetworkLinesPainter extends CustomPainter {
  final double progress;

  NetworkLinesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.3;

    for (var i = 0; i < 4; i++) {
      final startAngle = (i * math.pi / 2) + math.pi / 4;
      final endAngle = ((i + 1) * math.pi / 2) + math.pi / 4;
      
      final start = Offset(
        center.dx + radius * math.cos(startAngle),
        center.dy + radius * math.sin(startAngle),
      );
      
      final end = Offset(
        center.dx + radius * math.cos(endAngle),
        center.dy + radius * math.sin(endAngle),
      );

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(end.dx, end.dy);

      final pathMetrics = path.computeMetrics().first;
      final extractPath = pathMetrics.extractPath(
        0.0,
        pathMetrics.length * progress,
      );

      canvas.drawPath(extractPath, paint);
    }
  }

  @override
  bool shouldRepaint(NetworkLinesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class SplashGradientPainter extends CustomPainter {
  final Offset? touchPoint;
  final double touchRadius;
  final double animationValue;

  SplashGradientPainter({
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
  }

  @override
  bool shouldRepaint(SplashGradientPainter oldDelegate) {
    return oldDelegate.touchPoint != touchPoint ||
           oldDelegate.touchRadius != touchRadius ||
           oldDelegate.animationValue != animationValue;
  }
} 