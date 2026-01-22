import 'package:flutter/material.dart';
import 'package:manager/db/database_helper.dart';
import 'package:manager/models/product.dart';
import 'package:manager/screens/product_form_screen.dart';
import 'package:manager/l10n/app_localizations.dart';
import 'package:manager/services/kiosk_connection_service.dart';
import 'package:manager/services/kiosk_client/kiosk_client.dart';
import 'package:intl/intl.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Product> _products = [];
  bool _isLoading = true;
  final KioskConnectionService _connectionService = KioskConnectionService();
  final KioskClientService _kioskService = KioskClientService();

  @override
  void initState() {
    super.initState();
    _connectionService.addListener(_onConnectionChange);
    _loadProducts();
  }

  @override
  void dispose() {
    _connectionService.removeListener(_onConnectionChange);
    super.dispose();
  }

  void _onConnectionChange() {
    if (mounted) setState(() {});
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final products = await DatabaseHelper.instance.getAllProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToAddEdit({String? barcode}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormScreen(initialBarcode: barcode),
      ),
    );

    if (result == true) {
      _loadProducts();
    }
  }

  Future<bool> _confirmDelete(Product product) async {
    final l10n = AppLocalizations.of(context)!;
    if (!_connectionService.hasConnectedKiosk) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.kioskNotConnected)),
      );
      return false;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteProductTitle),
        content: Text(l10n.deleteProductMessage(product.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  Future<void> _deleteProduct(Product product) async {
    final l10n = AppLocalizations.of(context)!;
    final connectedKiosk = _connectionService.connectedKiosk;
    if (connectedKiosk == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.kioskNotConnected)),
      );
      await _loadProducts();
      return;
    }

    try {
      await DatabaseHelper.instance.deleteProduct(product.barcode);
      final products = await DatabaseHelper.instance.getAllProducts();
      final syncSuccess = await _kioskService.pushProductsToKiosk(
        connectedKiosk.ip,
        connectedKiosk.port,
        connectedKiosk.pin,
        products,
        replace: true,
      );
      await _loadProducts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            syncSuccess ? l10n.deleteSuccess : l10n.deleteSyncFailed,
          ),
        ),
      );
    } catch (e) {
      await _loadProducts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deleteFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isConnected = _connectionService.hasConnectedKiosk;
    final currencyFormat = NumberFormat.currency(symbol: '¥');

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addProduct)), // Reuse "Add Product" label or "Products"
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? Center(child: Text(l10n.noProductsFound))
              : ListView.builder(
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    final tile = ListTile(
                      key: ValueKey(product.barcode),
                      title: Text(product.name),
                      subtitle: Text(product.barcode),
                      trailing: Text(currencyFormat.format(product.price)),
                      onTap: isConnected ? () => _navigateToAddEdit(barcode: product.barcode) : null,
                      enabled: isConnected,
                    );

                    if (!isConnected) {
                      return tile;
                    }

                    return Dismissible(
                      key: ValueKey('dismiss_${product.barcode}'),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) => _confirmDelete(product),
                      onDismissed: (_) {
                        setState(() {
                          _products.removeAt(index);
                        });
                        _deleteProduct(product);
                      },
                      background: const SizedBox.shrink(),
                      secondaryBackground: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        color: Colors.red,
                        child: Text(
                          l10n.delete,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      child: tile,
                    );
                  },
                ),
      floatingActionButton: isConnected 
          ? FloatingActionButton(
              onPressed: () => _navigateToAddEdit(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
