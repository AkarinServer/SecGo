import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kiosk/services/server/kiosk_server.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:kiosk/l10n/app_localizations.dart';
import 'package:kiosk/screens/main_screen.dart';

import 'package:kiosk/services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final KioskServerService _serverService;
  final TextEditingController _pinController = TextEditingController();
  final SettingsService _settingsService = SettingsService(); // Add SettingsService
  bool _isServerRunning = false;
  bool _isLoading = false;
  bool _showRestoreComplete = false;
  String? _qrData;

  @override
  void initState() {
    super.initState();
    _serverService = KioskServerService(onRestoreComplete: _onRestoreComplete);
    // Pre-fill PIN if available
    final savedPin = _settingsService.getPin();
    if (savedPin != null) {
      _pinController.text = savedPin;
      // Auto-start server if PIN is available
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startServer();
      });
    }
  }

  @override
  void dispose() {
    _serverService.stopServer();
    super.dispose();
  }

  void _onRestoreComplete() {
    if (_showRestoreComplete) return;
    _runRestoreCompleteFlow();
  }

  Future<void> _runRestoreCompleteFlow() async {
    if (!mounted) return;
    setState(() => _showRestoreComplete = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );
  }

  Future<void> _startServer() async {
    final l10n = AppLocalizations.of(context)!;
    if (_pinController.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pinLength)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final deviceId = await _settingsService.getOrCreateDeviceId();
    await _serverService.startServer(_pinController.text, deviceId: deviceId);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (_serverService.ipAddress != null) {
          _isServerRunning = true;
          // QR Data format: {"ip": "192.168.x.x", "port": 8081, "pin": "1234"}
          _qrData = jsonEncode({
            'ip': _serverService.ipAddress,
            'port': _serverService.port,
            'pin': _pinController.text,
            'deviceId': deviceId,
          });
        } else {
           // Optional: Show error if IP is null (e.g. no wifi)
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.serverNoIp)),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.kioskSettings)),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: _isLoading 
                ? const CircularProgressIndicator() 
                : _isServerRunning
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.kioskReadyToSync,
                          style: TextStyle(fontSize: 24, color: Colors.green),
                        ),
                        const SizedBox(height: 20),
                        if (_qrData != null)
                          Container(
                            color: Colors.white,
                            padding: const EdgeInsets.all(16),
                            child: QrImageView(
                              data: _qrData!,
                              size: 250,
                            ),
                          ),
                        const SizedBox(height: 20),
                        Text(
                          l10n.ipAddressLabel(
                            _serverService.ipAddress ?? '-',
                            _serverService.port,
                          ),
                        ),
                        const SizedBox(height: 40),
                        ElevatedButton(
                          onPressed: () {
                            // Restart server logic or close page
                            Navigator.pop(context);
                          },
                          child: Text(l10n.close),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.red),
                        const SizedBox(height: 20),
                        Text(
                          l10n.serverStartFailedTitle,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.serverStartFailedMessage,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: _startServer,
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
            ),
          ),
          if (_showRestoreComplete)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.65),
                child: Center(
                  child: AnimatedScale(
                    scale: _showRestoreComplete ? 1 : 0.9,
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 96),
                        const SizedBox(height: 16),
                        Text(
                          l10n.restoreComplete,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.returningHome,
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
