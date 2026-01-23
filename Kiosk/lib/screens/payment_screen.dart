import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kiosk/services/payment_notification_watch_service.dart';
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
  Map<String, String> _qrs = {};
  bool _isLoading = true;
  int _adminTapCount = 0;
  bool _autoConfirmStarted = false;
  bool _confirmed = false;
  bool _showPaymentSuccess = false;

  @override
  void initState() {
    super.initState();
    unawaited(_settingsService.setPendingPaymentOrderId(widget.orderId));
    _loadQrCode();
    _startAutoConfirm();
  }

  void _confirmPayment() {
    if (_confirmed) return;
    _confirmed = true;
    unawaited(_settingsService.setPendingPaymentOrderId(null));
    if (mounted) {
      setState(() => _showPaymentSuccess = true);
    }
    unawaited(
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        widget.onPaymentConfirmed();
      }),
    );
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
        _confirmPayment();
      },
      onMismatch: (message) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.amountMismatchWaiting)),
        );
      },
      onTimeout: () async {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(l10n.paymentTimeoutTitle),
              content: Text(l10n.paymentTimeoutContent),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.ok),
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
    if (!_confirmed) {
      final pendingId = _settingsService.getPendingPaymentOrderId();
      if (pendingId == widget.orderId) {
        unawaited(_settingsService.setPendingPaymentOrderId(null));
      }
    }
    super.dispose();
  }

  Future<void> _loadQrCode() async {
    final qrs = _settingsService.getPaymentQrs();
    if (mounted) {
      setState(() {
        _qrs = qrs;
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
                _confirmPayment();
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

  Widget _buildQrTile(String provider, String base64Qr) {
    final l10n = AppLocalizations.of(context)!;
    final label = provider == 'alipay'
        ? l10n.paymentMethodAlipay
        : provider == 'wechat'
            ? l10n.paymentMethodWechat
            : provider;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _handleAdminTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.memory(
              base64Decode(base64Qr),
              width: 220,
              height: 220,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '¥');
    final providers = _qrs.keys.toList()..sort();
    
    return Scaffold(
      // backgroundColor: Colors.black, // Use theme
      appBar: AppBar(
        title: Text(l10n.payment),
        // backgroundColor: Colors.black, // Use theme
        // foregroundColor: Colors.white, // Use theme
      ),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              Widget content;
              if (_isLoading) {
                content = const CircularProgressIndicator();
              } else if (providers.isEmpty) {
                content = Text(
                  l10n.failedQr,
                  style: TextStyle(color: theme.colorScheme.error),
                );
              } else {
                content = Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final p in providers) _buildQrTile(p, _qrs[p]!),
                  ],
                );
              }

              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.totalWithAmount(currencyFormat.format(widget.totalAmount)),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 32),
                          content,
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              l10n.scanQr,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (_showPaymentSuccess)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.65),
                child: Center(
                  child: AnimatedScale(
                    scale: _showPaymentSuccess ? 1 : 0.9,
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 96),
                        const SizedBox(height: 16),
                        Text(
                          l10n.paymentSuccess,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.returningHome,
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
