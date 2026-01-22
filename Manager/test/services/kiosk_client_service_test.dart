import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manager/services/kiosk_client/kiosk_client.dart';

void main() {
  group('KioskClientService', () {
    const ip = '192.168.1.100';
    const port = 8081;
    const pin = '1234';

    test('fetchOrders returns list of orders on 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), 'http://$ip:$port/orders');
        expect(request.headers['Authorization'], 'Bearer $pin');
        
        return http.Response(jsonEncode([
          {
            'id': '1',
            'items': [
              {'barcode': '123', 'name': 'Soda', 'price': 1.5, 'quantity': 1}
            ],
            'total_amount': 1.5,
            'timestamp': 1000,
            'synced': true
          }
        ]), 200);
      });

      final service = KioskClientService(client: mockClient);
      final orders = await service.fetchOrders(ip, port, pin);

      expect(orders, isNotNull);
      expect(orders!.length, 1);
      expect(orders.first.id, '1');
      expect(orders.first.totalAmount, 1.5);
    });

    test('uploadPaymentQr sends POST request', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(), 'http://$ip:$port/payment_qr');
        expect(jsonDecode(request.body)['data'], 'base64_string');
        return http.Response('', 200);
      });

      final service = KioskClientService(client: mockClient);
      final result = await service.uploadPaymentQr(ip, port, pin, 'base64_string');

      expect(result, true);
    });

    test('downloadBackup writes file on success', () async {
      // Create a temporary file for testing
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/test_backup.db');

      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), 'http://$ip:$port/backup');
        return http.Response.bytes([1, 2, 3, 4], 200);
      });

      final service = KioskClientService(client: mockClient);
      final result = await service.downloadBackup(ip, port, pin, tempFile.path);

      expect(result.success, true);
      expect(tempFile.existsSync(), true);
      expect(await tempFile.readAsBytes(), [1, 2, 3, 4]);

      // Cleanup
      tempDir.deleteSync(recursive: true);
    });

    test('restoreBackup sends file bytes', () async {
      // Create a dummy backup file
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/restore.db');
      await tempFile.writeAsBytes([5, 6, 7, 8]);

      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(), 'http://$ip:$port/restore');
        expect(request.headers['Content-Type'], 'application/x-sqlite3');
        expect(request.bodyBytes, [5, 6, 7, 8]);
        return http.Response('', 200);
      });

      final service = KioskClientService(client: mockClient);
      final result = await service.restoreBackup(ip, port, pin, tempFile);

      expect(result, true);

      // Cleanup
      tempDir.deleteSync(recursive: true);
    });
  });
}
