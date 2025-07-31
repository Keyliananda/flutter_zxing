import 'package:flutter/material.dart';
import 'package:flutter_zxing/flutter_zxing.dart';

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
            child: ReaderWidget(
        actionButtonsAlignment: Alignment.topCenter,
        onScan: (dynamic result) async {
          if (result is Code) {
            addCode(result);
          } else {
            print('Scan error: $result');
            setState(() {
              _debugInfo = 'Scan Error: $result';
            });
          }
        },
              onControllerCreated: (controller, error) {
                setState(() {
                  if (error != null) {
                    _debugInfo = 'Camera Error: ${error.toString()}';
                    _isCameraReady = false;
                  } else if (controller != null) {
                    _debugInfo = 'Camera Ready: ${controller.description.name}';
                    _isCameraReady = true;
                  } else {
                    _debugInfo = 'Camera Controller: null';
                    _isCameraReady = false;
                  }
                });
                print('Camera Controller Created: $controller, Error: $error');
              },
                             onScanFailure: (dynamic result) {
                 setState(() {
                   if (result is Code) {
                     _debugInfo = 'Scan Failed: ${result.error ?? 'Unknown error'}';
                   } else {
                     _debugInfo = 'Scan Failed: $result';
                   }
                 });
                 print('Scan Failed: $result');
               },
            ),
          ),
        ],
      ),
    );
  }

  void addCode(Code result) {
    final model.Code code = model.Code.fromCodeResult(result);
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
