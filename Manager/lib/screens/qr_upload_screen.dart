import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:manager/services/api_service.dart';
import 'package:manager/l10n/app_localizations.dart';

class QrUploadScreen extends StatefulWidget {
  const QrUploadScreen({super.key});

  @override
  State<QrUploadScreen> createState() => _QrUploadScreenState();
}

class _QrUploadScreenState extends State<QrUploadScreen> {
  final ApiService _apiService = ApiService();
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
    final bytes = await _image!.readAsBytes();
    final base64Image = base64Encode(bytes);

    final success = await _apiService.uploadPaymentQr(base64Image);
    setState(() => _isUploading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.successUpload)),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorUpload)),
      );
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
