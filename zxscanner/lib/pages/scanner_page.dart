import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/models.dart' as model;
import '../utils/db_service.dart';
import '../utils/api_service.dart';
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
          IconButton(
            icon: const Icon(Icons.api),
            onPressed: () {
              _testApiEndpoints();
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

  void _markWorkCompleted(model.Code code) async {
    print('DEBUG: Marking work as completed for: ${code.text}');
    
    // Save locally first
    DbService.instance.addCode(code);
    
    // Try to sync to server
    try {
      if (await ApiService.instance.isConnected()) {
        // Submit scan with 'completed' status
        await ApiService.instance.submitScan(
          barcode: code.text ?? '',
          format: code.formatName,
          action: 'completed',
          notes: 'Arbeit als erledigt markiert',
        );
        
        context.showToast('✅ Arbeit erledigt & synchronisiert:\n${code.text ?? ''}');
        setState(() {
          _debugInfo = 'Work completed & synced: ${code.text ?? ''}';
        });
      } else {
        context.showToast('✅ Arbeit erledigt (offline):\n${code.text ?? ''}\nWird später synchronisiert');
        setState(() {
          _debugInfo = 'Work completed (offline): ${code.text ?? ''}';
        });
      }
    } catch (e) {
      print('API Error: $e');
      context.showToast('✅ Arbeit erledigt (lokal):\n${code.text ?? ''}\nSync-Fehler: $e');
      setState(() {
        _debugInfo = 'Work completed (local only): ${code.text ?? ''}';
      });
    }
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

  void _testApiEndpoints() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🧪 API Tests'),
        content: const Text('API-Endpunkte werden getestet...\nSchau ins Terminal für Details!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    // Run API tests in background
    try {
      await ApiService.instance.testAllEndpoints();
      context.showToast('✅ API Tests abgeschlossen!\nDetails im Terminal');
    } catch (e) {
      context.showToast('❌ API Tests fehlgeschlagen:\n$e');
    }
  }

  void _syncOfflineData() async {
    try {
      final localCodes = DbService.instance.getCodes().values.toList();
      if (localCodes.isEmpty) {
        context.showToast('Keine lokalen Daten zum Synchronisieren');
        return;
      }

      await ApiService.instance.syncCodesToServer(localCodes);
      context.showToast('✅ ${localCodes.length} Codes synchronisiert');
    } catch (e) {
      context.showToast('❌ Sync fehlgeschlagen: $e');
    }
  }
}
