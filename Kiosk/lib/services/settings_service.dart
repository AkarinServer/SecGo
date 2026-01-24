import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class SettingsService {
  static const String _boxName = 'settings';
  static const String _pinKey = 'admin_pin';
  static const String _deviceIdKey = 'device_id';
  static const String _paymentQrKey = 'payment_qr';
  static const String _paymentQrsKey = 'payment_qrs';
  static const String _pendingPaymentOrderIdKey = 'pending_payment_order_id';
  static const String _homeAppPackageKey = 'home_app_package';

  Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  Box get _box => Hive.box(_boxName);

  String? getPin() {
    return _box.get(_pinKey);
  }

  Future<void> setPin(String pin) async {
    await _box.put(_pinKey, pin);
  }

  bool hasPin() {
    return _box.containsKey(_pinKey);
  }

  String? getPaymentQr() {
    final qrs = getPaymentQrs();
    if (qrs.isEmpty) return _box.get(_paymentQrKey);
    return qrs['alipay'] ?? qrs['wechat'] ?? qrs['default'] ?? qrs.values.first;
  }

  Future<void> setPaymentQr(String base64) async {
    await _box.put(_paymentQrKey, base64);
    final current = getPaymentQrs();
    current['default'] = base64;
    await _box.put(_paymentQrsKey, current);
  }

  Map<String, String> getPaymentQrs() {
    final v = _box.get(_paymentQrsKey);
    if (v is Map) {
      final result = <String, String>{};
      for (final entry in v.entries) {
        final k = entry.key?.toString();
        final val = entry.value?.toString();
        if (k == null || k.isEmpty) continue;
        if (val == null || val.isEmpty) continue;
        result[k] = val;
      }
      if (result.isNotEmpty) return result;
    }
    final legacy = _box.get(_paymentQrKey);
    if (legacy is String && legacy.isNotEmpty) {
      return {'default': legacy};
    }
    return {};
  }

  Future<void> setPaymentQrForProvider(String provider, String base64) async {
    final key = provider.trim().toLowerCase();
    if (key.isEmpty) return;
    final current = getPaymentQrs();
    current[key] = base64;
    await _box.put(_paymentQrsKey, current);
  }

  String? getDeviceId() {
    return _box.get(_deviceIdKey);
  }

  String? getPendingPaymentOrderId() {
    final v = _box.get(_pendingPaymentOrderIdKey);
    if (v is String && v.isNotEmpty) return v;
    return null;
  }

  Future<void> setPendingPaymentOrderId(String? orderId) async {
    final id = orderId?.trim();
    if (id == null || id.isEmpty) {
      await _box.delete(_pendingPaymentOrderIdKey);
      return;
    }
    await _box.put(_pendingPaymentOrderIdKey, id);
  }

  String? getHomeAppPackage() {
    final v = _box.get(_homeAppPackageKey);
    if (v is String) {
      final s = v.trim();
      return s.isEmpty ? null : s;
    }
    return null;
  }

  Future<void> setHomeAppPackage(String? packageName) async {
    final v = packageName?.trim();
    if (v == null || v.isEmpty) {
      await _box.delete(_homeAppPackageKey);
      return;
    }
    await _box.put(_homeAppPackageKey, v);
  }


  Future<String> getOrCreateDeviceId() async {
    final existing = getDeviceId();
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final id = const Uuid().v4();
    await _box.put(_deviceIdKey, id);
    return id;
  }
}
