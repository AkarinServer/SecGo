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

  Future<void> _onQrDetect(BarcodeCapture capture) async {
    if (_isSyncing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String code = barcodes.first.rawValue!;
      try {
        final Map<String, dynamic> data = jsonDecode(code);
        if (data.containsKey('ip') && data.containsKey('port')) {
          final ip = data['ip'] as String;
          final port = data['port'] as int;
          final deviceId = data['deviceId'] as String?;
          setState(() {
            _isSyncing = true;
            _statusMessage = AppLocalizations.of(context)!.enterPinPrompt;
          });
          final storedPin = await _findStoredPin(ip, deviceId);
          final pin = storedPin ?? await _promptForPin();
          if (!mounted) return;
          if (pin == null) {
            setState(() {
              _isSyncing = false;
              _statusMessage = null;
            });
            return;
          }
          await _pairWithKiosk(ip, port, pin);
        }
      } catch (e) {
        // Not a valid JSON or Kiosk QR
        if (mounted) {
          setState(() {
            _isSyncing = false;
            _statusMessage = null;
          });
        }
      }
    }
  }

  Future<String?> _findStoredPin(String ip, String? deviceId) async {
    final kiosks = await DatabaseHelper.instance.getAllKiosks();
    for (final kiosk in kiosks) {
      if (deviceId != null && kiosk.deviceId == deviceId) return kiosk.pin;
      if (kiosk.ip == ip) return kiosk.pin;
    }
    return null;
  }

  Future<String?> _promptForPin() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    String? errorText;
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.enterPinTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: l10n.enterPinHint,
              errorText: errorText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                final pin = controller.text.trim();
                if (pin.length < 4) {
                  setState(() => errorText = l10n.pinLength);
                  return;
                }
                Navigator.pop(context, pin);
              },
              child: Text(l10n.confirm),
            ),
          ],
        ),
      ),
    );
    return result;
  }

  Future<void> _pairWithKiosk(String ip, int port, String pin) async {
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isSyncing = true;
      _statusMessage = l10n.pairingKiosk(ip);
    });

    final fetchedDeviceId = await _kioskService.fetchDeviceId(ip, port, pin);
    final success = fetchedDeviceId != null;

    if (!mounted) return;
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
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(content: Text(l10n.pairSuccess)),
      );
      navigator.pop();
    } else {
      setState(() {
        _isSyncing = false;
        _statusMessage = l10n.pairFailed;
      });
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
