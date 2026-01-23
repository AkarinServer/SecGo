import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kiosk/services/alipay_payment_watch_service.dart';
import 'package:kiosk/services/android_notification_listener_service.dart';
import 'package:kiosk/services/settings_service.dart';
// import 'package:qr_flutter/qr_flutter.dart';
import 'package:kiosk/l10n/app_localizations.dart';

class PaymentScreen extends StatefulWidget {
  final double totalAmount;
  final String orderId;
  final int checkoutTimeMs;
  final List<String> baselineKeys;
  final bool autoConfirmEnabled;
  final VoidCallback onPaymentConfirmed;

  const PaymentScreen({
    super.key,
    required this.totalAmount,
    required this.orderId,
    required this.checkoutTimeMs,
    required this.baselineKeys,
    required this.autoConfirmEnabled,
    required this.onPaymentConfirmed,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final SettingsService _settingsService = SettingsService();
  final PaymentNotificationWatchService _watchService = PaymentNotificationWatchService();
  final AndroidNotificationListenerService _notificationListenerService =
      AndroidNotificationListenerService();
  String? _qrData;
  bool _isLoading = true;
  int _adminTapCount = 0;
  bool _autoConfirmStarted = false;

  @override
  void initState() {
    super.initState();
    _loadQrCode();
    _startAutoConfirm();
  }

  Future<void> _startAutoConfirm() async {
    if (_autoConfirmStarted) return;
    _autoConfirmStarted = true;
    final enabled = await _notificationListenerService.isEnabled();
    if (!enabled) return;
    final baseline = widget.baselineKeys.toSet();
    final alipaySnapshot = await _notificationListenerService.getActiveAlipayNotificationsSnapshot();
    for (final n in alipaySnapshot) {
      final key = n['key'];
      final postTime = n['postTime'];
      final packageName = n['package'];
      if (packageName is! String || packageName.isEmpty) continue;
      if (key is! String || key.isEmpty) continue;
      if (postTime is int && postTime <= widget.checkoutTimeMs) {
        baseline.add('$packageName|$key');
      }
    }
    final wechatSnapshot = await _notificationListenerService.getActiveWechatNotificationsSnapshot();
    for (final n in wechatSnapshot) {
      final key = n['key'];
      final postTime = n['postTime'];
      final packageName = n['package'];
      if (packageName is! String || packageName.isEmpty) continue;
      if (key is! String || key.isEmpty) continue;
      if (postTime is int && postTime <= widget.checkoutTimeMs) {
        baseline.add('$packageName|$key');
      }
    }
    debugPrint(
      'PaymentScreen autoConfirm start orderId=${widget.orderId} amount=${widget.totalAmount} checkoutTimeMs=${widget.checkoutTimeMs} baselineKeys=${widget.baselineKeys.length}',
    );

    await _watchService.start(
      orderId: widget.orderId,
      orderAmount: widget.totalAmount,
      checkoutTimeMs: widget.checkoutTimeMs,
      baselineKeys: baseline,
      onMatched: () {
        if (!mounted) return;
        widget.onPaymentConfirmed();
      },
      onMismatch: (message) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Amount mismatch, still waiting for payment...')),
        );
      },
      onTimeout: () async {
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Payment timeout'),
              content: const Text('Auto confirmation timed out. Manual/admin handling required.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _watchService.stop();
    super.dispose();
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
          ],
        ),
      ),
    );
  }
}
