import 'package:hive_flutter/hive_flutter.dart';

class SettingsService {
  static const String _boxName = 'settings';
  static const String _pinKey = 'admin_pin';

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
}
