import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:manager/services/kiosk_client/kiosk_client.dart';
import 'package:manager/db/database_helper.dart';
import 'package:manager/models/kiosk.dart';
import 'package:manager/l10n/app_localizations.dart';
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
          _pairWithKiosk(data['ip'], data['port'], data['pin']);
        }
      } catch (e) {
        // Not a valid JSON or Kiosk QR
      }
    }
  }

  Future<void> _pairWithKiosk(String ip, int port, String pin) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isSyncing = true;
      _statusMessage = l10n.pairingKiosk(ip);
    });

    final fetchedDeviceId = await _kioskService.fetchDeviceId(ip, port, pin);
    final success = fetchedDeviceId != null;

    if (mounted) {
      if (success) {
        // Keep _isSyncing true to prevent further scans
        
        // Save Kiosk to DB
        await DatabaseHelper.instance.insertKiosk(Kiosk(
          ip: ip,
          port: port,
          pin: pin,
          lastSynced: DateTime.now().millisecondsSinceEpoch,
          deviceId: fetchedDeviceId,
        ));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.pairSuccess)),
        );
        Navigator.pop(context);
      } else {
        setState(() {
          _isSyncing = false;
          _statusMessage = l10n.pairFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pairKioskTitle)),
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
                        Text(_statusMessage ?? l10n.scanBarcode),
                      ],
                    )
                  : Text(l10n.scanKioskHint),
            ),
          ),
        ],
      ),
    );
  }
}
