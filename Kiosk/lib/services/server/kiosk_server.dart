import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:kiosk/db/database_helper.dart';
import 'package:kiosk/models/product.dart';
import 'package:network_info_plus/network_info_plus.dart';

class KioskServerService {
  HttpServer? _server;
  String? _pin;
  String? _ipAddress;
  int _port = 8081;

  String? get ipAddress => _ipAddress;
  int get port => _port;

  Future<void> startServer(String pin) async {
    _pin = pin;
    
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
      return Response.ok(jsonEncode({'status': 'online', 'device': 'kiosk'}));
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
    // TODO: Implement order fetching logic

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
