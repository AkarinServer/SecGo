import 'dart:io';

import 'package:flutter/services.dart';

class AndroidLauncherService {
  static const MethodChannel _methodChannel =
      MethodChannel('com.secgo.kiosk/notification_listener');

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

