import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:manager/db/database_helper.dart';
import 'package:manager/models/kiosk.dart';
import 'package:manager/services/kiosk_client/kiosk_client.dart';

class KioskConnectionService extends ChangeNotifier {
  static final KioskConnectionService _instance = KioskConnectionService._internal();
  static KioskConnectionService? _mockInstance;

  factory KioskConnectionService() => _mockInstance ?? _instance;

  @visibleForTesting
  static set mockInstance(KioskConnectionService? mock) => _mockInstance = mock;

  KioskConnectionService._internal();

  @visibleForTesting
  KioskConnectionService.testing();

  final KioskClientService _kioskService = KioskClientService();
  
  List<Kiosk> _kiosks = [];
  Map<int, bool> _connectionStatus = {};
  Timer? _monitorTimer;
  bool _isChecking = false;

  List<Kiosk> get kiosks => _kiosks;
  bool get hasConnectedKiosk => _connectionStatus.values.any((connected) => connected);
  Kiosk? get connectedKiosk {
    final entry = _connectionStatus.entries.firstWhere(
      (e) => e.value, 
      orElse: () => const MapEntry(-1, false)
    );
    if (entry.value) {
      return _kiosks.firstWhere((k) => k.id == entry.key);
    }
    return null;
  }

  void startMonitoring() {
    _refreshConnections();
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(const Duration(seconds: 5), (_) => _refreshConnections());
  }

  void stopMonitoring() {
    _monitorTimer?.cancel();
  }

  Future<void> _refreshConnections() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final kiosks = await DatabaseHelper.instance.getAllKiosks();
      if (kiosks.isEmpty) {
        _kiosks = [];
        _connectionStatus = {};
        notifyListeners();
        return;
      }

      // Ping concurrently
      final results = await Future.wait(kiosks.map((kiosk) async {
        final deviceId = await _kioskService.fetchDeviceId(kiosk.ip, kiosk.port, kiosk.pin);
        final isMatch = deviceId != null && (kiosk.deviceId == null || kiosk.deviceId == deviceId);
        return MapEntry(kiosk.id!, isMatch);
      }));

      final statusMap = Map.fromEntries(results);

      // Enforce single connection
      final connectedIds = statusMap.entries.where((e) => e.value).map((e) => e.key).toList();
      if (connectedIds.length > 1) {
        // Sort by last synced
        connectedIds.sort((a, b) {
          final kioskA = kiosks.firstWhere((k) => k.id == a);
          final kioskB = kiosks.firstWhere((k) => k.id == b);
          return (kioskB.lastSynced ?? 0).compareTo(kioskA.lastSynced ?? 0);
        });
        // Keep first
        for (var i = 1; i < connectedIds.length; i++) {
          statusMap[connectedIds[i]] = false;
        }
      }

      _kiosks = kiosks;
      _connectionStatus = statusMap;
      notifyListeners();

    } finally {
      _isChecking = false;
    }
  }
  
  bool isKioskConnected(int id) => _connectionStatus[id] ?? false;
  
  // Force refresh
  Future<void> refresh() => _refreshConnections();

  Future<Map<String, dynamic>?> fetchConnectedKioskAlipayNotificationState() async {
    final kiosk = connectedKiosk;
    if (kiosk == null) return null;
    return _kioskService.fetchAlipayNotificationState(kiosk.ip, kiosk.port, kiosk.pin);
  }

  Future<Map<String, dynamic>?> fetchConnectedKioskLatestAlipayNotification() async {
    final kiosk = connectedKiosk;
    if (kiosk == null) return null;
    return _kioskService.fetchLatestAlipayNotification(kiosk.ip, kiosk.port, kiosk.pin);
  }
}
