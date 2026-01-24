import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:manager/models/kiosk.dart';
import 'package:manager/services/kiosk_client/kiosk_client.dart';
import 'package:manager/services/kiosk_connection_service.dart';
import 'package:path/path.dart' as path;
import 'package:manager/l10n/app_localizations.dart';

class KioskBackupScreen extends StatefulWidget {
  final Kiosk kiosk;

  const KioskBackupScreen({super.key, required this.kiosk});

  @override
  State<KioskBackupScreen> createState() => _KioskBackupScreenState();
}

class _KioskBackupScreenState extends State<KioskBackupScreen> {
  final KioskClientService _kioskService = KioskClientService();
  final KioskConnectionService _connectionService = KioskConnectionService();
  List<_BackupEntry> _backups = [];
  bool _showAllKiosks = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _connectionService.addListener(_onConnectionChange);
    _loadBackups();
  }

  @override
  void dispose() {
    _connectionService.removeListener(_onConnectionChange);
    super.dispose();
  }

  void _onConnectionChange() {
    if (mounted) setState(() {});
  }

  bool get _isConnected {
    final kioskId = widget.kiosk.id;
    if (kioskId == null) return _connectionService.hasConnectedKiosk;
    return _connectionService.isKioskConnected(kioskId);
  }

  Future<void> _loadBackups() async {
    final dir = await getApplicationSupportDirectory();
    final root = Directory(path.join(dir.path, 'backups'));
    if (!await root.exists()) {
      if (mounted) setState(() => _backups = []);
      return;
    }

    final entries = <_BackupEntry>[];
    if (_showAllKiosks) {
      final children = root.listSync();
      for (final entity in children) {
        if (entity is! Directory) continue;
        final name = path.basename(entity.path);
        final sourceId = _parseKioskIdFromDirName(name);
        final dbFiles = entity
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.db'))
            .toList();
        for (final f in dbFiles) {
          entries.add(_BackupEntry(file: f, sourceKioskId: sourceId, modified: f.statSync().modified));
        }
      }
    } else {
      final kioskKey = _kioskBackupKey();
      final backupDir = Directory(path.join(root.path, kioskKey));
      if (await backupDir.exists()) {
        final dbFiles = backupDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.db'))
            .toList();
        for (final f in dbFiles) {
          entries.add(_BackupEntry(file: f, sourceKioskId: widget.kiosk.id, modified: f.statSync().modified));
        }
      }
    }

    entries.sort((a, b) => b.modified.compareTo(a.modified));
    if (mounted) setState(() => _backups = entries);
  }

  String _kioskBackupKey() {
    final id = widget.kiosk.id;
    if (id != null) return 'kiosk_$id';
    final deviceId = widget.kiosk.deviceId;
    if (deviceId != null && deviceId.isNotEmpty) return 'kiosk_$deviceId';
    return 'kiosk_${widget.kiosk.ip}';
  }

  int? _parseKioskIdFromDirName(String name) {
    final match = RegExp(r'^kiosk_(\d+)$').firstMatch(name);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  Future<void> _createBackup() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.kioskNotConnected)),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final dir = await getApplicationSupportDirectory();
      final backupDir = Directory(path.join(dir.path, 'backups', _kioskBackupKey()));
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = path.join(backupDir.path, 'backup_$timestamp.db');

      final result = await _kioskService.downloadBackup(
        widget.kiosk.ip, 
        widget.kiosk.port, 
        widget.kiosk.pin, 
        filePath
      );

      if (result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.backupCreated)),
          );
        }
        await _loadBackups();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.backupCreateFailedWithReason(result.message ?? l10n.backupCreateFailed),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithMessage(e))),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreBackup(File file) async {
    final l10n = AppLocalizations.of(context)!;
    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.kioskNotConnected)),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmRestore),
        content: Text(l10n.restoreOverwriteWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.restore),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final result = await _kioskService.restoreBackup(
        widget.kiosk.ip,
        widget.kiosk.port,
        widget.kiosk.pin,
        file,
      );

      if (result.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.restoreCompleted)),
        );
        await _connectionService.refresh();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.restoreFailedWithReason(result.message ?? l10n.restoreFailed),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithMessage(e))),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isConnected = _isConnected;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupRestore)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: isConnected ? _createBackup : null,
                    icon: const Icon(Icons.save),
                    label: Text(l10n.createNewBackup),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          Localizations.localeOf(context).languageCode == 'zh'
                              ? '显示全部终端备份'
                              : 'Show backups from all kiosks',
                        ),
                      ),
                      Switch(
                        value: _showAllKiosks,
                        onChanged: (v) async {
                          setState(() => _showAllKiosks = v);
                          await _loadBackups();
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: _backups.isEmpty
                      ? Center(child: Text(l10n.noBackupsFound))
                      : ListView.builder(
                          itemCount: _backups.length,
                          itemBuilder: (context, index) {
                            final entry = _backups[index];
                            final file = entry.file;
                            final name = path.basename(file.path);
                            final date = DateFormat('yyyy-MM-dd HH:mm').format(entry.modified);
                            final sourceLabel = entry.sourceKioskId == null
                                ? (Localizations.localeOf(context).languageCode == 'zh'
                                    ? '来源：未知终端'
                                    : 'Source: unknown kiosk')
                                : (Localizations.localeOf(context).languageCode == 'zh'
                                    ? '来源：终端 ${entry.sourceKioskId}'
                                    : 'Source: kiosk ${entry.sourceKioskId}');

                            return ListTile(
                              leading: const Icon(Icons.backup),
                              title: Text(name),
                              subtitle: Text('$date • $sourceLabel'),
                              trailing: ElevatedButton(
                                onPressed: isConnected ? () => _restoreBackup(file) : null,
                                child: Text(l10n.restore),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _BackupEntry {
  final File file;
  final int? sourceKioskId;
  final DateTime modified;

  const _BackupEntry({
    required this.file,
    required this.sourceKioskId,
    required this.modified,
  });
}
