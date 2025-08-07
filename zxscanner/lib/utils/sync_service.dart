import 'dart:async';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../models/scan.dart';
import '../utils/api_service.dart';
import '../utils/db_service.dart';
import '../utils/auth_service.dart';

/// Comprehensive sync service for offline-first scan management
class SyncService {
  static final SyncService instance = SyncService._privateConstructor();
  SyncService._privateConstructor();

  late Timer? _syncTimer;
  bool _isSyncing = false;
  final List<Function(SyncStatus)> _statusListeners = [];
  final List<Function(int, int)> _progressListeners = [];

  // Sync configuration
  static const int _syncIntervalSeconds = 30; // Check for sync every 30 seconds
  static const int _maxRetryCount = 5;
  static const int _batchSize = 10; // Sync in batches to avoid overwhelming the server

  /// Initialize the sync service
  Future<void> initialize() async {
    print('SyncService: Initializing...');
    
    // Start periodic sync timer
    _startPeriodicSync();
    
    // Listen for network connectivity changes
    Connectivity().onConnectivityChanged.listen((connectivityResult) {
      if (connectivityResult != ConnectivityResult.none) {
        print('SyncService: Network available, triggering sync');
        triggerSync();
      }
    });
    
    print('SyncService: Initialized successfully');
  }

  /// Add a new scan to the local queue
  Future<String> addScan({
    required String barcode,
    required String format,
    String? action,
    String? notes,
    String? userId,
    DateTime? scannedAt,
  }) async {
    final scan = Scan.create(
      barcode: barcode,
      format: format,
      action: action,
      notes: notes,
      userId: userId,
      scannedAt: scannedAt,
    );

    // Store locally
    await DbService.instance.addScan(scan);
    
    print('SyncService: Added scan ${scan.id} to local queue');
    
    // Trigger immediate sync if network is available
    if (await _isNetworkAvailable()) {
      triggerSync();
    }
    
    return scan.id;
  }

  /// Manually trigger sync process
  Future<void> triggerSync() async {
    if (_isSyncing) {
      print('SyncService: Sync already in progress, skipping');
      return;
    }

    if (!await _isNetworkAvailable()) {
      print('SyncService: No network available, skipping sync');
      return;
    }

    if (!AuthService.instance.isAuthenticated) {
      print('SyncService: Not authenticated, skipping sync');
      return;
    }

    await _performSync();
  }

  /// Get sync statistics
  SyncStats getSyncStats() {
    final scans = DbService.instance.getScans().values.toList();
    return SyncStats(
      total: scans.length,
      pending: scans.where((s) => s.isPending).length,
      syncing: scans.where((s) => s.isSyncing).length,
      synced: scans.where((s) => s.isSynced).length,
      failed: scans.where((s) => s.isFailed).length,
    );
  }

  /// Get all unsynced scans
  List<Scan> getUnsyncedScans() {
    return DbService.instance.getScans().values
        .where((scan) => scan.needsSync)
        .toList();
  }

  /// Get scans that are ready for retry
  List<Scan> getRetryableScans() {
    return DbService.instance.getScans().values
        .where((scan) => scan.isFailed && scan.isRetryDue && scan.retryCount < _maxRetryCount)
        .toList();
  }

  /// Add listener for sync status changes
  void addStatusListener(Function(SyncStatus) listener) {
    _statusListeners.add(listener);
  }

  /// Add listener for sync progress
  void addProgressListener(Function(int current, int total) listener) {
    _progressListeners.add(listener);
  }

  /// Remove listeners
  void removeStatusListener(Function(SyncStatus) listener) {
    _statusListeners.remove(listener);
  }

  void removeProgressListener(Function(int current, int total) listener) {
    _progressListeners.remove(listener);
  }

  /// Dispose resources
  void dispose() {
    _syncTimer?.cancel();
    _statusListeners.clear();
    _progressListeners.clear();
  }

  // Private methods

  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(
      const Duration(seconds: _syncIntervalSeconds),
      (_) => triggerSync(),
    );
  }

  Future<bool> _isNetworkAvailable() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> _performSync() async {
    _isSyncing = true;
    _notifyStatusListeners(SyncStatus.syncing);
    
    try {
      print('SyncService: Starting sync process...');
      
      // Get all scans that need syncing
      final pendingScans = getUnsyncedScans();
      final retryableScans = getRetryableScans();
      final allScansToSync = [...pendingScans, ...retryableScans];
      
      if (allScansToSync.isEmpty) {
        print('SyncService: No scans to sync');
        return;
      }
      
      print('SyncService: Syncing ${allScansToSync.length} scans');
      
      // Process scans in batches
      final batches = _createBatches(allScansToSync, _batchSize);
      int totalProcessed = 0;
      
      for (int i = 0; i < batches.length; i++) {
        final batch = batches[i];
        print('SyncService: Processing batch ${i + 1}/${batches.length} (${batch.length} scans)');
        
        await _syncBatch(batch);
        
        totalProcessed += batch.length;
        _notifyProgressListeners(totalProcessed, allScansToSync.length);
        
        // Small delay between batches to avoid overwhelming the server
        if (i < batches.length - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      
      print('SyncService: Sync completed successfully');
      
    } catch (e) {
      print('SyncService: Sync failed with error: $e');
    } finally {
      _isSyncing = false;
      _notifyStatusListeners(SyncStatus.pending);
    }
  }

  Future<void> _syncBatch(List<Scan> scans) async {
    for (final scan in scans) {
      if (!await _isNetworkAvailable()) {
        print('SyncService: Network lost during sync, stopping');
        break;
      }
      
      await _syncScan(scan);
    }
  }

  Future<void> _syncScan(Scan scan) async {
    try {
      // Mark as syncing
      scan.markSyncing();
      await scan.save();
      
      print('SyncService: Syncing scan ${scan.id} (${scan.barcode})');
      
      // Submit to API
      final response = await ApiService.instance.submitScan(
        barcode: scan.barcode,
        format: scan.format,
        action: scan.action,
        notes: scan.notes,
        userId: scan.userId,
      );
      
      // Mark as synced
      final serverId = response['id']?.toString();
      scan.markSynced(serverId: serverId);
      await scan.save();
      
      print('SyncService: Successfully synced scan ${scan.id}');
      
    } on DioException catch (e) {
      await _handleSyncError(scan, e);
    } catch (e) {
      await _handleSyncError(scan, e);
    }
  }

  Future<void> _handleSyncError(Scan scan, dynamic error) async {
    String errorMessage = 'Unknown error';
    bool shouldRetry = true;
    
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      errorMessage = 'HTTP $statusCode: ${error.message}';
      
      // Determine if we should retry based on status code
      shouldRetry = _shouldRetryForStatusCode(statusCode);
      
      print('SyncService: Sync failed for scan ${scan.id} - $errorMessage (retry: $shouldRetry)');
      
      // Handle specific status codes
      switch (statusCode) {
        case 401:
          print('SyncService: Authentication failed, triggering logout');
          await AuthService.instance.logout();
          return;
          
        case 422:
          print('SyncService: Validation error, scan data invalid');
          shouldRetry = false;
          break;
          
        case 409:
          // Conflict - scan might already exist on server
          print('SyncService: Conflict - scan might already exist');
          scan.markSynced(); // Mark as synced to avoid further attempts
          await scan.save();
          return;
          
        default:
          break;
      }
    } else {
      errorMessage = error.toString();
      print('SyncService: Sync failed for scan ${scan.id} - $errorMessage');
    }
    
    if (shouldRetry && scan.retryCount < _maxRetryCount) {
      // Schedule retry
      scan.markFailed(errorMessage);
      await scan.save();
      print('SyncService: Scheduled retry for scan ${scan.id} (attempt ${scan.retryCount}/${_maxRetryCount})');
    } else {
      // Give up retrying
      scan.markFailed('$errorMessage (max retries exceeded)');
      await scan.save();
      print('SyncService: Giving up on scan ${scan.id} after ${scan.retryCount} attempts');
    }
  }

  bool _shouldRetryForStatusCode(int? statusCode) {
    if (statusCode == null) return true;
    
    // Don't retry for client errors (4xx) except for specific cases
    if (statusCode >= 400 && statusCode < 500) {
      switch (statusCode) {
        case 408: // Request Timeout
        case 429: // Too Many Requests
          return true;
        default:
          return false;
      }
    }
    
    // Retry for server errors (5xx) and network errors
    return true;
  }

  List<List<Scan>> _createBatches(List<Scan> scans, int batchSize) {
    final batches = <List<Scan>>[];
    for (int i = 0; i < scans.length; i += batchSize) {
      final end = min(i + batchSize, scans.length);
      batches.add(scans.sublist(i, end));
    }
    return batches;
  }

  void _notifyStatusListeners(SyncStatus status) {
    for (final listener in _statusListeners) {
      try {
        listener(status);
      } catch (e) {
        print('SyncService: Error notifying status listener: $e');
      }
    }
  }

  void _notifyProgressListeners(int current, int total) {
    for (final listener in _progressListeners) {
      try {
        listener(current, total);
      } catch (e) {
        print('SyncService: Error notifying progress listener: $e');
      }
    }
  }
}

/// Sync statistics data class
class SyncStats {
  final int total;
  final int pending;
  final int syncing;
  final int synced;
  final int failed;

  const SyncStats({
    required this.total,
    required this.pending,
    required this.syncing,
    required this.synced,
    required this.failed,
  });

  int get unsynced => pending + failed;
  double get syncedPercentage => total > 0 ? (synced / total) * 100 : 0;
  
  @override
  String toString() {
    return 'SyncStats{total: $total, pending: $pending, syncing: $syncing, synced: $synced, failed: $failed}';
  }
}