import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:manager/models/kiosk.dart';
import 'package:manager/services/kiosk_client/kiosk_client.dart';
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
  List<FileSystemEntity> _backups = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    final dir = await getApplicationSupportDirectory();
    final backupDir = Directory(path.join(dir.path, 'backups', 'kiosk_${widget.kiosk.id}'));
    if (await backupDir.exists()) {
      setState(() {
        _backups = backupDir.listSync()
            .where((e) => e.path.endsWith('.db'))
            .toList()
          ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      });
    } else {
      setState(() {
        _backups = [];
      });
    }
  }

  Future<void> _createBackup() async {
    setState(() => _isLoading = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final dir = await getApplicationSupportDirectory();
      final backupDir = Directory(path.join(dir.path, 'backups', 'kiosk_${widget.kiosk.id}'));
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = path.join(backupDir.path, 'backup_$timestamp.db');

      final success = await _kioskService.downloadBackup(
        widget.kiosk.ip, 
        widget.kiosk.port, 
        widget.kiosk.pin, 
        filePath
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.backupCreated)),
          );
        }
        await _loadBackups();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.backupCreateFailed)),
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
      final success = await _kioskService.restoreBackup(
        widget.kiosk.ip,
        widget.kiosk.port,
        widget.kiosk.pin,
        file,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.restoreCompleted)),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.restoreFailed)),
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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupRestore)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: _createBackup,
                    icon: const Icon(Icons.save),
                    label: Text(l10n.createNewBackup),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: _backups.isEmpty
                      ? Center(child: Text(l10n.noBackupsFound))
                      : ListView.builder(
                          itemCount: _backups.length,
                          itemBuilder: (context, index) {
                            final file = _backups[index] as File;
                            final stat = file.statSync();
                            final name = path.basename(file.path);
                            final date = DateFormat('yyyy-MM-dd HH:mm').format(stat.modified);

                            return ListTile(
                              leading: const Icon(Icons.backup),
                              title: Text(name),
                              subtitle: Text(date),
                              trailing: ElevatedButton(
                                onPressed: () => _restoreBackup(file),
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
