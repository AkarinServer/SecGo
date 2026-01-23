import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

class AndroidNotificationListenerService {
  static const MethodChannel _methodChannel =
      MethodChannel('com.secgo.kiosk/notification_listener');
  static const EventChannel _eventChannel =
      EventChannel('com.secgo.kiosk/notifications');

  Stream<Map<String, dynamic>>? _events;

  Stream<Map<String, dynamic>> events() {
    if (!Platform.isAndroid) {
      return const Stream.empty();
    }
    _events ??= _eventChannel
        .receiveBroadcastStream()
        .map((e) => Map<String, dynamic>.from(e as Map));
    return _events!;
  }

  Future<bool> isEnabled() async {
    if (!Platform.isAndroid) return false;
    final enabled =
        await _methodChannel.invokeMethod<bool>('isNotificationListenerEnabled');
    return enabled ?? false;
  }

  Future<Map<String, dynamic>> getAlipayState() async {
    if (!Platform.isAndroid) {
      return {
        'enabled': false,
        'hasAlipay': false,
        'updatedAtMs': 0,
      };
    }
    final state = await _methodChannel
        .invokeMethod<Map>('getAlipayNotificationState')
        .then((v) => Map<String, dynamic>.from(v ?? const <String, dynamic>{}));
    state.putIfAbsent('enabled', () => false);
    state.putIfAbsent('hasAlipay', () => false);
    state.putIfAbsent('updatedAtMs', () => 0);
    return state;
  }

  Future<Map<String, dynamic>> getWechatState() async {
    if (!Platform.isAndroid) {
      return {
        'enabled': false,
        'hasWechat': false,
        'updatedAtMs': 0,
      };
    }
    final state = await _methodChannel
        .invokeMethod<Map>('getWechatNotificationState')
        .then((v) => Map<String, dynamic>.from(v ?? const <String, dynamic>{}));
    state.putIfAbsent('enabled', () => false);
    state.putIfAbsent('hasWechat', () => false);
    state.putIfAbsent('updatedAtMs', () => 0);
    return state;
  }

  Future<Map<String, dynamic>?> getLatestAlipayNotification() async {
    if (!Platform.isAndroid) return null;
    final data = await _methodChannel
        .invokeMethod<Map>('getLatestAlipayNotification')
        .then((v) => v == null ? null : Map<String, dynamic>.from(v));
    return data;
  }

  Future<Map<String, dynamic>?> getLatestAlipayPaymentNotification() async {
    if (!Platform.isAndroid) return null;
    final data = await _methodChannel
        .invokeMethod<Map>('getLatestAlipayPaymentNotification')
        .then((v) => v == null ? null : Map<String, dynamic>.from(v));
    return data;
  }

  Future<Map<String, dynamic>?> getLatestWechatNotification() async {
    if (!Platform.isAndroid) return null;
    final data = await _methodChannel
        .invokeMethod<Map>('getLatestWechatNotification')
        .then((v) => v == null ? null : Map<String, dynamic>.from(v));
    return data;
  }

  Future<Map<String, dynamic>?> getLatestWechatPaymentNotification() async {
    if (!Platform.isAndroid) return null;
    final data = await _methodChannel
        .invokeMethod<Map>('getLatestWechatPaymentNotification')
        .then((v) => v == null ? null : Map<String, dynamic>.from(v));
    return data;
  }

  Future<List<Map<String, dynamic>>> getActiveAlipayNotificationsSnapshot() async {
    if (!Platform.isAndroid) return const [];
    final data = await _methodChannel
        .invokeMethod<List>('getActiveAlipayNotificationsSnapshot')
        .then((v) => (v ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList());
    return data;
  }

  Future<List<Map<String, dynamic>>> getActiveWechatNotificationsSnapshot() async {
    if (!Platform.isAndroid) return const [];
    final data = await _methodChannel
        .invokeMethod<List>('getActiveWechatNotificationsSnapshot')
        .then((v) => (v ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList());
    return data;
  }

  Future<void> openSettings() async {
    if (!Platform.isAndroid) return;
    await _methodChannel.invokeMethod('openNotificationListenerSettings');
  }
}
