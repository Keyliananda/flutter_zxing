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
  String _debugInfo = 'Scanner ready';

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
    
    print('DEBUG: Scanned barcode: ${code.text}');
    print('DEBUG: Format: ${barcode.format}');
    
    // Show action dialog instead of just saving
    _showActionDialog(code);
  }

  void _showActionDialog(model.Code code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('QR-Code gescannt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Inhalt: ${code.text}', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Format: ${code.formatName}'),
            SizedBox(height: 16),
            Text('Was möchtest du tun?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _markWorkCompleted(code);
            },
            child: Text('✓ Arbeit erledigt'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _editItemInfo(code);
            },
            child: Text('✏️ Info ändern'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _justSaveCode(code);
            },
            child: Text('💾 Nur speichern'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('❌ Abbrechen'),
          ),
        ],
      ),
    );
  }

  void _markWorkCompleted(model.Code code) {
    // TODO: Implement work completion logic
    print('DEBUG: Marking work as completed for: ${code.text}');
    
    DbService.instance.addCode(code);
    context.showToast('Arbeit als erledigt markiert:\n${code.text ?? ''}');
    setState(() {
      _debugInfo = 'Work completed: ${code.text ?? ''}';
    });
  }

  void _editItemInfo(model.Code code) {
    // TODO: Implement edit info dialog
    print('DEBUG: Editing info for: ${code.text}');
    
    // For now, show a simple text input dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Info ändern'),
        content: TextField(
          decoration: InputDecoration(
            labelText: 'Notiz',
            hintText: 'Zusätzliche Information eingeben...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              DbService.instance.addCode(code);
              context.showToast('Info geändert für:\n${code.text ?? ''}');
            },
            child: Text('Speichern'),
          ),
        ],
      ),
    );
  }

  void _justSaveCode(model.Code code) {
    DbService.instance.addCode(code);
    context.showToast('Code gespeichert:\n${code.text ?? ''}');
    setState(() {
      _debugInfo = 'Scan Success: ${code.text ?? ''}';
    });
    print('DEBUG: Code saved to database');
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
