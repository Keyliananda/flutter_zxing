import 'package:hive_flutter/hive_flutter.dart';

import '../models/models.dart';
import '../models/scan.dart';

class DbService {
  DbService._privateConstructor();

  static final DbService instance = DbService._privateConstructor();

  Future<void> initializeApp() async {
    await Hive.initFlutter();
    Hive.registerAdapter(CodeAdapter());
    Hive.registerAdapter(EncodeAdapter());
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(ScanAdapter());

    await Hive.openBox<Code>('codes');
    await Hive.openBox<Encode>('encodes');
    await Hive.openBox<Scan>('scans');
  }

  Box<Code> getCodes() => Hive.box<Code>('codes');

  Future<void> deleteCodes() async {
    final Box<Code> items = getCodes();
    await items.deleteAll(items.keys);
  }

  Future<int> addCode(Code value) async {
    final Box<Code> items = getCodes();
    if (!items.values.contains(value)) {
      return items.add(value);
    }
    return -1;
  }

  Future<void> deleteCode(Code value) async {
    final Box<Code> items = getCodes();
    await items.delete(value.key);
    return;
  }

  Box<Encode> getEncodes() => Hive.box<Encode>('encodes');

  Future<void> deleteEncodes() async {
    final Box<Encode> items = getEncodes();
    await items.deleteAll(items.keys);
  }

  Future<int> addEncode(Encode value) async {
    final Box<Encode> items = getEncodes();
    if (!items.values.contains(value)) {
      return items.add(value);
    }
    return -1;
  }

  Future<void> deleteEncode(Encode value) async {
    final Box<Encode> items = getEncodes();
    await items.delete(value.key);
    return;
  }

  // Scan management methods
  Box<Scan> getScans() => Hive.box<Scan>('scans');

  Future<void> deleteScans() async {
    final Box<Scan> items = getScans();
    await items.deleteAll(items.keys);
  }

  Future<int> addScan(Scan value) async {
    final Box<Scan> items = getScans();
    return items.add(value);
  }

  Future<void> deleteScan(Scan value) async {
    final Box<Scan> items = getScans();
    await items.delete(value.key);
    return;
  }

  // Get scans by sync status
  List<Scan> getScansByStatus(SyncStatus status) {
    return getScans().values
        .where((scan) => scan.status == status)
        .toList();
  }

  // Get unsynced scans (pending or failed)
  List<Scan> getUnsyncedScans() {
    return getScans().values
        .where((scan) => scan.needsSync)
        .toList();
  }

  // Get scan statistics
  Map<String, int> getScanStats() {
    final scans = getScans().values.toList();
    return {
      'total': scans.length,
      'pending': scans.where((s) => s.isPending).length,
      'syncing': scans.where((s) => s.isSyncing).length,
      'synced': scans.where((s) => s.isSynced).length,
      'failed': scans.where((s) => s.isFailed).length,
    };
  }
}
