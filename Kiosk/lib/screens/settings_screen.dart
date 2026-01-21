import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kiosk/services/server/kiosk_server.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:kiosk/l10n/app_localizations.dart';

import 'package:kiosk/services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final KioskServerService _serverService = KioskServerService();
  final TextEditingController _pinController = TextEditingController();
  final SettingsService _settingsService = SettingsService(); // Add SettingsService
  bool _isServerRunning = false;
  bool _isLoading = false;
  String? _qrData;

  @override
  void initState() {
    super.initState();
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

  Future<void> _startServer() async {
    if (_pinController.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN must be at least 4 digits')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await _serverService.startServer(_pinController.text);
    
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
          });
        } else {
           // Optional: Show error if IP is null (e.g. no wifi)
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to start server: No IP address found')),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kiosk Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: _isLoading 
            ? const CircularProgressIndicator() 
            : _isServerRunning
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Kiosk is Ready to Sync',
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
                    Text('IP: ${_serverService.ipAddress}:${_serverService.port}'),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () {
                        // Restart server logic or close page
                        Navigator.pop(context);
                      },
                      child: const Text('Close'),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: Colors.red),
                    const SizedBox(height: 20),
                    const Text(
                      'Failed to Start Server',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Could not find a valid IP address.\nPlease check your Wi-Fi, Hotspot, or Mobile Data connection.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _startServer,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
