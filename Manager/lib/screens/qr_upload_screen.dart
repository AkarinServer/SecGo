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
  File? _image;
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

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;
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
      final bytes = await _image!.readAsBytes();
      final base64Image = base64Encode(bytes);
      final success = await _kioskService.uploadPaymentQr(
        connectedKiosk.ip,
        connectedKiosk.port,
        connectedKiosk.pin,
        base64Image,
      );

      setState(() => _isUploading = false);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.uploadedToKiosks(1))),
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
    final canUpload = isConnected && _image != null && !_isUploading;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.uploadQr)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isConnected)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  l10n.connectKioskToUpload,
                  textAlign: TextAlign.center,
                ),
              ),
            if (_image != null)
              Image.file(_image!, height: 300)
            else
              const Icon(Icons.qr_code, size: 100, color: Colors.grey),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: isConnected ? _pickImage : null,
              icon: const Icon(Icons.image),
              label: Text(l10n.selectImage),
            ),
            const SizedBox(height: 20),
            if (_isUploading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: canUpload ? _uploadImage : null,
                child: Text(l10n.uploadToServer),
              ),
          ],
        ),
      ),
    );
  }
}
