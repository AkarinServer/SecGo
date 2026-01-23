import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:manager/models/product.dart';
import 'package:manager/services/api_service.dart';
import 'package:manager/db/database_helper.dart';
import 'package:manager/services/kiosk_connection_service.dart';
import 'package:manager/services/kiosk_client/kiosk_client.dart';
import 'package:manager/l10n/app_localizations.dart'; // Re-added

class ProductFormScreen extends StatefulWidget {
  final String? initialBarcode;

  const ProductFormScreen({super.key, this.initialBarcode});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _barcodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _priceFocusNode = FocusNode();
  final ApiService _apiService = ApiService();
  final KioskConnectionService _connectionService = KioskConnectionService();
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _connectionService.addListener(_onConnectionChange);
    _priceFocusNode.addListener(() {
      if (!_priceFocusNode.hasFocus) {
        _normalizePriceOnBlur();
      }
    });
    if (widget.initialBarcode != null) {
      _barcodeController.text = widget.initialBarcode!;
      _loadProduct(widget.initialBarcode!);
    }
  }

  @override
  void dispose() {
    _connectionService.removeListener(_onConnectionChange);
    _barcodeController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _priceFocusNode.dispose();
    super.dispose();
  }

  void _onConnectionChange() {
    if (mounted) setState(() {});
  }

  Future<void> _loadProduct(String barcode) async {
    setState(() => _isLoading = true);
    
    // 1. Try Local DB first
    final localProduct = await DatabaseHelper.instance.getProduct(barcode);
    Product? product = localProduct;
    
    // 2. If not found, try External API (AliCloud)
    product ??= await _apiService.getProduct(barcode);

    if (product != null) {
      _nameController.text = product.name;
      if (localProduct != null) {
        _priceController.text = product.price.toStringAsFixed(2);
      } else {
        _priceController.text = '';
      }
    }
    setState(() => _isLoading = false);
  }

  bool _isPriceValidFinal(String input) {
    final v = input.trim();
    if (v.isEmpty) return false;
    if (v.contains(',')) return false;
    if (v.startsWith('.')) return false;
    if (v.endsWith('.')) return false;
    final ok = RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(v);
    if (!ok) return false;
    final n = double.tryParse(v);
    if (n == null) return false;
    if (n.isNaN || n.isInfinite) return false;
    if (n < 0) return false;
    return true;
  }

  void _normalizePriceOnBlur() {
    final raw = _priceController.text.trim();
    if (raw.isEmpty) return;
    if (!_isPriceValidFinal(raw)) {
      if (mounted) {
        _formKey.currentState?.validate();
      }
      return;
    }
    final n = double.parse(raw);
    final formatted = n.toStringAsFixed(2);
    if (_priceController.text != formatted) {
      _priceController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  Future<void> _scanBarcode() async {
    // Navigate to a dedicated scanner screen or show modal
    // For simplicity in this iteration, we'll assume a modal approach
    final String? barcode = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: 400,
        child: MobileScanner(
          controller: MobileScannerController(
            formats: const [
              BarcodeFormat.ean13,
              BarcodeFormat.ean8,
              BarcodeFormat.upcA,
              BarcodeFormat.upcE,
              BarcodeFormat.code128,
              BarcodeFormat.code39,
              BarcodeFormat.code93,
              BarcodeFormat.itf,
              BarcodeFormat.codabar,
            ],
          ),
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
              Navigator.pop(context, barcodes.first.rawValue);
            }
          },
        ),
      ),
    );

    if (barcode != null) {
      _barcodeController.text = barcode;
      _loadProduct(barcode);
    }
  }

  Future<void> _saveProduct() async {
    if (_isSaving) return;
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) {
      if (_priceController.text.trim().isEmpty || !_isPriceValidFinal(_priceController.text)) {
        _priceFocusNode.requestFocus();
      }
      return;
    }
    final kiosk = _connectionService.connectedKiosk;
    if (kiosk == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.connectKioskToEdit)),
      );
      return;
    }

    _normalizePriceOnBlur();
    setState(() => _isSaving = true);
    final product = Product(
      barcode: _barcodeController.text,
      name: _nameController.text,
      price: double.parse(_priceController.text.trim()),
      lastUpdated: DateTime.now().millisecondsSinceEpoch,
    );

    try {
      await DatabaseHelper.instance.upsertProduct(product);
      final client = KioskClientService();
      final success = await client.pushProductsToKiosk(
        kiosk.ip,
        kiosk.port,
        kiosk.pin,
        [product],
      );

      if (!success) {
        if (mounted) {
          setState(() => _isSaving = false);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.syncFailed)),
          );
        }
        return; // Stay on screen on failure
      }

      if (mounted) {
        setState(() => _isSaving = false);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.successSave)),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.errorSave}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isConnected = _connectionService.hasConnectedKiosk;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.addProduct)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (!isConnected)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          l10n.connectKioskToEdit,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _barcodeController,
                            decoration: InputDecoration(labelText: l10n.barcodeLabel),
                            enabled: isConnected && !_isSaving,
                            validator: (value) =>
                                value!.isEmpty ? l10n.barcodeRequired : null,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.qr_code_scanner),
                          onPressed: isConnected && !_isSaving
                              ? _scanBarcode
                              : null,
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: l10n.productName),
                      enabled: isConnected && !_isSaving,
                      validator: (value) =>
                          value!.isEmpty ? l10n.nameRequired : null,
                    ),
                    TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(labelText: l10n.price),
                      focusNode: _priceFocusNode,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          final text = newValue.text;
                          if (text.isEmpty) return newValue;
                          if (text.contains(',')) return oldValue;
                          if (text.startsWith('.')) return oldValue;
                          if (!RegExp(r'^\d*\.?\d{0,2}$').hasMatch(text)) {
                            return oldValue;
                          }
                          return newValue;
                        }),
                      ],
                      enabled: isConnected && !_isSaving,
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) return l10n.priceRequired;
                        if (!_isPriceValidFinal(v)) return l10n.priceInvalid;
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isConnected && !_isSaving
                          ? _saveProduct
                          : null,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.saveProduct),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
