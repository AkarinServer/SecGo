import 'dart:io';

import 'package:flutter/services.dart';

class AndroidLauncherService {
  static const MethodChannel _methodChannel =
      MethodChannel('com.secgo.kiosk/notification_listener');

  Future<List<Map<String, String>>> listLaunchableApps() async {
    if (!Platform.isAndroid) return const [];
    final data = await _methodChannel
        .invokeMethod<List>('listLaunchableApps')
        .then((v) => (v ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList());
    final result = <Map<String, String>>[];
    for (final e in data) {
      final pkg = e['packageName']?.toString().trim();
      final label = e['label']?.toString().trim();
      if (pkg == null || pkg.isEmpty) continue;
      result.add({'packageName': pkg, 'label': (label == null || label.isEmpty) ? pkg : label});
    }
    return result;
  }

  Future<bool> openLauncherHome() async {
    if (!Platform.isAndroid) return false;
    final ok = await _methodChannel.invokeMethod<bool>('openLauncherHome');
    return ok ?? false;
  }

  Future<bool> openApp(String packageName) async {
    if (!Platform.isAndroid) return false;
    final ok = await _methodChannel.invokeMethod<bool>(
      'openApp',
      {'packageName': packageName},
    );
    return ok ?? false;
  }
}
