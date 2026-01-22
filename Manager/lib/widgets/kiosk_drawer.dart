import 'dart:async';
import 'package:flutter/material.dart';
import 'package:manager/db/database_helper.dart';
import 'package:manager/models/kiosk.dart';
import 'package:manager/screens/sync_kiosk_screen.dart';
import 'package:manager/services/kiosk_connection_service.dart';
import 'package:manager/screens/kiosk_backup_screen.dart';
import 'package:manager/services/test_service.dart'; // Add TestService
import 'package:manager/screens/kiosk_history_screen.dart'; // Re-added
import 'package:manager/l10n/app_localizations.dart';

class KioskDrawer extends StatefulWidget {
  const KioskDrawer({super.key});

  @override
  State<KioskDrawer> createState() => _KioskDrawerState();
}

class _KioskDrawerState extends State<KioskDrawer> {
  final KioskConnectionService _connectionService = KioskConnectionService();

  @override
  void initState() {
    super.initState();
    _connectionService.addListener(_onConnectionChange);
    // Initial fetch handled by service startMonitoring usually, but we can trigger refresh
    _connectionService.refresh();
  }

  @override
  void dispose() {
    _connectionService.removeListener(_onConnectionChange);
    super.dispose();
  }

  void _onConnectionChange() {
    if (mounted) setState(() {});
  }

  // ... (remove _loadKiosks, _startConnectionMonitor, _refreshConnections methods as they are now in service)


  Future<void> _openBackupRestore(Kiosk kiosk) async {
    _showBackupOptions(kiosk);
  }

  void _showBackupOptions(Kiosk kiosk) {
    Navigator.pop(context); // Close drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => KioskBackupScreen(kiosk: kiosk)),
    );
  }

  Future<void> _deleteKiosk(int id) async {
    await DatabaseHelper.instance.deleteKiosk(id);
    _connectionService.refresh();
  }

  Future<void> _confirmDeleteKiosk(Kiosk kiosk) async {
    final l10n = AppLocalizations.of(context)!;
    final kioskId = kiosk.id;
    final kioskLabel = kiosk.name ??
        (kioskId != null ? l10n.kioskWithId(kioskId) : l10n.kioskLabel);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeKioskTitle),
        content: Text(l10n.removeKioskMessage(kioskLabel)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );

    if (confirmed == true && kiosk.id != null) {
      await _deleteKiosk(kiosk.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final kiosks = _connectionService.kiosks;
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Center(
              child: Text(
                l10n.pairedKiosks,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          Expanded(
            child: kiosks.isEmpty
                ? Center(child: Text(l10n.noKiosksPaired))
                : ListView.builder(
                    itemCount: kiosks.length,
                    itemBuilder: (context, index) {
                      final kiosk = kiosks[index];
                      final isConnected = _connectionService.isKioskConnected(kiosk.id!);
                      final kioskId = kiosk.id;
                      final kioskLabel = kiosk.name ??
                          (kioskId != null
                              ? l10n.kioskWithId(kioskId)
                              : l10n.kioskLabel);
                      return ListTile(
                        leading: const Icon(Icons.tablet_android),
                        title: Text(kioskLabel),
                        subtitle: Text('${kiosk.ip}:${kiosk.port}'),
                        onTap: () => _openBackupRestore(kiosk),
                        onLongPress: () => _confirmDeleteKiosk(kiosk),
                        trailing: isConnected
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.history, color: Colors.blue),
                                    tooltip: l10n.viewOrderHistory,
                                    onPressed: () {
                                      Navigator.pop(context); // Close drawer
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => KioskHistoryScreen(kiosk: kiosk),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    semanticLabel: l10n.connected,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(l10n.connected),
                                ],
                              )
                            : null, // Removed delete button
                      );
                    },
                  ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner),
            title: Text(l10n.pairNewKiosk),
            onTap: () async {
              Navigator.pop(context); // Close drawer
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SyncKioskScreen()),
              );
              _connectionService.refresh(); // Reload after return
            },
          ),
          // Debug Test Button
          if (kFuture.any((_) => true)) // Always true in dev
             ListTile(
               leading: const Icon(Icons.bug_report, color: Colors.orange),
               title: Text(l10n.runDiagnostics),
               onTap: () async {
                 final testService = TestService();
                 final messenger = ScaffoldMessenger.of(context);
                 messenger.showSnackBar(
                   SnackBar(content: Text(l10n.runningSyncTest)),
                 );
                 await testService.runSyncTest();
                 if (!mounted) return;
                 messenger.showSnackBar(
                   SnackBar(content: Text(l10n.runningBackupTest)),
                 );
                 await testService.runBackupTest();
                 if (!mounted) return;
                 messenger.showSnackBar(
                   SnackBar(content: Text(l10n.testsCompleteCheckLogs)),
                 );
               },
             ),
        ],
      ),
    );
  }
}
// Dummy helper for condition
const List<void> kFuture = [null];
