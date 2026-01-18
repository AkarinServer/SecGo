import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _keyApiUrl = 'api_url';
  static const String _keyMiddlewareType = 'middleware_type';
  static const String _defaultApiUrl = 'https://world.openfoodfacts.org/api/v0/product/';
  // Defaulting to AliCloud API for Universal
  static const String _defaultUniversalApiUrl = 'https://barcode100.market.alicloudapi.com/getBarcode?Code=';
  static const String _defaultMiddlewareType = 'open_food_facts';

  Future<String> getApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyApiUrl) ?? _defaultApiUrl;
  }

  Future<void> setApiUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApiUrl, url);
  }

  Future<String> getMiddlewareType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyMiddlewareType) ?? _defaultMiddlewareType;
  }

  Future<void> setMiddlewareType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMiddlewareType, type);
  }
}
