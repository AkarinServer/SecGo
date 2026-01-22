import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class SettingsService {
  static const String _boxName = 'settings';
  static const String _pinKey = 'admin_pin';
  static const String _deviceIdKey = 'device_id';
  static const String _paymentQrKey = 'payment_qr';

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
    return _box.get(_paymentQrKey);
  }

  Future<void> setPaymentQr(String base64) async {
    await _box.put(_paymentQrKey, base64);
  }

  String? getDeviceId() {
    return _box.get(_deviceIdKey);
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
