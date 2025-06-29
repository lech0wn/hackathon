import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScanPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scan QR Code')),
      body: MobileScanner(
        onDetect: (BarcodeCapture barcodeCapture) {
          final String? code = barcodeCapture.barcodes.isNotEmpty
              ? barcodeCapture.barcodes.first.rawValue
              : null;
          if (code != null) {
            Navigator.pop(context, code); // Return scanned QR code string
          }
        },
      ),
    );
  }
}
