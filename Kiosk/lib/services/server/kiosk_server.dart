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
    final info = NetworkInfo();
    _ipAddress = await info.getWifiIP();
    
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
