import 'package:flutter/services.dart';

class AndroidNetworkService {
  static const MethodChannel _channel = MethodChannel('com.secgo.kiosk/network');

  Future<bool> getHotspotEnabled() async {
    final enabled = await _channel.invokeMethod<bool>('getHotspotEnabled');
    return enabled ?? false;
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

