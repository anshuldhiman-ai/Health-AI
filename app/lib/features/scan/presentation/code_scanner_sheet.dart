import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Local QR and retail-barcode reader. The decoded value is handed back
/// to the caller; no camera frame or code is sent over the network.
class CodeScannerSheet extends StatefulWidget {
  const CodeScannerSheet({super.key});

  @override
  State<CodeScannerSheet> createState() => _CodeScannerSheetState();
}

class _CodeScannerSheetState extends State<CodeScannerSheet> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value == null || value.isEmpty) continue;
      _handled = true;
      Navigator.of(context).pop(value);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.78,
      child: Stack(fit: StackFit.expand, children: [
        MobileScanner(onDetect: _onDetect),
        SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
                const Spacer(),
                const Text('Scan a food code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                const Spacer(),
                const SizedBox(width: 48),
              ]),
            ),
            const Spacer(),
            Container(
              width: 260,
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD4AF37), width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: Text(
                'Point at a QR code or product barcode. Scanning stays on this device.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, height: 1.4),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
