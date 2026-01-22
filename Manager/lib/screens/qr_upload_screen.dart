import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:manager/db/database_helper.dart';
import 'package:manager/services/kiosk_client/kiosk_client.dart';
import 'package:manager/l10n/app_localizations.dart';

class QrUploadScreen extends StatefulWidget {
  const QrUploadScreen({super.key});

  @override
  State<QrUploadScreen> createState() => _QrUploadScreenState();
}

class _QrUploadScreenState extends State<QrUploadScreen> {
  final KioskClientService _kioskService = KioskClientService();
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool _isUploading = false;

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

    setState(() => _isUploading = true);
    try {
      final bytes = await _image!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final kiosks = await DatabaseHelper.instance.getAllKiosks();
      if (kiosks.isEmpty) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.noKiosksPaired)),
          );
        }
        setState(() => _isUploading = false);
        return;
      }

      int successCount = 0;
      for (final kiosk in kiosks) {
        final success = await _kioskService.uploadPaymentQr(
          kiosk.ip, 
          kiosk.port, 
          kiosk.pin, 
          base64Image
        );
        if (success) successCount++;
      }

      setState(() => _isUploading = false);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.uploadedToKiosks(successCount))),
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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.uploadQr)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_image != null)
              Image.file(_image!, height: 300)
            else
              const Icon(Icons.qr_code, size: 100, color: Colors.grey),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: Text(l10n.selectImage),
            ),
            const SizedBox(height: 20),
            if (_isUploading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _image != null ? _uploadImage : null,
                child: Text(l10n.uploadToServer),
              ),
          ],
        ),
      ),
    );
  }
}
