import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/utils/app_constants.dart';
import 'package:mobile/utils/dialog_widgets.dart';

import '../../connection/provider/connection_provider.dart';
import '../../connection/domain/connection_status.dart';
import '../../connection/presentation/connect_screen.dart';

class ConnectedScreen extends ConsumerStatefulWidget {
  final String url;

  const ConnectedScreen({super.key, required this.url});

  @override
  ConsumerState<ConnectedScreen> createState() => _ConnectedScreenState();
}

class _ConnectedScreenState extends ConsumerState<ConnectedScreen> {
  
  bool _alertShown = false;

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(connectionStatusProvider);

    // If connection drops, trigger alert and redirection
    if (!_alertShown && status == ConnectionStatus.disconnected) {
      _alertShown = true;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        connectionLostDialog(context, "Connection with the server lost.\nYou will be redirected to the connection screen.");

        await Future.delayed(const Duration(seconds: 3));
        navigateAndRemoveAll(context, const ConnectScreen());
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Connected')),
      body: Center(
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
          ],
        ),
      ),
    );
  }
}
