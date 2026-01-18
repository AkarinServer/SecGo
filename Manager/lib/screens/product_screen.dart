import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:manager/models/product.dart';
import 'package:manager/services/api_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProductScreen extends StatefulWidget {
  final String? initialBarcode;

  const ProductScreen({super.key, this.initialBarcode});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _barcodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialBarcode != null) {
      _barcodeController.text = widget.initialBarcode!;
      _loadProduct(widget.initialBarcode!);
    }
  }

  Future<void> _loadProduct(String barcode) async {
    setState(() => _isLoading = true);
    final product = await _apiService.getProduct(barcode);
    if (product != null) {
      _nameController.text = product.name;
      _priceController.text = product.price.toString();
    }
    setState(() => _isLoading = false);
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final product = Product(
      barcode: _barcodeController.text,
      name: _nameController.text,
      price: double.parse(_priceController.text),
      lastUpdated: 0, // Server will set this
    );

    final success = await _apiService.saveProduct(product);
    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.successSave)),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorSave)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _barcodeController,
                            decoration: const InputDecoration(labelText: 'Barcode'),
                            validator: (value) =>
                                value!.isEmpty ? l10n.barcodeRequired : null,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.qr_code_scanner),
                          onPressed: _scanBarcode,
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: l10n.productName),
                      validator: (value) =>
                          value!.isEmpty ? l10n.nameRequired : null,
                    ),
                    TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(labelText: l10n.price),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? l10n.priceRequired : null,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveProduct,
                      child: Text(l10n.saveProduct),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
