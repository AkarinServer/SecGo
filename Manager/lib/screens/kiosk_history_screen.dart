import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:manager/models/kiosk.dart';
import 'package:manager/models/order.dart';
import 'package:manager/services/kiosk_client/kiosk_client.dart';
import 'package:manager/l10n/app_localizations.dart';

class KioskHistoryScreen extends StatefulWidget {
  final Kiosk kiosk;

  const KioskHistoryScreen({super.key, required this.kiosk});

  @override
  State<KioskHistoryScreen> createState() => _KioskHistoryScreenState();
}

class _KioskHistoryScreenState extends State<KioskHistoryScreen> {
  final KioskClientService _kioskService = KioskClientService();
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orders = await _kioskService.fetchOrders(
        widget.kiosk.ip,
        widget.kiosk.port,
        widget.kiosk.pin,
      );

      if (mounted) {
        setState(() {
          _orders = orders ?? [];
          _isLoading = false;
          if (orders == null) {
            _error = AppLocalizations.of(context)!.failedToConnectKiosk;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currencyFormat = NumberFormat.currency(symbol: '¥'); // Or match your locale
    final kioskId = widget.kiosk.id;
    final kioskName = widget.kiosk.name ??
        (kioskId != null ? l10n.kioskWithId(kioskId) : l10n.kioskLabel);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.kioskHistoryTitle(kioskName)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchHistory,
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                )
              : _orders.isEmpty
                  ? Center(child: Text(l10n.noOrderHistory))
                  : ListView.builder(
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        final date = DateTime.fromMillisecondsSinceEpoch(order.timestamp);
                        final method = order.alipayNotifyCheckedAmount
                            ? l10n.paymentMethodAlipay
                            : order.wechatNotifyCheckedAmount
                                ? l10n.paymentMethodWechat
                                : l10n.paymentMethodPending;
                        
                        return ExpansionTile(
                          leading: CircleAvatar(
                            child: Text('${index + 1}'),
                          ),
                          title: Text(
                            l10n.orderNumber(order.id.substring(order.id.length - 4)),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(DateFormat('yyyy-MM-dd HH:mm').format(date)),
                              Text(l10n.payMethodLabel(method)),
                            ],
                          ),
                          trailing: Text(
                            currencyFormat.format(order.totalAmount),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                          children: order.items.map((item) {
                            return ListTile(
                              title: Text(item.name),
                              subtitle: Text(l10n.quantityMultiplier(item.quantity)),
                              trailing: Text(currencyFormat.format(item.price * item.quantity)),
                              dense: true,
                            );
                          }).toList(),
                        );
                      },
                    ),
    );
  }
}
