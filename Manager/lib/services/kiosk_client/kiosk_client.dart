import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:manager/models/product.dart';
import 'package:manager/db/database_helper.dart';

class KioskClientService {
  Future<bool> syncProductsToKiosk(String ip, int port, String pin) async {
    return await bidirectionalSync(ip, port, pin);
  }

  Future<bool> bidirectionalSync(String ip, int port, String pin) async {
    try {
      final localProducts = await DatabaseHelper.instance.getAllProducts();
      final remoteProducts = await _fetchProductsFromKiosk(ip, port, pin);

      if (remoteProducts == null) {
        print('Failed to fetch remote products, aborting sync');
        return false;
      }

      List<Product> toPush = [];
      List<Product> toPull = [];

      final localMap = {for (var p in localProducts) p.barcode: p};
      final remoteMap = {for (var p in remoteProducts) p.barcode: p};

      // Check Local against Remote
      for (var local in localProducts) {
        final remote = remoteMap[local.barcode];
        if (remote == null) {
          // New in Local -> Push
          toPush.add(local);
        } else if (local.lastUpdated > remote.lastUpdated) {
          // Local newer -> Push
          toPush.add(local);
        } else if (remote.lastUpdated > local.lastUpdated) {
          // Remote newer -> Pull
          toPull.add(remote);
        }
      }

      // Check Remote against Local (for new items in Remote)
      for (var remote in remoteProducts) {
        if (!localMap.containsKey(remote.barcode)) {
          // New in Remote -> Pull
          toPull.add(remote);
        }
      }

      bool pushSuccess = true;
      if (toPush.isNotEmpty) {
        pushSuccess = await _pushProductsToKiosk(ip, port, pin, toPush);
      }

      if (toPull.isNotEmpty) {
        for (var p in toPull) {
          await DatabaseHelper.instance.upsertProduct(p);
        }
      }

      return pushSuccess;

    } catch (e) {
      print('Bidirectional Sync failed: $e');
      return false;
    }
  }

  Future<List<Product>?> _fetchProductsFromKiosk(String ip, int port, String pin) async {
    try {
      final response = await http.get(
        Uri.parse('http://$ip:$port/sync/products'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $pin',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching products from kiosk: $e');
    }
    return null;
  }

  Future<bool> _pushProductsToKiosk(String ip, int port, String pin, List<Product> products) async {
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
  }
}
