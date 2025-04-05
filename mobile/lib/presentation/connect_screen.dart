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

  Future<void> _attemptConnection(BuildContext context, WidgetRef ref) async {
    loadingDialog(context);

    final notifier = ref.read(connectionStatusProvider.notifier);
    final url = urlController.text.trim();

    if (!isValidNgrokUrl(url)) {
      Navigator.pop(context); // Close loading dialog
      errorDialog(context, "Invalid URL format. Please try again.");
      return;
    }

    final success = await notifier.connect(url);
    Navigator.pop(context); // Close loading dialog

    if (success) {
      navigateAndReplace(context, ConnectedScreen(url: url));
    } else {
      errorDialog(context, "Could not connect to the server.");
    }
  }

  Future<void> _captureUrl(BarcodeCapture capture, BuildContext context, WidgetRef ref, MobileScannerController scannerController) async {
    final raw = capture.barcodes.first.rawValue;
    if (raw != null) {
      scannerController.dispose();
      Navigator.of(context).pop(); // Close dialog

      setState(() {
        urlController.text = raw;
      });

      await Future.delayed(const Duration(milliseconds: 300));
      _attemptConnection(context, ref);
    }
  }

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
                onDetect: (capture) => _captureUrl(capture, context, ref, scannerController),
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
    // final notifier = ref.read(connectionStatusProvider.notifier);

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
                  labelText: 'Server URL (e.g. https://example.com)',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () => _showQRScannerDialog(context),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _attemptConnection(context, ref),
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
