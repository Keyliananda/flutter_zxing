import 'package:mobx/mobx.dart';
import '../models/scan.dart';
import '../utils/sync_service.dart';
import '../utils/db_service.dart';

part 'sync_store.g.dart';

class SyncStore = SyncStoreBase with _$SyncStore;

abstract class SyncStoreBase with Store {
  final SyncService _syncService = SyncService.instance;

  @observable
  bool isSyncing = false;

  @observable
  SyncStats syncStats = const SyncStats(
    total: 0,
    pending: 0,
    syncing: 0,
    synced: 0,
    failed: 0,
  );

  @observable
  int syncProgress = 0;

  @observable
  int syncTotal = 0;

  @observable
  String? lastSyncError;

  @observable
  DateTime? lastSyncTime;

  @computed
  bool get hasUnsyncedScans => syncStats.unsynced > 0;

  @computed
  double get syncPercentage => syncStats.syncedPercentage;

  @computed
  String get syncStatusText {
    if (isSyncing) {
      if (syncTotal > 0) {
        return 'Syncing $syncProgress/$syncTotal...';
      }
      return 'Syncing...';
    }
    
    if (hasUnsyncedScans) {
      return '${syncStats.unsynced} scans pending';
    }
    
    return 'All scans synced';
  }

  /// Initialize the sync store
  @action
  Future<void> initialize() async {
    // Set up listeners for sync service
    _syncService.addStatusListener(_onSyncStatusChanged);
    _syncService.addProgressListener(_onSyncProgressChanged);
    
    // Load initial sync stats
    updateSyncStats();
  }

  /// Manually trigger sync
  @action
  Future<void> triggerSync() async {
    try {
      lastSyncError = null;
      await _syncService.triggerSync();
      updateSyncStats();
      lastSyncTime = DateTime.now();
    } catch (e) {
      lastSyncError = e.toString();
    }
  }

  /// Add a new scan
  @action
  Future<String> addScan({
    required String barcode,
    required String format,
    String? action,
    String? notes,
    String? userId,
    DateTime? scannedAt,
  }) async {
    final scanId = await _syncService.addScan(
      barcode: barcode,
      format: format,
      action: action,
      notes: notes,
      userId: userId,
      scannedAt: scannedAt,
    );
    
    updateSyncStats();
    return scanId;
  }

  /// Update sync statistics from database
  @action
  void updateSyncStats() {
    syncStats = _syncService.getSyncStats();
  }

  /// Get all scans
  List<Scan> getAllScans() {
    return DbService.instance.getScans().values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get unsynced scans
  List<Scan> getUnsyncedScans() {
    return _syncService.getUnsyncedScans()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get scans by status
  List<Scan> getScansByStatus(SyncStatus status) {
    return DbService.instance.getScansByStatus(status)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Delete a scan
  @action
  Future<void> deleteScan(Scan scan) async {
    await DbService.instance.deleteScan(scan);
    updateSyncStats();
  }

  /// Clear all synced scans
  @action
  Future<void> clearSyncedScans() async {
    final syncedScans = getScansByStatus(SyncStatus.synced);
    for (final scan in syncedScans) {
      await DbService.instance.deleteScan(scan);
    }
    updateSyncStats();
  }

  /// Clear all scans
  @action
  Future<void> clearAllScans() async {
    await DbService.instance.deleteScans();
    updateSyncStats();
  }

  /// Dispose resources
  void dispose() {
    _syncService.removeStatusListener(_onSyncStatusChanged);
    _syncService.removeProgressListener(_onSyncProgressChanged);
  }

  // Private methods

  @action
  void _onSyncStatusChanged(SyncStatus status) {
    isSyncing = status == SyncStatus.syncing;
    if (!isSyncing) {
      syncProgress = 0;
      syncTotal = 0;
      updateSyncStats();
    }
  }

  @action
  void _onSyncProgressChanged(int current, int total) {
    syncProgress = current;
    syncTotal = total;
  }
}

// Global sync store instance
final SyncStore syncStore = SyncStore();