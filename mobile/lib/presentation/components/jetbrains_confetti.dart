import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class JetBrainsConfetti extends StatefulWidget {
  final bool showConfetti;

  const JetBrainsConfetti({
    super.key,
    required this.showConfetti,
  });

  @override
  State<JetBrainsConfetti> createState() => _JetBrainsConfettiState();
}

class _JetBrainsConfettiState extends State<JetBrainsConfetti> with SingleTickerProviderStateMixin {
  late List<LogoParticle> particles;
  late AnimationController _animationController;
  final random = math.Random();
  final List<ui.Image> _logoImages = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8), // Even slower animation
    );

    // Load all logo images
    _loadImages();

    // Initialize particles
    particles = List.generate(30, (index) => _createParticle());

    // Listen to showConfetti changes
    _handleShowConfetti();
  }

  Future<void> _loadImages() async {
    for (var logoPath in jetBrainsLogos) {
      final ByteData data = await rootBundle.load(logoPath);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _logoImages.add(frame.image);
    }
  }

  @override
  void didUpdateWidget(JetBrainsConfetti oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showConfetti != oldWidget.showConfetti) {
      _handleShowConfetti();
    }
  }

  void _handleShowConfetti() {
    if (widget.showConfetti) {
      particles = List.generate(30, (index) => _createParticle());
      _animationController.forward(from: 0);
    }
  }

  LogoParticle _createParticle() {
    final startX = 0.5; // Center X
    final startY = 0.5; // Center Y
    
    // Random angle in radians
    final angle = random.nextDouble() * 2 * math.pi;
    // Much slower velocity
    final velocity = 0.08 + random.nextDouble() * 0.12;
    // Slower rotation speed
    final rotationSpeed = (random.nextDouble() - 0.5) * math.pi * 0.5;
    // Random logo index
    final logoIndex = random.nextInt(jetBrainsLogos.length);
    // Random size between 32-64 pixels
    final size = 32.0 + random.nextDouble() * 32.0;

    return LogoParticle(
      x: startX,
      y: startY,
      angle: angle,
      velocity: velocity,
      rotationSpeed: rotationSpeed,
      logoIndex: logoIndex,
      size: size,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: ConfettiPainter(
            particles: particles,
            progress: _animationController.value,
            logoImages: _logoImages,
          ),
        );
      },
    );
  }
}

class LogoParticle {
  double x;
  double y;
  final double angle;
  final double velocity;
  final double rotationSpeed;
  final int logoIndex;
  final double size;
  double rotation = 0;

  LogoParticle({
    required this.x,
    required this.y,
    required this.angle,
    required this.velocity,
    required this.rotationSpeed,
    required this.logoIndex,
    required this.size,
  });

  void update(double progress) {
    // Update position based on angle and velocity
    x += math.cos(angle) * velocity * progress;
    y += math.sin(angle) * velocity * progress - progress * progress * 0.8; // Reduced gravity effect
    
    // Update rotation
    rotation += rotationSpeed * progress;
  }
}

class ConfettiPainter extends CustomPainter {
  final List<LogoParticle> particles;
  final double progress;
  final List<ui.Image> logoImages;

  ConfettiPainter({
    required this.particles,
    required this.progress,
    required this.logoImages,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      // Update particle position
      particle.update(progress);

      // Calculate actual position in pixels
      final x = particle.x * size.width;
      final y = particle.y * size.height;

      // Save canvas state
      canvas.save();
      
      // Translate to particle position and apply rotation
      canvas.translate(x, y);
      canvas.rotate(particle.rotation);

      // Draw the actual logo image
      if (particle.logoIndex < logoImages.length) {
        final image = logoImages[particle.logoIndex];
        final imageSize = particle.size;
        final rect = Rect.fromCenter(
          center: Offset.zero,
          width: imageSize,
          height: imageSize,
        );
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          rect,
          Paint(),
        );
      }

      // Restore canvas state
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

// This list will be populated with actual logo asset paths
const jetBrainsLogos = [
  'assets/product-logos/intellij-idea.png',
  'assets/product-logos/pycharm.png',
  'assets/product-logos/webstorm.png',
  'assets/product-logos/phpstorm.png',
  'assets/product-logos/rider.png',
  'assets/product-logos/clion.png',
  'assets/product-logos/goland.png',
  'assets/product-logos/rubymine.png',
  'assets/product-logos/datagrip.png',
]; 