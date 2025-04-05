import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/connection_storage.dart';
import 'package:mobile/data/domain/connection_status.dart';
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
  bool _runButtonDisabled = false;
  bool _manualDisconnect = false;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(connectionStatusProvider.notifier).connect(widget.url);
    });
  }

  @override
  Widget build(BuildContext context) {
    final connectionStatus = ref.watch(connectionStatusProvider);
    final buildData = ref.watch(buildProvider);
    final buildStatus = buildData?['status']?.toString().toLowerCase();

    // If connection drops, show alert and redirect
    if (!_alertShown && connectionStatus == ConnectionStatus.disconnected && !_manualDisconnect) {
      _alertShown = true;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        connectionLostDialog(
          context,
          "Connection with the server lost.\nYou will be redirected to the connection screen.",
        );

        await Future.delayed(const Duration(seconds: 3));
        navigateAndRemoveAll(context, const ConnectScreen());
      });
    }

    if (_runButtonDisabled && (buildStatus == 'success' || buildStatus == 'failure')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _runButtonDisabled = false;
        });
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Connected')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
              const SizedBox(height: 20),
              Text(
                'You are connected to:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                widget.url,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  _manualDisconnect = true;
                  await ConnectionStorage.clearConnectedUrl();
                  ref.read(connectionStatusProvider.notifier).stop();
                  navigateAndRemoveAll(context, const ConnectScreen());
                },
                child: const Text("Disconnect"),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: (_runButtonDisabled)
                    ? null
                    : () => _handleRun(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_runButtonDisabled)
                      ? Colors.grey
                      : Colors.green,
                ),
                child: const Text('Run'),
              ),
              const SizedBox(height: 24),
              if (buildStatus != null) ...[
                Text(
                  "Build Status: ${buildStatus.toUpperCase()}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleRun(BuildContext context) async {
    setState(() {
      _runButtonDisabled = true;
    });

    await ref.read(buildProvider.notifier).run(widget.url);

    final buildResult = ref.read(buildProvider);
    final status = buildResult?['status']?.toString().toLowerCase();

    if (status == 'error' || status == null) {
      setState(() {
        _runButtonDisabled = false;
      });

      final message = buildResult?['message'] ?? "This error shouldn't be reached.";
      errorDialog(context, message); // uses your CoolAlert wrapper
    }
  }
}
