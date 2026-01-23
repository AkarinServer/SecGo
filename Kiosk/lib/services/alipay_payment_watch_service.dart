import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kiosk/db/database_helper.dart';
import 'package:kiosk/services/android_notification_listener_service.dart';

class AlipayPaymentWatchResult {
  final bool matched;
  final bool timedOut;
  final bool amountMismatched;
  final String? mismatchText;

  const AlipayPaymentWatchResult._({
    required this.matched,
    required this.timedOut,
    required this.amountMismatched,
    this.mismatchText,
  });

  const AlipayPaymentWatchResult.matched()
      : this._(matched: true, timedOut: false, amountMismatched: false);

  const AlipayPaymentWatchResult.timedOut()
      : this._(matched: false, timedOut: true, amountMismatched: false);

  const AlipayPaymentWatchResult.amountMismatched(String text)
      : this._(
          matched: false,
          timedOut: false,
          amountMismatched: true,
          mismatchText: text,
        );
}

class AlipayPaymentWatchService {
  AlipayPaymentWatchService({
    AndroidNotificationListenerService? androidNotificationListenerService,
    DatabaseHelper? databaseHelper,
  })  : _notificationListenerService =
            androidNotificationListenerService ?? AndroidNotificationListenerService(),
        _db = databaseHelper ?? DatabaseHelper.instance;

  final AndroidNotificationListenerService _notificationListenerService;
  final DatabaseHelper _db;

  StreamSubscription<Map<String, dynamic>>? _sub;
  Timer? _timeoutTimer;
  Timer? _pollTimer;
  bool _active = false;
  final Map<String, int> _seenMaxPostTimeByKey = {};
  final Set<String> _loggedParseFailureKeys = {};

  Future<void> stop() async {
    _active = false;
    await _sub?.cancel();
    _sub = null;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _seenMaxPostTimeByKey.clear();
    _loggedParseFailureKeys.clear();
  }

  Future<Set<String>> buildBaselineKeys() async {
    final snapshot = await _notificationListenerService.getActiveAlipayNotificationsSnapshot();
    final keys = <String>{};
    for (final n in snapshot) {
      final key = n['key'];
      if (key is String && key.isNotEmpty) {
        keys.add(key);
      }
    }
    return keys;
  }

  Future<void> start({
    required String orderId,
    required double orderAmount,
    required int checkoutTimeMs,
    required Set<String> baselineKeys,
    required void Function() onMatched,
    required void Function(String message) onMismatch,
    required void Function() onTimeout,
  }) async {
    await stop();
    _active = true;

    final expectedFen = _amountToFen(orderAmount);
    debugPrint(
      'AlipayWatch start orderId=$orderId expectedFen=$expectedFen checkoutTimeMs=$checkoutTimeMs baselineKeys=${baselineKeys.length}',
    );
    _timeoutTimer = Timer(const Duration(minutes: 5), () async {
      if (!_active) return;
      await stop();
      debugPrint('AlipayWatch timeout orderId=$orderId');
      onTimeout();
    });

    _sub = _notificationListenerService.events().listen((event) async {
      if (!_active) return;

      final type = event['type'];
      if (type != 'posted') return;

      final payload = event['notification'];
      if (payload is! Map) return;

      await _evaluateNotification(
        notification: Map<String, dynamic>.from(payload),
        expectedFen: expectedFen,
        orderId: orderId,
        checkoutTimeMs: checkoutTimeMs,
        baselineKeys: baselineKeys,
        onMatched: onMatched,
        onMismatch: onMismatch,
      );
    });

    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!_active) return;
      final snapshot = await _notificationListenerService.getActiveAlipayNotificationsSnapshot();
      for (final n in snapshot) {
        if (!_active) return;
        await _evaluateNotification(
          notification: n,
          expectedFen: expectedFen,
          orderId: orderId,
          checkoutTimeMs: checkoutTimeMs,
          baselineKeys: baselineKeys,
          onMatched: onMatched,
          onMismatch: onMismatch,
        );
      }
    });
  }

  Future<void> _evaluateNotification({
    required Map<String, dynamic> notification,
    required int expectedFen,
    required String orderId,
    required int checkoutTimeMs,
    required Set<String> baselineKeys,
    required void Function() onMatched,
    required void Function(String message) onMismatch,
  }) async {
    if (!_active) return;
    final packageName = notification['package'];
    if (packageName != 'com.eg.android.AlipayGphone') return;

    final key = notification['key'];
    if (key is! String || key.isEmpty) return;

    final postTime = notification['postTime'];
    if (postTime is! int) return;
    if (postTime <= checkoutTimeMs) return;

    final seenPostTime = _seenMaxPostTimeByKey[key];
    if (seenPostTime != null && postTime <= seenPostTime) return;
    _seenMaxPostTimeByKey[key] = postTime;

    if (baselineKeys.contains(key)) return;

    final title = _toStrOrNull(notification['title']);
    final text = _toStrOrNull(notification['text']);
    final bigText = _toStrOrNull(notification['bigText']);
    final combined = [title, text, bigText].whereType<String>().join(' ');
    if (!combined.contains('成功收款')) return;

    final parsedFen = parseSuccessAmountFen(combined);
    if (parsedFen == null) {
      if (_loggedParseFailureKeys.add(key)) {
        debugPrint(
          'AlipayWatch parseFailed orderId=$orderId key=$key postTime=$postTime combined=$combined',
        );
      }
      return;
    }

    if (parsedFen != expectedFen) {
      debugPrint(
        'AlipayWatch mismatch orderId=$orderId key=$key postTime=$postTime expectedFen=$expectedFen parsedFen=$parsedFen text=${text ?? bigText ?? ""}',
      );
      onMismatch('mismatch: expectedFen=$expectedFen parsedFen=$parsedFen');
      return;
    }

    final used = await _db.isAlipayNotificationKeyAlreadyUsed(key);
    if (used) return;

    debugPrint(
      'AlipayWatch matched orderId=$orderId key=$key postTime=$postTime fen=$parsedFen',
    );
    await _db.updateOrderAlipayMatch(
      orderId: orderId,
      checkoutTimeMs: checkoutTimeMs,
      matchedKey: key,
      matchedPostTimeMs: postTime,
      matchedTitle: title,
      matchedText: text ?? bigText,
      matchedParsedAmountFen: parsedFen,
    );

    await stop();
    onMatched();
  }

  static String? _toStrOrNull(Object? v) {
    if (v == null) return null;
    if (v is String) return v;
    return v.toString();
  }

  static int _amountToFen(double amount) {
    final s = amount.toStringAsFixed(2);
    return _decimalStringToFen(s);
  }

  static int _decimalStringToFen(String s) {
    final cleaned = s.trim().replaceAll(',', '');
    final parts = cleaned.split('.');
    final intPart = parts.isEmpty ? '0' : parts[0].isEmpty ? '0' : parts[0];
    final frac = parts.length > 1 ? parts[1] : '';
    final frac2 = '${frac}00'.substring(0, 2);
    final fenStr = '$intPart$frac2';
    return int.parse(fenStr);
  }

  static int? parseSuccessAmountFen(String s) {
    final m = RegExp(r'成功收款\s*[¥￥]?\s*([0-9][0-9,]*)(?:\.([0-9]{1,2}))?\s*元')
        .firstMatch(s);
    if (m == null) return null;
    final intPart = (m.group(1) ?? '').replaceAll(',', '');
    if (intPart.isEmpty) return null;
    final frac = m.group(2) ?? '';
    final frac2 = '${frac}00'.substring(0, 2);
    return int.parse('$intPart$frac2');
  }
}
