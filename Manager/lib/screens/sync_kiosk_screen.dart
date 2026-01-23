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
  late final MobileScannerController _scannerController;
  bool _isSyncing = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _onQrDetect(BarcodeCapture capture) async {
    if (_isSyncing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String code = barcodes.first.rawValue!;
      debugPrint('SyncKioskScreen qrDetected len=${code.length}');
      try {
        final Map<String, dynamic> data = jsonDecode(code);
        if (data.containsKey('ip') && data.containsKey('port')) {
          final ip = data['ip']?.toString();
          final portValue = data['port'];
          final port = portValue is int ? portValue : int.tryParse(portValue?.toString() ?? '');
          if (ip == null || ip.isEmpty || port == null) {
            if (mounted) {
              setState(() {
                _isSyncing = false;
                _statusMessage = AppLocalizations.of(context)!.pairFailed;
              });
            }
            return;
          }
          debugPrint('SyncKioskScreen parsed ip=$ip port=$port');
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
        debugPrint('SyncKioskScreen qrDecodeFailed err=$e');
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

    debugPrint('SyncKioskScreen pairingStart ip=$ip port=$port pinLen=${pin.length}');
    final debugResult = await _kioskService.fetchDeviceIdDebug(ip, port, pin);
    final fetchedDeviceId = debugResult.deviceId;
    final success = fetchedDeviceId != null;
    debugPrint(
      'SyncKioskScreen pairingResult success=$success statusCode=${debugResult.statusCode} error=${debugResult.error}',
    );

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
        final err = debugResult.error;
        _statusMessage = err == null || err.isEmpty ? l10n.pairFailed : err;
      });
    }
  }

  Future<void> _manualPair() async {
    if (_isSyncing) return;
    final l10n = AppLocalizations.of(context)!;
    final ipController = TextEditingController();
    final portController = TextEditingController(text: '8081');

    final pin = await _promptForPin();
    if (!mounted) return;
    if (pin == null) return;

    final result = await showDialog<({String ip, int port})>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text(l10n.pairKioskTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ipController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(labelText: l10n.ipLabel),
            ),
            TextField(
              controller: portController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.portLabel),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              final ip = ipController.text.trim();
              final port = int.tryParse(portController.text.trim());
              if (ip.isEmpty || port == null) {
                Navigator.pop(context);
                return;
              }
              Navigator.pop(context, (ip: ip, port: port));
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (result == null) return;
    await _pairWithKiosk(result.ip, result.port, pin);
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
              controller: _scannerController,
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
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(l10n.scanKioskHint),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _manualPair,
                          child: Text(l10n.manualPair),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
