import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:manager/models/product.dart';
import 'package:manager/models/order.dart';
import 'package:manager/db/database_helper.dart';

class KioskClientService {
  final http.Client _client;

  KioskClientService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<String>> getCandidateKioskIps() async {
    final info = NetworkInfo();
    final candidates = <String>{};
    final gateway = await info.getWifiGatewayIP();
    if (gateway != null && gateway.isNotEmpty) {
      candidates.add(gateway);
    }
    final wifiIp = await info.getWifiIP();
    if (wifiIp != null && wifiIp.isNotEmpty) {
      final parts = wifiIp.split('.');
      if (parts.length == 4) {
        candidates.add('${parts[0]}.${parts[1]}.${parts[2]}.1');
      }
    }
    return candidates.toList();
  }

  Future<String?> fetchDeviceId(String ip, int port, String pin) async {
    try {
      final response = await _client
          .get(
            Uri.parse('http://$ip:$port/status'),
            headers: {
              'Authorization': 'Bearer $pin',
            },
          )
          .timeout(const Duration(seconds: 1));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['device_id'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> syncProductsToKiosk(String ip, int port, String pin) async {
    return await bidirectionalSync(ip, port, pin);
  }

  Future<bool> pushProductsToKiosk(
    String ip,
    int port,
    String pin,
    List<Product> products,
  ) async {
    if (products.isEmpty) return true;
    return _pushProductsToKiosk(ip, port, pin, products);
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
      final response = await _client.get(
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

      final response = await _client.post(
        Uri.parse('http://$ip:$port/sync/products'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $pin',
        },
        body: productsJson,
      );

      return response.statusCode == 200;
  }

  Future<bool> uploadPaymentQr(String ip, int port, String pin, String base64Image) async {
    try {
      final response = await _client.post(
        Uri.parse('http://$ip:$port/payment_qr'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $pin',
        },
        body: jsonEncode({'data': base64Image}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error uploading QR to kiosk: $e');
      return false;
    }
  }

  Future<List<Order>?> fetchOrders(String ip, int port, String pin) async {
    try {
      final response = await _client.get(
        Uri.parse('http://$ip:$port/orders'),
        headers: {
          'Authorization': 'Bearer $pin',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Order.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching orders from kiosk: $e');
    }
    return null;
  }

  Future<bool> downloadBackup(String ip, int port, String pin, String savePath) async {
    try {
      final response = await _client.get(
        Uri.parse('http://$ip:$port/backup'),
        headers: {
          'Authorization': 'Bearer $pin',
        },
      );

      if (response.statusCode == 200) {
        final file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);
        return true;
      }
    } catch (e) {
      print('Error downloading backup: $e');
    }
    return false;
  }

  Future<bool> restoreBackup(String ip, int port, String pin, File dbFile) async {
    try {
      final bytes = await dbFile.readAsBytes();
      final response = await _client.post(
        Uri.parse('http://$ip:$port/restore'),
        headers: {
          'Authorization': 'Bearer $pin',
          'Content-Type': 'application/x-sqlite3',
        },
        body: bytes,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error restoring backup: $e');
      return false;
    }
  }
}
