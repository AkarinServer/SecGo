import 'package:flutter/material.dart';
import 'package:manager/services/settings_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = true;
  String _selectedMiddleware = 'open_food_facts';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final url = await _settingsService.getApiUrl();
    final middleware = await _settingsService.getMiddlewareType();
    _urlController.text = url;
    setState(() {
      _selectedMiddleware = middleware;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await _settingsService.setApiUrl(_urlController.text);
    await _settingsService.setMiddlewareType(_selectedMiddleware);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedMiddleware,
                    decoration: const InputDecoration(
                      labelText: 'API Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'open_food_facts',
                        child: Text('Open Food Facts'),
                      ),
                      DropdownMenuItem(
                        value: 'custom',
                        child: Text('Universal Product API'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedMiddleware = value);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'Product API URL',
                      hintText: 'https://barcode100.market.alicloudapi.com/getBarcode?Code=',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveSettings,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
    );
  }
}
