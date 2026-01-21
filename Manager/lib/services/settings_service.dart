import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _keyApiUrl = 'api_url';
  // Defaulting to AliCloud API for Universal
  static const String _defaultUniversalApiUrl = 'https://barcode100.market.alicloudapi.com/getBarcode?Code=';

  Future<String> getApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyApiUrl) ?? _defaultUniversalApiUrl;
  }

  Future<void> setApiUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApiUrl, url);
  }
}
