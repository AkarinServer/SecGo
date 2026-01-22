import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:manager/models/product.dart';
import 'package:manager/services/settings_service.dart';
import 'package:manager/services/middleware/product_middleware.dart';
import 'package:manager/services/middleware/universal_product_middleware.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  final SettingsService _settingsService = SettingsService();

  // Use localhost for iOS simulator/Android emulator mapping
  // Android Emulator: 10.0.2.2
  // iOS Simulator: 127.0.0.1
  // Real Device: Need actual local IP
  static const String baseUrl = 'http://127.0.0.1:8080'; 

  Future<Product?> getProduct(String barcode) async {
    try {
      // 1. Try configured External API
      final apiUrl = await _settingsService.getApiUrl();
      // Always use Universal Middleware
      ProductMiddleware middleware = UniversalProductMiddleware();

      if (apiUrl.isNotEmpty) {
        String fullUrl;
        Map<String, String> headers = {};

        // Universal API (AliCloud) logic
        // Pattern: https://barcode100.market.alicloudapi.com/getBarcode?Code={barcode}
        // We assume the user set the base URL to: https://barcode100.market.alicloudapi.com/getBarcode
        
        if (apiUrl.contains('?')) {
          fullUrl = '$apiUrl$barcode'; // e.g. ...?Code=
        } else {
          // If user entered base path without query param, we append it
          // This is a bit specific to this AliCloud API, but we can make it smart
          // For now, let's assume the user configures the full prefix like:
          // https://barcode100.market.alicloudapi.com/getBarcode?Code=
          fullUrl = '$apiUrl$barcode';
        }

        final appCode = dotenv.env['ALI_CLOUD_APP_CODE'];
        if (appCode != null && appCode.isNotEmpty) {
          headers['Authorization'] = 'APPCODE $appCode';
        } else {
          // If AppCode is missing for AliCloud, abort the request to prevent errors
          // or fallback to manual entry (return null)
          debugPrint('AliCloud AppCode is missing in .env');
          return null;
        }

        final extResponse = await http.get(Uri.parse(fullUrl), headers: headers);
        if (extResponse.statusCode == 200) {
           final data = jsonDecode(extResponse.body);
           return middleware.parse(barcode, data);
        }
      }
    } catch (e) {
      debugPrint('Error getting product: $e');
    }
    return null;
  }

  Future<bool> saveProduct(Product product) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'barcode': product.barcode,
          'name': product.name,
          'price': product.price,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error saving product: $e');
      return false;
    }
  }

  Future<bool> uploadPaymentQr(String base64Image) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payment_qr'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'data': base64Image}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error uploading QR: $e');
      return false;
    }
  }
}
