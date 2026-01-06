import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerPage extends StatelessWidget {
  const ScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Barcode")),
      body: MobileScanner(
        onDetect: (BarcodeCapture capture) {
          final List<Barcode> barcodes = capture.barcodes;

          if (barcodes.isNotEmpty) {
            final String code = barcodes.first.rawValue ?? '';
            if (code.isNotEmpty) {
              Navigator.pop(context, code);
            }
          }
        },
      ),
    );
  }
}
