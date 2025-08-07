import 'package:hive/hive.dart';

part 'scan.g.dart';

enum SyncStatus {
  pending,
  syncing, 
  synced,
  failed,
}

@HiveType(typeId: 3)
class Scan extends HiveObject {
  @HiveField(0)
  late String id; // UUID for local identification

  @HiveField(1)
  late String barcode;

  @HiveField(2)
  late String format;

  @HiveField(3)
  String? action;

  @HiveField(4)
  String? notes;

  @HiveField(5)
  String? userId;

  @HiveField(6)
  late DateTime scannedAt;

  @HiveField(7)
  late DateTime createdAt;

  @HiveField(8)
  DateTime? lastSyncAttempt;

  @HiveField(9)
  late int syncStatus; // Using int to store SyncStatus enum

  @HiveField(10)
  int retryCount = 0;

  @HiveField(11)
  DateTime? nextRetryAt;

  @HiveField(12)
  String? lastError;

  @HiveField(13)
  String? serverId; // Server-assigned ID after successful sync

  Scan();

  Scan.create({
    required this.barcode,
    required this.format,
    this.action,
    this.notes,
    this.userId,
    DateTime? scannedAt,
  }) {
    id = _generateUuid();
    this.scannedAt = scannedAt ?? DateTime.now();
    createdAt = DateTime.now();
    syncStatus = SyncStatus.pending.index;
    retryCount = 0;
  }

  // Getters for enum conversion
  SyncStatus get status => SyncStatus.values[syncStatus];
  set status(SyncStatus value) => syncStatus = value.index;

  bool get isPending => status == SyncStatus.pending;
  bool get isSyncing => status == SyncStatus.syncing;
  bool get isSynced => status == SyncStatus.synced;
  bool get isFailed => status == SyncStatus.failed;
  bool get needsSync => isPending || isFailed;

  // Check if retry is due (for failed scans)
  bool get isRetryDue {
    if (!isFailed || nextRetryAt == null) return false;
    return DateTime.now().isAfter(nextRetryAt!);
  }

  // Calculate next retry time with exponential backoff
  void scheduleRetry() {
    retryCount++;
    final backoffSeconds = _calculateBackoffSeconds(retryCount);
    nextRetryAt = DateTime.now().add(Duration(seconds: backoffSeconds));
  }

  // Reset retry state on successful sync
  void markSynced({String? serverId}) {
    this.serverId = serverId;
    status = SyncStatus.synced;
    retryCount = 0;
    nextRetryAt = null;
    lastError = null;
    lastSyncAttempt = DateTime.now();
  }

  // Mark as failed with error
  void markFailed(String error) {
    status = SyncStatus.failed;
    lastError = error;
    lastSyncAttempt = DateTime.now();
    scheduleRetry();
  }

  // Mark as syncing
  void markSyncing() {
    status = SyncStatus.syncing;
    lastSyncAttempt = DateTime.now();
  }

  // Convert to JSON for API submission
  Map<String, dynamic> toApiJson() {
    return {
      'barcode': barcode,
      'format': format,
      'action': action ?? 'scanned',
      'notes': notes,
      'user_id': userId,
      'scanned_at': scannedAt.toIso8601String(),
      'client_id': id, // Send local ID for deduplication
    };
  }

  // Create from JSON response
  factory Scan.fromJson(Map<String, dynamic> json) {
    final scan = Scan();
    scan.id = json['client_id'] ?? _generateUuid();
    scan.barcode = json['barcode'] ?? '';
    scan.format = json['format'] ?? '';
    scan.action = json['action'];
    scan.notes = json['notes'];
    scan.userId = json['user_id']?.toString();
    scan.scannedAt = DateTime.tryParse(json['scanned_at'] ?? '') ?? DateTime.now();
    scan.createdAt = DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now();
    scan.serverId = json['id']?.toString();
    scan.status = SyncStatus.synced; // Assume synced if from server
    return scan;
  }

  // Convert to JSON for storage/export
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barcode': barcode,
      'format': format,
      'action': action,
      'notes': notes,
      'user_id': userId,
      'scanned_at': scannedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'last_sync_attempt': lastSyncAttempt?.toIso8601String(),
      'sync_status': status.name,
      'retry_count': retryCount,
      'next_retry_at': nextRetryAt?.toIso8601String(),
      'last_error': lastError,
      'server_id': serverId,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Scan &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Scan{id: $id, barcode: $barcode, status: ${status.name}, retryCount: $retryCount}';
  }

  // Private helper methods
  static String _generateUuid() {
    // Simple UUID v4 implementation
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 1000000).toString().padLeft(6, '0');
    return 'scan_${timestamp}_$random';
  }

  static int _calculateBackoffSeconds(int retryCount) {
    // Exponential backoff: 2^retryCount seconds, max 300 seconds (5 minutes)
    final backoff = (2 << (retryCount - 1)).clamp(1, 300);
    return backoff;
  }
}

// Hive Type Adapter for SyncStatus enum
@HiveType(typeId: 4)
enum SyncStatusHive {
  @HiveField(0)
  pending,
  @HiveField(1)
  syncing,
  @HiveField(2)
  synced,
  @HiveField(3)
  failed,
}