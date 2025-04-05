import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/presentation/connected_screen.dart';
import 'package:mobile/utils/app_constants.dart';
import 'package:mobile/utils/dialog_widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../data/provider/connection_provider.dart';
import '../data/connection_status.dart';

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  final TextEditingController urlController = TextEditingController();

  void _showQRScannerDialog(BuildContext context) {
    
    final scannerController = MobileScannerController(
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.normal,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async {
          scannerController.dispose();
          return true;
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              MobileScanner(
                controller: scannerController,
                onDetect: (capture) {
                  final raw = capture.barcodes.first.rawValue;
                  if (raw != null && raw.startsWith('http')) {
                    urlController.text = raw;
                    scannerController.dispose();
                    Navigator.of(context).pop(); // Close dialog
                  }
                },
              ),
              Center(child: _buildScannerOverlay()),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: () {
                    scannerController.dispose();
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueAccent, width: 4),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(connectionStatusProvider);
    final notifier = ref.read(connectionStatusProvider.notifier);

    return GestureDetector(
      // behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Connect to IDE')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: urlController,
                decoration: InputDecoration(
                  labelText: 'Server URL (e.g. https://abc.ngrok.io)',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () => _showQRScannerDialog(context),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  loadingDialog(context);
                  final success = await notifier.connect(urlController.text);
                  if (success) {
                    // Navigate to the connected screen
                    // Navigator.pop(context); // Close the loading dialog
                    navigateAndReplace(context, ConnectedScreen(url: urlController.text));
                  } else {
                    // Navigator.pop(context); // Close the loading dialog
                    errorDialog(context, "Could not connect to the server.");
                  }
                },
                child: const Text('Connect'),
              ),
              const SizedBox(height: 24),
              Text(
                'Status: ${status.name.toUpperCase()}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: status == ConnectionStatus.connected
                      ? Colors.green
                      : status == ConnectionStatus.error
                          ? Colors.red
                          : Colors.orange,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
