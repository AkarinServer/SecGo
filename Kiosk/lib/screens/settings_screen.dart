import 'package:flutter/material.dart';
import 'package:kiosk/services/server/kiosk_server.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final KioskServerService _serverService = KioskServerService();
  final TextEditingController _pinController = TextEditingController();
  bool _isServerRunning = false;
  String? _qrData;

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

    await _serverService.startServer(_pinController.text);
    if (_serverService.ipAddress != null) {
      setState(() {
        _isServerRunning = true;
        // QR Data format: {"ip": "192.168.x.x", "port": 8081, "pin": "1234"}
        // Note: Including PIN in QR for easier pairing, assuming QR is only shown to trusted manager
        _qrData = jsonEncode({
          'ip': _serverService.ipAddress,
          'port': _serverService.port,
          'pin': _pinController.text,
        });
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
          child: _isServerRunning
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
                        _serverService.stopServer();
                        setState(() => _isServerRunning = false);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Stop Server'),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Setup Kiosk Server',
                      style: TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _pinController,
                      decoration: const InputDecoration(
                        labelText: 'Set Connection PIN',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _startServer,
                      child: const Text('Start Server & Show QR'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
