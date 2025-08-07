import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../configs/sync_store.dart';
import '../configs/auth_store.dart';
import '../models/scan.dart';

class SyncStatusWidget extends StatelessWidget {
  const SyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        if (!authStore.isAuthenticated) {
          return _buildOfflineIndicator();
        }

        return _buildSyncIndicator(context);
      },
    );
  }

  Widget _buildOfflineIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border.all(color: Colors.orange[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, size: 16, color: Colors.orange[700]),
          const SizedBox(width: 8),
          Text(
            'Offline Mode',
            style: TextStyle(
              color: Colors.orange[700],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncIndicator(BuildContext context) {
    final stats = syncStore.syncStats;
    final isSyncing = syncStore.isSyncing;
    final hasUnsynced = syncStore.hasUnsyncedScans;

    Color backgroundColor;
    Color borderColor;
    Color iconColor;
    Color textColor;
    IconData icon;

    if (isSyncing) {
      backgroundColor = Colors.blue[50]!;
      borderColor = Colors.blue[300]!;
      iconColor = Colors.blue[700]!;
      textColor = Colors.blue[700]!;
      icon = Icons.sync;
    } else if (hasUnsynced) {
      backgroundColor = Colors.orange[50]!;
      borderColor = Colors.orange[300]!;
      iconColor = Colors.orange[700]!;
      textColor = Colors.orange[700]!;
      icon = Icons.cloud_upload;
    } else {
      backgroundColor = Colors.green[50]!;
      borderColor = Colors.green[300]!;
      iconColor = Colors.green[700]!;
      textColor = Colors.green[700]!;
      icon = Icons.cloud_done;
    }

    return GestureDetector(
      onTap: () => _showSyncDetails(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSyncing)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                ),
              )
            else
              Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
            Text(
              syncStore.syncStatusText,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (hasUnsynced && !isSyncing) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${stats.unsynced}',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSyncDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const SyncDetailsSheet(),
    );
  }
}

class SyncDetailsSheet extends StatelessWidget {
  const SyncDetailsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final stats = syncStore.syncStats;
        
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.sync, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Sync Status',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Sync Statistics
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildStatRow('Total Scans', stats.total.toString(), Icons.qr_code),
                      const Divider(),
                      _buildStatRow('Synced', stats.synced.toString(), Icons.cloud_done, Colors.green),
                      _buildStatRow('Pending', stats.pending.toString(), Icons.cloud_upload, Colors.orange),
                      _buildStatRow('Failed', stats.failed.toString(), Icons.error, Colors.red),
                      if (stats.syncing > 0)
                        _buildStatRow('Syncing', stats.syncing.toString(), Icons.sync, Colors.blue),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Progress bar
              if (syncStore.isSyncing) ...[
                Text(
                  'Sync Progress',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: syncStore.syncTotal > 0 
                      ? syncStore.syncProgress / syncStore.syncTotal 
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  '${syncStore.syncProgress} / ${syncStore.syncTotal}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
              ],
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: syncStore.isSyncing ? null : () async {
                        await syncStore.triggerSync();
                      },
                      icon: syncStore.isSyncing 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync),
                      label: Text(syncStore.isSyncing ? 'Syncing...' : 'Sync Now'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showScansList(context);
                      },
                      icon: const Icon(Icons.list),
                      label: const Text('View Scans'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showScansList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const ScansListSheet(),
    );
  }
}

class ScansListSheet extends StatelessWidget {
  const ScansListSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final scans = syncStore.getAllScans();
        
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.list, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'All Scans (${scans.length})',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: scans.length,
                      itemBuilder: (context, index) {
                        final scan = scans[index];
                        return _buildScanItem(context, scan);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildScanItem(BuildContext context, Scan scan) {
    IconData statusIcon;
    Color statusColor;
    
    switch (scan.status) {
      case SyncStatus.synced:
        statusIcon = Icons.cloud_done;
        statusColor = Colors.green;
        break;
      case SyncStatus.pending:
        statusIcon = Icons.cloud_upload;
        statusColor = Colors.orange;
        break;
      case SyncStatus.syncing:
        statusIcon = Icons.sync;
        statusColor = Colors.blue;
        break;
      case SyncStatus.failed:
        statusIcon = Icons.error;
        statusColor = Colors.red;
        break;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(
          scan.barcode,
          style: const TextStyle(fontFamily: 'monospace'),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Format: ${scan.format}'),
            Text('Scanned: ${_formatDateTime(scan.scannedAt)}'),
            if (scan.isFailed && scan.lastError != null)
              Text(
                'Error: ${scan.lastError}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        ),
        trailing: scan.isFailed && scan.retryCount > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Retry ${scan.retryCount}',
                  style: const TextStyle(fontSize: 10, color: Colors.red),
                ),
              )
            : null,
        isThreeLine: true,
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}