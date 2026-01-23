import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:manager/services/kiosk_client/kiosk_client.dart';
import 'package:manager/l10n/app_localizations.dart';
import 'package:manager/services/kiosk_connection_service.dart';

class QrUploadScreen extends StatefulWidget {
  const QrUploadScreen({super.key});

  @override
  State<QrUploadScreen> createState() => _QrUploadScreenState();
}

class _QrUploadScreenState extends State<QrUploadScreen> {
  final KioskClientService _kioskService = KioskClientService();
  final KioskConnectionService _connectionService = KioskConnectionService();
  final ImagePicker _picker = ImagePicker();
  final Map<String, File> _imagesByProvider = {};
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _connectionService.addListener(_onConnectionChange);
  }

  @override
  void dispose() {
    _connectionService.removeListener(_onConnectionChange);
    super.dispose();
  }

  void _onConnectionChange() {
    if (mounted) setState(() {});
  }

  Future<File?> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  Future<String?> _promptCustomProvider() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    String? errorText;
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.customPaymentMethodTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.customPaymentMethodHint,
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
                final v = controller.text.trim().toLowerCase();
                if (v.isEmpty) {
                  setState(() => errorText = l10n.customPaymentMethodInvalid);
                  return;
                }
                Navigator.pop(context, v);
              },
              child: Text(l10n.confirm),
            ),
          ],
        ),
      ),
    );
    return result;
  }

  Future<void> _addProviderImage(String provider) async {
    if (!_connectionService.hasConnectedKiosk) return;
    final file = await _pickImage();
    if (file == null) return;
    if (!mounted) return;
    setState(() => _imagesByProvider[provider] = file);
  }

  Future<void> _addCustomProviderImage() async {
    if (!_connectionService.hasConnectedKiosk) return;
    final provider = await _promptCustomProvider();
    if (!mounted) return;
    if (provider == null || provider.isEmpty) return;
    await _addProviderImage(provider);
  }

  Future<void> _uploadImages() async {
    if (_imagesByProvider.isEmpty) return;
    final connectedKiosk = _connectionService.connectedKiosk;
    if (connectedKiosk == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.kioskNotConnected)),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      final payload = <String, String>{};
      for (final entry in _imagesByProvider.entries) {
        final bytes = await entry.value.readAsBytes();
        payload[entry.key] = base64Encode(bytes);
      }
      final success = await _kioskService.uploadPaymentQrs(
        connectedKiosk.ip,
        connectedKiosk.port,
        connectedKiosk.pin,
        payload,
      );

      setState(() => _isUploading = false);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.uploadedPaymentQrs(_imagesByProvider.length))),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorUpload)),
          );
        }
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isConnected = _connectionService.hasConnectedKiosk;
    final canUpload = isConnected && _imagesByProvider.isNotEmpty && !_isUploading;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.uploadQr)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (!isConnected)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    l10n.connectKioskToUpload,
                    textAlign: TextAlign.center,
                  ),
                ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: isConnected ? () => _addProviderImage('alipay') : null,
                    child: Text(l10n.addAlipayQr),
                  ),
                  ElevatedButton(
                    onPressed: isConnected ? () => _addProviderImage('wechat') : null,
                    child: Text(l10n.addWechatQr),
                  ),
                  ElevatedButton(
                    onPressed: isConnected ? _addCustomProviderImage : null,
                    child: Text(l10n.addCustomQr),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _imagesByProvider.isEmpty
                    ? const Center(
                        child: Icon(Icons.qr_code, size: 100, color: Colors.grey),
                      )
                    : ListView(
                        children: _imagesByProvider.entries.map((e) {
                          final label = e.key == 'alipay'
                              ? l10n.paymentMethodAlipay
                              : e.key == 'wechat'
                                  ? l10n.paymentMethodWechat
                                  : e.key;
                          return Card(
                            child: ListTile(
                              title: Text(label),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Image.file(e.value, height: 140),
                              ),
                              trailing: IconButton(
                                tooltip: l10n.remove,
                                icon: const Icon(Icons.close),
                                onPressed: _isUploading
                                    ? null
                                    : () {
                                        setState(() => _imagesByProvider.remove(e.key));
                                      },
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 12),
              if (_isUploading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: CircularProgressIndicator(),
                ),
              ElevatedButton(
                onPressed: canUpload ? _uploadImages : null,
                child: Text(l10n.uploadToServer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
