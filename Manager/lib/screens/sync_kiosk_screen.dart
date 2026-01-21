import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:manager/services/kiosk_client/kiosk_client.dart';
import 'package:manager/db/database_helper.dart';
import 'package:manager/models/kiosk.dart';
import 'dart:convert';

class SyncKioskScreen extends StatefulWidget {
  const SyncKioskScreen({super.key});

  @override
  State<SyncKioskScreen> createState() => _SyncKioskScreenState();
}

class _SyncKioskScreenState extends State<SyncKioskScreen> {
  final KioskClientService _kioskService = KioskClientService();
  bool _isSyncing = false;
  String? _statusMessage;

  void _onQrDetect(BarcodeCapture capture) {
    if (_isSyncing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String code = barcodes.first.rawValue!;
      try {
        final Map<String, dynamic> data = jsonDecode(code);
        if (data.containsKey('ip') && data.containsKey('port') && data.containsKey('pin')) {
          _syncWithKiosk(data['ip'], data['port'], data['pin']);
        }
      } catch (e) {
        // Not a valid JSON or Kiosk QR
      }
    }
  }

  Future<void> _syncWithKiosk(String ip, int port, String pin) async {
    setState(() {
      _isSyncing = true;
      _statusMessage = 'Syncing with Kiosk at $ip...';
    });

    final success = await _kioskService.syncProductsToKiosk(ip, port, pin);

    if (mounted) {
      if (success) {
        // Keep _isSyncing true to prevent further scans
        
        // Save Kiosk to DB
        await DatabaseHelper.instance.insertKiosk(Kiosk(
          ip: ip,
          port: port,
          pin: pin,
          name: 'Kiosk $ip', // Default name
          lastSynced: DateTime.now().millisecondsSinceEpoch,
        ));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kiosk Synced & Paired Successfully')),
        );
        Navigator.pop(context);
      } else {
        setState(() {
          _isSyncing = false;
          _statusMessage = 'Sync Failed!';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Kiosk QR to Sync')),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: MobileScanner(
              onDetect: _onQrDetect,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: _isSyncing
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 20),
                        Text(_statusMessage ?? 'Scanning...'),
                      ],
                    )
                  : const Text('Scan the QR code on the Kiosk Settings screen'),
            ),
          ),
        ],
      ),
    );
  }
}
