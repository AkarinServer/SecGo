import 'package:flutter/material.dart';
import 'package:manager/db/database_helper.dart';
import 'package:manager/models/product.dart';
import 'package:manager/screens/product_form_screen.dart';
import 'package:manager/l10n/app_localizations.dart';
import 'package:manager/services/kiosk_connection_service.dart';
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
    setState(() => _isLoading = true);
    final products = await DatabaseHelper.instance.getAllProducts();
    setState(() {
      _products = products;
      _isLoading = false;
    });
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
                    return ListTile(
                      title: Text(product.name),
                      subtitle: Text(product.barcode),
                      trailing: Text(currencyFormat.format(product.price)),
                      onTap: isConnected ? () => _navigateToAddEdit(barcode: product.barcode) : null,
                      enabled: isConnected,
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
