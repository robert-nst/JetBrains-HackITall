import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile/data/connection_storage.dart';
import 'package:mobile/data/domain/connection_status.dart';
import 'package:mobile/presentation/components/jetbrains_confetti.dart';
import 'package:mobile/presentation/build_error_details_page.dart';
import 'package:mobile/utils/app_constants.dart';
import 'package:mobile/utils/dialog_widgets.dart';
import 'package:mobile/utils/jetbrains_brand_theme.dart';
import '../data/provider/connection_provider.dart';
import '../data/provider/build_provider.dart';
import 'connect_screen.dart';

class ConnectedScreen extends ConsumerStatefulWidget {
  final String url;

  const ConnectedScreen({super.key, required this.url});

  @override
  ConsumerState<ConnectedScreen> createState() => _ConnectedScreenState();
}

class _ConnectedScreenState extends ConsumerState<ConnectedScreen> with SingleTickerProviderStateMixin {
  bool _alertShown = false;
  bool _manualDisconnect = false;
  bool _showConfetti = false;
  late AnimationController _backgroundAnimationController;
  Offset? _touchPoint;
  double _touchRadius = 0;

  @override
  void initState() {
    super.initState();
    _backgroundAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    Future.microtask(() {
      ref.read(connectionStatusProvider.notifier).connect(widget.url);

      // Fetch build status once on screen load
      _fetchInitialBuildStatus();
    });
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _touchPoint = details.localPosition;
      _touchRadius = 150.0;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _touchRadius = 0;
    });
  }

  void _fetchInitialBuildStatus() async {
    final result = await ref.read(buildRepositoryProvider).getBuildStatus(widget.url);

    if (result != null) {
      ref.read(buildProvider.notifier).setState(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final connectionStatus = ref.watch(connectionStatusProvider);
    final buildData = ref.watch(buildProvider);

    // If build data was not retrieved yet, show loading indicator
    if (buildData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final buildStatus = buildData['status']?.toString().toLowerCase();
    final previousBuildStatus = buildData['previousStatus']?.toString().toLowerCase();

    // Show confetti only when transitioning to success state
    if (buildStatus == 'success' && previousBuildStatus != 'success' && !_showConfetti) {
      setState(() => _showConfetti = true);
      Future.delayed(const Duration(seconds: 6), () {
        if (mounted) setState(() => _showConfetti = false);
      });
    }

    // Action
    FlutterNativeSplash.remove();

    // If connection drops, show alert and redirect
    if (!_alertShown && connectionStatus == ConnectionStatus.disconnected && !_manualDisconnect) {
      _alertShown = true;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        connectionLostDialog(
          context,
          "Connection with the server lost.\nYou will be redirected to the connection screen.",
        );

        await Future.delayed(const Duration(seconds: 3));
        await ConnectionStorage.clearConnectedUrl();
        ref.read(buildProvider.notifier).reset();
        navigateAndRemoveAll(context, const ConnectScreen());
      });
    }

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Scaffold(
        backgroundColor: JetBrandTheme.backgroundDark,
        body: Stack(
          children: [
            // Animated Background
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
            // Main Content
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Section with Connection Status
                  Container(
                    margin: EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.wifi_rounded,
                            color: Colors.green,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Connected',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.url,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Build Status Card
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            JetBrandTheme.surfaceDark.withOpacity(0.9),
                            JetBrandTheme.surfaceDark.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Card Header
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: JetBrandTheme.buttonGradient,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.build_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Build Status',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Last updated just now',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.5),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Build Status Content
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              child: _buildStatusContent(buildStatus, buildData, context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Disconnect Button
                  Container(
                    margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: ElevatedButton.icon(
                      onPressed: () => _handleDisconnect(context),
                      icon: const Icon(Icons.power_settings_new_rounded),
                      label: const Text('Disconnect'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Confetti Effect
            if (_showConfetti)
              JetBrainsConfetti(showConfetti: _showConfetti),
          ],
        ),
      ),
    );
  }

  // Action
  Future<void> _handleRun(BuildContext context) async {
    await ref.read(buildProvider.notifier).run(widget.url);
    final buildResult = ref.read(buildProvider);
    final status = buildResult?['status']?.toString().toLowerCase();
    if (status == 'error' || status == null) {
      final message = buildResult?['message'] ?? "This error shouldn't be reached.";
      errorDialog(context, message);
    }
  }

  // Action
  Future<void> _handleDisconnect(BuildContext context) async {
    try {
      _manualDisconnect = true;
      await ConnectionStorage.clearConnectedUrl();
      ref.read(connectionStatusProvider.notifier).stop();
      
      if (!mounted) return;
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const ConnectScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      errorDialog(context, "Failed to disconnect. Please try again.");
    }
  }

  Widget _buildStatusContent(String? status, Map<String, dynamic> buildData, BuildContext context) {
    switch (status) {
      case 'idle':
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.2),
                    Colors.blue.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(60),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.pause_circle_outline_rounded,
                color: Colors.blue,
                size: 64,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Ready to Build',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No builds have been run yet.\nClick the Run Build button to start.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _handleRun(context),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Run Build'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green.withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );

      case 'running':
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.2),
                    Colors.blue.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(60),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const CircularProgressIndicator(
                color: Colors.blue,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Building...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Build is currently in progress.\nPlease wait while we process your request.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );

      case 'success':
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.withOpacity(0.2),
                    Colors.green.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(60),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.green,
                size: 64,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Build Successful!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'The last build was completed successfully.\nAll tests passed and the code is ready to deploy.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _handleRun(context),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Run Again'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green.withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );

      case 'failure':
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.withOpacity(0.2),
                    Colors.red.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(60),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 64,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Build Failed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              buildData['errorMessage'] ?? 'Build failed. The build was run through IDE.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.error_outline),
                    label: const Text('See Details'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.red.withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleRun(context),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green.withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
