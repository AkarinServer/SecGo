import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:manager/db/database_helper.dart';
import 'package:manager/models/product.dart';
import 'package:manager/services/kiosk_client/kiosk_client.dart';
import 'package:manager/services/kiosk_connection_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class TestService {
  final KioskClientService _kioskService = KioskClientService();
  final KioskConnectionService _connectionService = KioskConnectionService();

  Future<void> runSyncTest() async {
    debugPrint('TEST_START: runSyncTest');
    try {
      if (!_connectionService.hasConnectedKiosk) {
        debugPrint('TEST_FAIL: No connected kiosk');
        return;
      }
      final kiosk = _connectionService.connectedKiosk!;
      
      // 1. Create Test Product
      final testProduct = Product(
        barcode: 'TEST_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Test Item ${DateTime.now().hour}:${DateTime.now().minute}',
        price: 99.99,
        lastUpdated: DateTime.now().millisecondsSinceEpoch,
      );

      debugPrint('TEST_INFO: Created product ${testProduct.barcode}');
      await DatabaseHelper.instance.upsertProduct(testProduct);

      // 2. Sync
      debugPrint('TEST_INFO: Attempting sync to ${kiosk.ip}');
      final success = await _kioskService.syncProductsToKiosk(kiosk.ip, kiosk.port, kiosk.pin);

      if (success) {
        debugPrint('SYNC_TEST: PASSED');
      } else {
        debugPrint('SYNC_TEST: FAILED - Sync call returned false');
      }
    } catch (e) {
      debugPrint('SYNC_TEST: FAILED - Exception: $e');
    }
  }

  Future<void> runBackupTest() async {
    debugPrint('TEST_START: runBackupTest');
    try {
      if (!_connectionService.hasConnectedKiosk) {
        debugPrint('TEST_FAIL: No connected kiosk');
        return;
      }
      final kiosk = _connectionService.connectedKiosk!;
      final dir = await getApplicationDocumentsDirectory();
      final backupDir = Directory(path.join(dir.path, 'test_backups'));
      if (!await backupDir.exists()) await backupDir.create();
      
      final filePath = path.join(backupDir.path, 'test_backup.db');
      
      // 1. Download Backup
      debugPrint('TEST_INFO: Downloading backup to $filePath');
      final downloadSuccess = await _kioskService.downloadBackup(kiosk.ip, kiosk.port, kiosk.pin, filePath);
      
      if (!downloadSuccess) {
        debugPrint('BACKUP_TEST: FAILED - Download failed');
        return;
      }
      
      if (!File(filePath).existsSync()) {
        debugPrint('BACKUP_TEST: FAILED - File not found');
        return;
      }
      
      debugPrint('TEST_INFO: Backup file size: ${File(filePath).lengthSync()} bytes');

      // 2. Restore Backup
      debugPrint('TEST_INFO: Restoring backup');
      final restoreResult = await _kioskService.restoreBackup(
        kiosk.ip,
        kiosk.port,
        kiosk.pin,
        File(filePath),
      );

      if (restoreResult.success) {
        debugPrint('RESTORE_TEST: PASSED');
      } else {
        debugPrint('RESTORE_TEST: FAILED - ${restoreResult.message}');
      }

    } catch (e) {
      debugPrint('BACKUP_RESTORE_TEST: FAILED - Exception: $e');
    }
  }
}
