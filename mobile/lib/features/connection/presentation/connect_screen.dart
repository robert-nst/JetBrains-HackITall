import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/connection_provider.dart';
import '../domain/connection_status.dart';

class ConnectScreen extends ConsumerWidget {

  final TextEditingController urlController = TextEditingController();

  ConnectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectionStatusProvider);
    final notifier = ref.read(connectionStatusProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Connect to IDE')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Server URL (e.g. https://abc.ngrok.io)',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => notifier.connect(urlController.text),
              child: const Text('Connect'),
            ),
            const SizedBox(height: 24),
            Text('Status: ${status.name.toUpperCase()}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: status == ConnectionStatus.connected ? Colors.green
                     : status == ConnectionStatus.error ? Colors.red
                     : Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
