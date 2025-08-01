import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/models.dart' as model;
import '../utils/db_service.dart';
import '../utils/extensions.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({
    super.key,
  });

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  String _debugInfo = 'Initializing...';
  bool _isCameraReady = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              _showDebugInfo();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Debug info panel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.grey[200],
            child: Text(
              _debugInfo,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          // Scanner widget
          Expanded(
            child: MobileScanner(
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final Barcode barcode = barcodes.first;
                  addBarcode(barcode);
                }
              },
              onScannerStarted: (value) {
                setState(() {
                  _debugInfo = 'Scanner Started: ${value.toString()}';
                  _isCameraReady = true;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  void addBarcode(Barcode barcode) {
    final model.Code code = model.Code();
    code.isValid = true;
    code.format = barcode.format.index;
    code.text = barcode.rawValue;
    
    DbService.instance.addCode(code);
    context.showToast('Barcode saved:\n${code.text ?? ''}');
    setState(() {
      _debugInfo = 'Scan Success: ${code.text ?? ''}';
    });
  }

  void _showDebugInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Info'),
        content: Text(_debugInfo),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
