import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/connection_storage.dart';
import 'package:mobile/presentation/connected_screen.dart';
import 'package:mobile/utils/app_constants.dart';
import 'package:mobile/utils/dialog_widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../data/provider/connection_provider.dart';

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  final TextEditingController urlController = TextEditingController();

  // UI: QR Scanner Dialog
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
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blueAccent, width: 4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
            ],
          ),
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
      Navigator.pop(context); // Close loading dialog
      errorDialog(context, "Invalid URL format. Please try again.");
      return;
    }

    final success = await notifier.connect(url);

    if (success) {
      await ConnectionStorage.saveConnectedUrl(url);
      navigateAndReplace(context, ConnectedScreen(url: url));
    } else {
      Navigator.pop(context); // Close loading dialog
      errorDialog(context, "Could not connect to the server.");
    }
  }

  // Action
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
}
