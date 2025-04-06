import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/connection_storage.dart';
import 'package:mobile/data/domain/connection_status.dart';
import 'package:mobile/presentation/build_error_details_page.dart';
import 'package:mobile/utils/app_constants.dart';
import 'package:mobile/utils/dialog_widgets.dart';
import '../data/provider/connection_provider.dart';
import '../data/provider/build_provider.dart';
import 'connect_screen.dart';

class ConnectedScreen extends ConsumerStatefulWidget {
  final String url;

  const ConnectedScreen({super.key, required this.url});

  @override
  ConsumerState<ConnectedScreen> createState() => _ConnectedScreenState();
}

class _ConnectedScreenState extends ConsumerState<ConnectedScreen> {
  bool _alertShown = false;
  bool _manualDisconnect = false;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(connectionStatusProvider.notifier).connect(widget.url);

      // Fetch build status once on screen load
      _fetchInitialBuildStatus();
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
    final connectionStatus = ref.watch(connectionStatusProvider);
    final buildData = ref.watch(buildProvider);

    // If build data was not retrieved yet, show loading indicator
    if (buildData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final buildStatus = buildData['status']?.toString().toLowerCase();

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

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.url,
                    textAlign: TextAlign.center,
                  ),
                  const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                ],
              ),
              ElevatedButton(
                onPressed: () => _handleDisconnect(context),
                child: const Text("Disconnect"),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16), // rounded corners
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (buildStatus == "running") ...[
                      Text(
                        'Build in progress...',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ] else ...[
                      Text(
                        'Last build details:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (buildStatus == 'idle') ...[
                        const Text('No build has been run yet.'),
                      ] else if (buildStatus == 'success') ...[
                        const Text('Build was successful!'),
                      ] else if (buildStatus == 'failure') ...[
                        const Text('Build failed!'),
                        if (buildData['errorMessage'] == null) ...[
                          const Text('Build was run through IDE.'),
                        ] else ...[
                          Text(buildData['errorMessage']),
                        ],
                      ],
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (buildStatus == 'failure') ...[
                          ElevatedButton(
                            onPressed: () => navigateTo(context, BuildErrorDetailsPage(buildData: buildData, baseUrl: widget.url)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text("See details"),
                          ),
                        ] else ...[
                          const SizedBox(),
                        ],
                        const SizedBox(),
                        ElevatedButton(
                          onPressed: (buildStatus == 'running')
                              ? null
                              : () => _handleRun(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (buildStatus == 'running')
                                ? Colors.grey
                                : Colors.green,
                          ),
                          child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
      errorDialog(context, message); // uses your CoolAlert wrapper
    }
  }

  // Action
  Future<void> _handleDisconnect(BuildContext context) async {
    _manualDisconnect = true;
    await ConnectionStorage.clearConnectedUrl();
    ref.read(connectionStatusProvider.notifier).stop();
    ref.read(buildProvider.notifier).reset();
    navigateAndRemoveAll(context, const ConnectScreen());
  }
}
