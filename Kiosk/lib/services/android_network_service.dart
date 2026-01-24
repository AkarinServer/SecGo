import 'package:flutter/services.dart';

class HotspotInfo {
  final bool enabled;
  final String? ssid;
  final String? password;

  const HotspotInfo({
    required this.enabled,
    required this.ssid,
    required this.password,
  });

  factory HotspotInfo.fromMap(Map<dynamic, dynamic> map) {
    return HotspotInfo(
      enabled: map['enabled'] == true,
      ssid: map['ssid']?.toString(),
      password: map['password']?.toString(),
    );
  }
}

class AndroidNetworkService {
  static const MethodChannel _channel = MethodChannel('com.secgo.kiosk/network');

  Future<bool> getHotspotEnabled() async {
    final enabled = await _channel.invokeMethod<bool>('getHotspotEnabled');
    return enabled ?? false;
  }

  Future<HotspotInfo> getHotspotInfo() async {
    final info = await _channel.invokeMethod<dynamic>('getHotspotInfo');
    if (info is Map) return HotspotInfo.fromMap(info);
    return const HotspotInfo(enabled: false, ssid: null, password: null);
  }

  Future<bool> setHotspotEnabled(bool enabled) async {
    final ok = await _channel.invokeMethod<bool>(
      'setHotspotEnabled',
      {'enabled': enabled},
    );
    return ok ?? false;
  }

  Future<void> openHotspotSettings() async {
    await _channel.invokeMethod<void>('openHotspotSettings');
  }

  Future<bool> getMobileDataEnabled() async {
    final enabled = await _channel.invokeMethod<bool>('getMobileDataEnabled');
    return enabled ?? false;
  }

  Future<bool> setMobileDataEnabled(bool enabled) async {
    final ok = await _channel.invokeMethod<bool>(
      'setMobileDataEnabled',
      {'enabled': enabled},
    );
    return ok ?? false;
  }

  Future<void> openInternetSettings() async {
    await _channel.invokeMethod<void>('openInternetSettings');
  }
}
