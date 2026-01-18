import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:manager/services/kiosk_client/kiosk_client.dart';
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
      setState(() {
        _isSyncing = false;
        _statusMessage = success ? 'Sync Successful!' : 'Sync Failed!';
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kiosk Synced Successfully')),
        );
        Navigator.pop(context);
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
