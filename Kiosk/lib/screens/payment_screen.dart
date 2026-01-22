import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kiosk/services/settings_service.dart';
// import 'package:qr_flutter/qr_flutter.dart';
import 'package:kiosk/l10n/app_localizations.dart';
import 'package:kiosk/services/audio_payment_service.dart';

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
  final SettingsService _settingsService = SettingsService();
  final AudioPaymentService _audioService = AudioPaymentService();
  StreamSubscription<double>? _paymentSubscription;
  StreamSubscription<String>? _logSubscription;
  String _debugLog = '';
  String? _qrData;
  bool _isLoading = true;
  int _adminTapCount = 0;

  @override
  void initState() {
    super.initState();
    _loadQrCode();
    _initAudioPayment();
  }

  Future<void> _initAudioPayment() async {
    _logSubscription?.cancel();
    _logSubscription = _audioService.logStream.listen((line) {
      if (!mounted) return;
      setState(() {
        _debugLog = '$line\n$_debugLog';
        final lines = _debugLog.split('\n');
        if (lines.length > 12) {
          _debugLog = lines.take(12).join('\n');
        }
      });
    });

    await _audioService.init();
    if (!mounted) return;
    await _audioService.startListening();

    _paymentSubscription?.cancel();
    _paymentSubscription = _audioService.amountStream.listen((amount) {
      if (!mounted) return;
      final total = widget.totalAmount;
      final diff = (amount - total).abs();
      final strict = diff < 0.01;
      final hasCents = ((total * 100).round() % 100) != 0;
      final vague =
          !hasCents && (amount.roundToDouble() == total.roundToDouble()) && diff < 0.6;

      if (strict || vague) {
        _handlePaymentSuccess(amount);
      }
    });
  }

  Future<void> _loadQrCode() async {
    final qrData = _settingsService.getPaymentQr();
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

  void _handlePaymentSuccess(double amount) {
    _paymentSubscription?.cancel();
    _audioService.stopListening();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment Verified: ¥$amount'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );

    widget.onPaymentConfirmed();
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
  void dispose() {
    _paymentSubscription?.cancel();
    _logSubscription?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '¥');
    
    return Scaffold(
      // backgroundColor: Colors.black, // Use theme
      appBar: AppBar(
        title: Text(l10n.payment),
        // backgroundColor: Colors.black, // Use theme
        // foregroundColor: Colors.white, // Use theme
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.totalWithAmount(currencyFormat.format(widget.totalAmount)),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
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
                  decoration: BoxDecoration(
                    color: Colors.white, // QR codes need white background
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                style: TextStyle(color: theme.colorScheme.error),
              ),
            const SizedBox(height: 40),
            Text(
              l10n.scanQr,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 360,
              height: 140,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _debugLog,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
