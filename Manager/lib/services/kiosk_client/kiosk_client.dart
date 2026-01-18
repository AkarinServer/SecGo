import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:manager/models/product.dart';
import 'package:manager/db/database_helper.dart';

class KioskClientService {
  Future<bool> syncProductsToKiosk(String ip, int port, String pin) async {
    try {
      final products = await DatabaseHelper.instance.getAllProducts();
      final productsJson = jsonEncode(products.map((p) => p.toJson()).toList());

      final response = await http.post(
        Uri.parse('http://$ip:$port/sync/products'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $pin',
        },
        body: productsJson,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Sync failed: $e');
      return false;
    }
  }
}
