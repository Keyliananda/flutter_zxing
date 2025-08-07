// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$SyncStore on SyncStoreBase, Store {
  Computed<bool>? _$hasUnsyncedScansComputed;

  @override
  bool get hasUnsyncedScans => (_$hasUnsyncedScansComputed ??= Computed<bool>(
          () => super.hasUnsyncedScans,
          name: 'SyncStoreBase.hasUnsyncedScans'))
      .value;
  Computed<double>? _$syncPercentageComputed;

  @override
  double get syncPercentage =>
      (_$syncPercentageComputed ??= Computed<double>(() => super.syncPercentage,
              name: 'SyncStoreBase.syncPercentage'))
          .value;
  Computed<String>? _$syncStatusTextComputed;

  @override
  String get syncStatusText =>
      (_$syncStatusTextComputed ??= Computed<String>(() => super.syncStatusText,
              name: 'SyncStoreBase.syncStatusText'))
          .value;

  late final _$isSyncingAtom =
      Atom(name: 'SyncStoreBase.isSyncing', context: context);

  @override
  bool get isSyncing {
    _$isSyncingAtom.reportRead();
    return super.isSyncing;
  }

  @override
  set isSyncing(bool value) {
    _$isSyncingAtom.reportWrite(value, super.isSyncing, () {
      super.isSyncing = value;
    });
  }

  late final _$syncStatsAtom =
      Atom(name: 'SyncStoreBase.syncStats', context: context);

  @override
  SyncStats get syncStats {
    _$syncStatsAtom.reportRead();
    return super.syncStats;
  }

  @override
  set syncStats(SyncStats value) {
    _$syncStatsAtom.reportWrite(value, super.syncStats, () {
      super.syncStats = value;
    });
  }

  late final _$syncProgressAtom =
      Atom(name: 'SyncStoreBase.syncProgress', context: context);

  @override
  int get syncProgress {
    _$syncProgressAtom.reportRead();
    return super.syncProgress;
  }

  @override
  set syncProgress(int value) {
    _$syncProgressAtom.reportWrite(value, super.syncProgress, () {
      super.syncProgress = value;
    });
  }

  late final _$syncTotalAtom =
      Atom(name: 'SyncStoreBase.syncTotal', context: context);

  @override
  int get syncTotal {
    _$syncTotalAtom.reportRead();
    return super.syncTotal;
  }

  @override
  set syncTotal(int value) {
    _$syncTotalAtom.reportWrite(value, super.syncTotal, () {
      super.syncTotal = value;
    });
  }

  late final _$lastSyncErrorAtom =
      Atom(name: 'SyncStoreBase.lastSyncError', context: context);

  @override
  String? get lastSyncError {
    _$lastSyncErrorAtom.reportRead();
    return super.lastSyncError;
  }

  @override
  set lastSyncError(String? value) {
    _$lastSyncErrorAtom.reportWrite(value, super.lastSyncError, () {
      super.lastSyncError = value;
    });
  }

  late final _$lastSyncTimeAtom =
      Atom(name: 'SyncStoreBase.lastSyncTime', context: context);

  @override
  DateTime? get lastSyncTime {
    _$lastSyncTimeAtom.reportRead();
    return super.lastSyncTime;
  }

  @override
  set lastSyncTime(DateTime? value) {
    _$lastSyncTimeAtom.reportWrite(value, super.lastSyncTime, () {
      super.lastSyncTime = value;
    });
  }

  late final _$initializeAsyncAction =
      AsyncAction('SyncStoreBase.initialize', context: context);

  @override
  Future<void> initialize() {
    return _$initializeAsyncAction.run(() => super.initialize());
  }

  late final _$triggerSyncAsyncAction =
      AsyncAction('SyncStoreBase.triggerSync', context: context);

  @override
  Future<void> triggerSync() {
    return _$triggerSyncAsyncAction.run(() => super.triggerSync());
  }

  late final _$addScanAsyncAction =
      AsyncAction('SyncStoreBase.addScan', context: context);

  @override
  Future<String> addScan(
      {required String barcode,
      required String format,
      String? action,
      String? notes,
      String? userId,
      DateTime? scannedAt}) {
    return _$addScanAsyncAction.run(() => super.addScan(
        barcode: barcode,
        format: format,
        action: action,
        notes: notes,
        userId: userId,
        scannedAt: scannedAt));
  }

  late final _$deleteScanAsyncAction =
      AsyncAction('SyncStoreBase.deleteScan', context: context);

  @override
  Future<void> deleteScan(Scan scan) {
    return _$deleteScanAsyncAction.run(() => super.deleteScan(scan));
  }

  late final _$clearSyncedScansAsyncAction =
      AsyncAction('SyncStoreBase.clearSyncedScans', context: context);

  @override
  Future<void> clearSyncedScans() {
    return _$clearSyncedScansAsyncAction.run(() => super.clearSyncedScans());
  }

  late final _$clearAllScansAsyncAction =
      AsyncAction('SyncStoreBase.clearAllScans', context: context);

  @override
  Future<void> clearAllScans() {
    return _$clearAllScansAsyncAction.run(() => super.clearAllScans());
  }

  late final _$SyncStoreBaseActionController =
      ActionController(name: 'SyncStoreBase', context: context);

  @override
  void updateSyncStats() {
    final _$actionInfo = _$SyncStoreBaseActionController.startAction(
        name: 'SyncStoreBase.updateSyncStats');
    try {
      return super.updateSyncStats();
    } finally {
      _$SyncStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _onSyncStatusChanged(SyncStatus status) {
    final _$actionInfo = _$SyncStoreBaseActionController.startAction(
        name: 'SyncStoreBase._onSyncStatusChanged');
    try {
      return super._onSyncStatusChanged(status);
    } finally {
      _$SyncStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _onSyncProgressChanged(int current, int total) {
    final _$actionInfo = _$SyncStoreBaseActionController.startAction(
        name: 'SyncStoreBase._onSyncProgressChanged');
    try {
      return super._onSyncProgressChanged(current, total);
    } finally {
      _$SyncStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
isSyncing: ${isSyncing},
syncStats: ${syncStats},
syncProgress: ${syncProgress},
syncTotal: ${syncTotal},
lastSyncError: ${lastSyncError},
lastSyncTime: ${lastSyncTime},
hasUnsyncedScans: ${hasUnsyncedScans},
syncPercentage: ${syncPercentage},
syncStatusText: ${syncStatusText}
    ''';
  }
}
