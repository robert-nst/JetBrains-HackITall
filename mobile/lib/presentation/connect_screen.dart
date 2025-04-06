import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile/data/connection_storage.dart';
import 'package:mobile/presentation/connected_screen.dart';
import 'package:mobile/utils/app_constants.dart';
import 'package:mobile/utils/dialog_widgets.dart';
import 'package:mobile/utils/jetbrains_brand_theme.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../data/provider/connection_provider.dart';

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> with SingleTickerProviderStateMixin {
  final TextEditingController urlController = TextEditingController();
  late AnimationController _backgroundAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  
  bool _showSubtitle = false;
  bool _showForm = false;
  
  // Interactive background animation
  Offset? _touchPoint;
  double _touchRadius = 0;
  
  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _touchPoint = details.localPosition;
      _touchRadius = 150.0; // Initial radius when touching
    });
  }
  
  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _touchRadius = 0; // Reset radius when touch ends
    });
  }
  
  @override
  void initState() {
    super.initState();
    _backgroundAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    _scaleAnimation = Tween<double>(
      begin: 0.98,
      end: 1.02,
    ).animate(
      CurvedAnimation(
        parent: _backgroundAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _rotateAnimation = Tween<double>(
      begin: -0.1,
      end: 0.1,
    ).animate(
      CurvedAnimation(
        parent: _backgroundAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Delayed animations
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() => _showSubtitle = true);
      }
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() => _showForm = true);
      }
    });
  }
  
  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  // UI: QR Scanner Dialog
  void _showQRScannerDialog(BuildContext context) {
    final scannerController = MobileScannerController(
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.normal,
    );

    final size = MediaQuery.of(context).size;
    final scannerSize = size.width * 0.7;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async {
          scannerController.dispose();
          return true;
        },
        child: Scaffold(
          backgroundColor: JetBrandTheme.backgroundDark,
          body: Stack(
            children: [
              // Interactive Gradient Background
              AnimatedBuilder(
                animation: _backgroundAnimationController,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(size.width, size.height),
                    painter: GlowingGradientPainter(
                      touchPoint: _touchPoint,
                      touchRadius: _touchRadius,
                      animationValue: _backgroundAnimationController.value,
                    ),
                  );
                },
              ),
              // Scanner Area with Clean Background
              Center(
                child: Container(
                  width: scannerSize,
                  height: scannerSize,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: JetBrandTheme.orangeMiddle.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        MobileScanner(
                          controller: scannerController,
                          onDetect: (capture) => _captureUrl(capture, context, ref, scannerController),
                        ),
                        // Scanner Frame
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: JetBrandTheme.orangeMiddle,
                              width: 4,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        // Scanner Guide
                        Center(
                          child: Container(
                            width: scannerSize * 0.8,
                            height: scannerSize * 0.8,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: JetBrandTheme.orangeMiddle.withOpacity(0.5),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Header
              Positioned(
                top: MediaQuery.of(context).padding.top + 20,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
                      onPressed: () {
                        scannerController.dispose();
                        Navigator.of(context).pop();
                      },
                    ),
                    Text(
                      'Scan QR Code',
                      style: JetBrandTheme.headingStyle.copyWith(
                        fontSize: size.width * 0.06,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the header
                  ],
                ),
              ),
              // Instructions
              Positioned(
                bottom: size.height * 0.1,
                left: 0,
                right: 0,
                child: Text(
                  'Position the QR code within the frame',
                  style: JetBrandTheme.subheadingStyle.copyWith(
                    fontSize: size.width * 0.035,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final horizontalPadding = size.width * 0.06;
    final logoSize = size.width * 0.22;
    final backgroundLogoSize = size.width * 0.5;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Scaffold(
        backgroundColor: JetBrandTheme.backgroundDark,
        body: Stack(
          children: [
            // Interactive Gradient Background
            AnimatedBuilder(
              animation: _backgroundAnimationController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(size.width, size.height),
                  painter: GlowingGradientPainter(
                    touchPoint: _touchPoint,
                    touchRadius: _touchRadius,
                    animationValue: _backgroundAnimationController.value,
                  ),
                );
              },
            ),
            // Animated Background Text
            AnimatedBuilder(
              animation: _backgroundAnimationController,
              builder: (context, child) {
                return Stack(
                  children: [
                    // Static text instance
                    Positioned(
                      bottom: size.height * 0.05,
                      left: size.width * 0.1,
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            JetBrandTheme.orangeStart.withOpacity(0.15),
                            JetBrandTheme.magentaEnd.withOpacity(0.15),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text(
                          'IntelliJ IDEA',
                          style: TextStyle(
                            fontSize: size.width * 0.15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -2,
                            height: 0.9,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            // Main Content
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // JetBrains Logo
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(seconds: 1),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.9 + (0.1 * value),
                          child: Container(
                            padding: EdgeInsets.all(size.width * 0.04),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.1),
                                  Colors.white.withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: JetBrandTheme.orangeMiddle.withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: SvgPicture.asset(
                              'assets/jetbrains.svg',
                              width: logoSize,
                              height: logoSize,
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: size.height * 0.04),
                    // Animated Text
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 400),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        'Connect to Server',
                        style: JetBrandTheme.headingStyle.copyWith(
                          fontSize: size.width * 0.06,
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.01),
                    // Animated Subtitle
                    AnimatedOpacity(
                      opacity: _showSubtitle ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      child: AnimatedSlide(
                        offset: Offset(0, _showSubtitle ? 0 : 0.2),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        child: Text(
                          'Enter your server URL or scan QR code',
                          style: JetBrandTheme.subheadingStyle.copyWith(
                            fontSize: size.width * 0.035,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.05),
                    // Animated Form
                    AnimatedOpacity(
                      opacity: _showForm ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      child: AnimatedSlide(
                        offset: Offset(0, _showForm ? 0 : 0.2),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        child: Container(
                          width: size.width * 0.88,
                          decoration: BoxDecoration(
                            color: JetBrandTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: JetBrandTheme.elevatedSurfaceDark,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(size.width * 0.06),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: urlController,
                                style: TextStyle(
                                  color: JetBrandTheme.textPrimary,
                                  fontSize: size.width * 0.04,
                                ),
                                decoration: JetBrandTheme.inputDecoration(
                                  label: 'Server URL',
                                  suffixIcon: IconButton(
                                    icon: ShaderMask(
                                      shaderCallback: (bounds) => JetBrandTheme.buttonGradient.createShader(bounds),
                                      child: Icon(
                                        Icons.qr_code_scanner,
                                        color: Colors.white,
                                        size: size.width * 0.06,
                                      ),
                                    ),
                                    onPressed: () => _showQRScannerDialog(context),
                                  ),
                                ),
                              ),
                              SizedBox(height: size.height * 0.03),
                              SizedBox(
                                width: double.infinity,
                                height: size.height * 0.06,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: JetBrandTheme.buttonGradient,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: JetBrandTheme.orangeMiddle.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () => _attemptConnection(context, ref),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: Text(
                                      'Connect',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: size.width * 0.042,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Action
  Future<void> _attemptConnection(BuildContext context, WidgetRef ref) async {
    loadingDialog(context);

    final notifier = ref.read(connectionStatusProvider.notifier);
    final url = urlController.text.trim();

    if (!isValidNgrokUrl(url)) {
      Navigator.pop(context);
      errorDialog(context, "Invalid URL format. Please try again.");
      return;
    }

    final success = await notifier.connect(url);

    if (success) {
      await ConnectionStorage.saveConnectedUrl(url);
      navigateAndReplace(context, ConnectedScreen(url: url));
    } else {
      Navigator.pop(context);
      errorDialog(context, "Could not connect to the server.");
    }
  }

  // Action
  Future<void> _captureUrl(BarcodeCapture capture, BuildContext context, WidgetRef ref, MobileScannerController scannerController) async {
    final raw = capture.barcodes.first.rawValue;
    if (raw != null) {
      scannerController.dispose();
      Navigator.of(context).pop();

      setState(() {
        urlController.text = raw;
      });

      await Future.delayed(const Duration(milliseconds: 300));
      _attemptConnection(context, ref);
    }
  }
}

// Custom Painter for the glowing interactive background
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
