import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kiosk/services/api_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PaymentScreen extends StatefulWidget {
  final double totalAmount;
  final VoidCallback onPaymentConfirmed;

  const PaymentScreen({
    super.key,
    required this.totalAmount,
    required this.onPaymentConfirmed,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final ApiService _apiService = ApiService();
  String? _qrData;
  bool _isLoading = true;
  int _adminTapCount = 0;

  @override
  void initState() {
    super.initState();
    _loadQrCode();
  }

  Future<void> _loadQrCode() async {
    final qrData = await _apiService.getPaymentQr();
    if (mounted) {
      setState(() {
        _qrData = qrData;
        _isLoading = false;
      });
    }
  }

  void _handleAdminTap() {
    _adminTapCount++;
    if (_adminTapCount >= 5) {
      _adminTapCount = 0;
      _showAdminPinDialog();
    }
  }

  Future<void> _showAdminPinDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController pinController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminConfirm),
        content: TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.enterPin),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              // Hardcoded PIN for now: 1234
              if (pinController.text == '1234') {
                Navigator.pop(context);
                widget.onPaymentConfirmed();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.invalidPin)),
                );
              }
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(l10n.payment),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Total: \$${widget.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_qrData != null)
              GestureDetector(
                onTap: _handleAdminTap,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: Image.memory(
                    base64Decode(_qrData!),
                    width: 300,
                    height: 300,
                  ),
                ),
              )
            else
              Text(
                l10n.failedQr,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 40),
            Text(
              l10n.scanQr,
              style: const TextStyle(color: Colors.grey, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
