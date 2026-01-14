import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _scanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scan QR')),
        body: const Center(child: Text('QR scanning is not supported on web')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR')),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                if (_scanned) return;
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isEmpty) return;
                final code = barcodes.first.rawValue ?? '';
                if (code.isEmpty) return;
                _scanned = true;
                _controller.stop();
                Navigator.of(context).pop(code);
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('Point the camera at the QR code to join the room'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
