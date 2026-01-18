import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:kiosk/models/product.dart';

class ApiService {
  // Use localhost for iOS simulator/Android emulator mapping
  // Android Emulator: 10.0.2.2
  // iOS Simulator: 127.0.0.1
  // Real Device: Need actual local IP
  static const String baseUrl = 'http://127.0.0.1:8080';

  Future<Product?> getProduct(String barcode) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products/$barcode'));
      if (response.statusCode == 200) {
        return Product.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('Error getting product: $e');
    }
    return null;
  }

  Future<String?> getPaymentQr() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/payment_qr'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']; // Returns base64 string
      }
    } catch (e) {
      debugPrint('Error getting QR: $e');
    }
    return null;
  }
}
