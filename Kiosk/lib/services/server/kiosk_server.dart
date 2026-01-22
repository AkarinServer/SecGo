import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:sqflite/sqflite.dart'; // Add this for getDatabasesPath
import 'package:path/path.dart'; // Add this for join
import 'package:kiosk/db/database_helper.dart';
import 'package:kiosk/models/product.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'package:kiosk/services/settings_service.dart';

class KioskServerService {
  KioskServerService({this.onRestoreComplete});

  HttpServer? _server;
  String? _pin;
  String? _ipAddress;
  int _port = 8081;
  String? _deviceId;
  final SettingsService _settingsService = SettingsService();
  final VoidCallback? onRestoreComplete;

  String? get ipAddress => _ipAddress;
  int get port => _port;

  Future<void> startServer(String pin, {String? deviceId}) async {
    _pin = pin;
    _deviceId = deviceId;
    
    // Iterate interfaces to find a valid non-loopback IPv4 address
    // Priority: Hotspot (ap0, tethering) -> Wi-Fi (wlan0) -> Exclude LTE (rmnet)
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false, 
        type: InternetAddressType.IPv4,
      );

      NetworkInterface? selectedInterface;

      // 1. Prioritize Hotspot/Tethering interface (ap, tether, wlan1 usually)
      try {
        selectedInterface = interfaces.firstWhere(
          (i) => i.name.toLowerCase().contains('ap') || 
                 i.name.toLowerCase().contains('tether')
        );
      } catch (_) {}

      // 2. If no Hotspot, try to find Wi-Fi interface (wlan)
      if (selectedInterface == null) {
        try {
          selectedInterface = interfaces.firstWhere((i) => i.name.toLowerCase().contains('wlan'));
        } catch (_) {}
      }

      // 3. If still nothing, look for any interface that IS NOT mobile data (rmnet, ccmni, pdp)
      if (selectedInterface == null) {
        try {
          selectedInterface = interfaces.firstWhere(
            (i) => !i.name.toLowerCase().contains('rmnet') && 
                   !i.name.toLowerCase().contains('ccmni') &&
                   !i.name.toLowerCase().contains('pdp')
          );
        } catch (_) {}
      }

      if (selectedInterface != null) {
        debugPrint('Selected interface: ${selectedInterface.name}');
        for (var addr in selectedInterface.addresses) {
           if (!addr.isLoopback) {
             _ipAddress = addr.address;
             break;
           }
        }
      }
    } catch (e) {
      debugPrint('Error listing network interfaces: $e');
    }
    
    // Fallback to NetworkInfo if manual lookup fails (though manual is more robust for Hotspot/LTE)
    if (_ipAddress == null) {
      final info = NetworkInfo();
      _ipAddress = await info.getWifiIP();
    }
    
    if (_ipAddress == null) {
      debugPrint('Could not get IP address. Server not started.');
      return;
    }

    final router = Router();

    // Middleware to verify PIN
    Handler _checkAuth(Handler innerHandler) {
      return (Request request) {
        final authHeader = request.headers['Authorization'];
        if (authHeader != 'Bearer $_pin') {
          return Response.forbidden('Invalid PIN');
        }
        return innerHandler(request);
      };
    }

    // Endpoint: Get Status
    router.get('/status', (Request request) {
      return Response.ok(jsonEncode({
        'status': 'online',
        'device': 'kiosk',
        'device_id': _deviceId,
      }));
    });

    // Endpoint: Sync Products (Push from Manager)
    router.post('/sync/products', (Request request) async {
      try {
        final payload = await request.readAsString();
        final List<dynamic> productsJson = jsonDecode(payload);
        
        for (var p in productsJson) {
          await DatabaseHelper.instance.upsertProduct(Product.fromJson(p));
        }
        
        return Response.ok(jsonEncode({'message': 'Synced ${productsJson.length} products'}));
      } catch (e) {
        return Response.internalServerError(body: 'Sync failed: $e');
      }
    });

    // Endpoint: Get Products (Pull from Kiosk)
    router.get('/sync/products', (Request request) async {
      try {
        final products = await DatabaseHelper.instance.getAllProducts();
        final productsJson = jsonEncode(products.map((p) => p.toJson()).toList());
        return Response.ok(productsJson, headers: {'Content-Type': 'application/json'});
      } catch (e) {
        return Response.internalServerError(body: 'Failed to fetch products: $e');
      }
    });

    // Endpoint: Get Orders (Pull to Manager)
    router.get('/orders', (Request request) async {
      try {
        final orders = await DatabaseHelper.instance.getAllOrders();
        final ordersJson = jsonEncode(orders.map((o) => o.toJson()).toList());
        return Response.ok(ordersJson, headers: {'Content-Type': 'application/json'});
      } catch (e) {
        return Response.internalServerError(body: 'Failed to fetch orders: $e');
      }
    });

    // Endpoint: Upload Payment QR (Push from Manager)
    router.post('/payment_qr', (Request request) async {
      try {
        final payload = await request.readAsString();
        final Map<String, dynamic> data = jsonDecode(payload);
        if (data.containsKey('data')) {
          await _settingsService.setPaymentQr(data['data']);
          return Response.ok(jsonEncode({'message': 'Payment QR updated'}));
        } else {
          return Response.badRequest(body: 'Missing "data" field');
        }
      } catch (e) {
        return Response.internalServerError(body: 'Failed to update QR: $e');
      }
    });

    // Endpoint: Get Backup (Download DB)
    router.get('/backup', (Request request) async {
      try {
        final dbPath = await getDatabasesPath();
        final path = join(dbPath, 'kiosk.db');
        final file = File(path);
        if (await file.exists()) {
           return Response.ok(
             file.openRead(), 
             headers: {
               'Content-Type': 'application/x-sqlite3',
               'Content-Disposition': 'attachment; filename="kiosk.db"'
             }
           );
        } else {
          return Response.notFound('Database file not found');
        }
      } catch (e) {
        return Response.internalServerError(body: 'Backup failed: $e');
      }
    });

    // Endpoint: Restore Backup (Upload DB)
    router.post('/restore', (Request request) async {
      try {
        // Read file bytes from request body
        final bytes = await request.read().expand((element) => element).toList();
        
        if (bytes.isEmpty) {
          return Response.badRequest(body: 'Empty backup file');
        }

        final dbPath = await getDatabasesPath();
        final tempPath = join(dbPath, 'temp_restore.db');
        final tempFile = File(tempPath);
        await tempFile.writeAsBytes(bytes);

        // Perform merge logic: Replace products, keep orders
        await DatabaseHelper.instance.restoreProductsFromBackup(tempPath);

        // Cleanup
        if (await tempFile.exists()) {
          await tempFile.delete();
        }

        onRestoreComplete?.call();
        return Response.ok(jsonEncode({'message': 'Restore successful'}));
      } catch (e) {
        return Response.internalServerError(body: 'Restore failed: $e');
      }
    });

    final handler = Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(_checkAuth)
        .addHandler(router.call);

    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, _port);
    debugPrint('Kiosk Server running at http://$_ipAddress:$_port');
  }

  Future<void> stopServer() async {
    await _server?.close();
    _server = null;
  }
}
