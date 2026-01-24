import 'package:flutter/material.dart';
import 'package:kiosk/db/database_helper.dart';
import 'package:kiosk/models/product.dart';
import 'package:intl/intl.dart';
import 'package:kiosk/l10n/app_localizations.dart';

class ManualBarcodeDialog extends StatefulWidget {
  const ManualBarcodeDialog({super.key});

  @override
  State<ManualBarcodeDialog> createState() => _ManualBarcodeDialogState();
}

class _ManualBarcodeDialogState extends State<ManualBarcodeDialog> {
  String _input = '';
  List<Product> _suggestions = [];
  bool _isLoading = false;
  final _db = DatabaseHelper.instance;

  void _onKeyTap(String key) {
    setState(() {
      _input += key;
    });
    _search();
  }

  void _onBackspace() {
    if (_input.isNotEmpty) {
      setState(() {
        _input = _input.substring(0, _input.length - 1);
      });
      _search();
    }
  }

  void _onClear() {
    setState(() {
      _input = '';
      _suggestions = [];
    });
  }

  Future<void> _search() async {
    if (_input.isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final results = await _db.searchProducts(_input);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onProductSelected(Product product) {
    Navigator.pop(context, product);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currencyFormat = NumberFormat.currency(symbol: '¥');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 700,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
             // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.inputBarcode, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            
            // Input Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _input.isEmpty ? l10n.inputBarcode : _input,
                style: TextStyle(
                  fontSize: 32,
                  color: _input.isEmpty ? Colors.grey : Colors.black,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),

            // Suggestions List
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _suggestions.isEmpty
                  ? Center(child: Text(_input.isEmpty ? '' : l10n.productNotFound(_input)))
                  : ListView.builder(
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final product = _suggestions[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: const Icon(Icons.shopping_bag_outlined),
                            title: Text(product.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            subtitle: Text('${product.barcode} ${product.brand ?? ''}'),
                            trailing: Text(
                              currencyFormat.format(product.price),
                              style: const TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                            onTap: () => _onProductSelected(product),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            
            // Numeric Keypad
            SizedBox(
              height: 300,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: GridView.count(
                      crossAxisCount: 3,
                      childAspectRatio: 1.5,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (var i = 1; i <= 9; i++)
                          _buildKey(i.toString()),
                        _buildKey('0'),
                        // Using a distinct visual style for special keys if needed
                        _buildKey('.', onTap: () => _onKeyTap('.')),
                        _buildBackspace(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                         Expanded(child: _buildActionButton(l10n.clear, Colors.orange, _onClear)),
                         const SizedBox(height: 10),
                         Expanded(child: _buildActionButton(l10n.close, Colors.grey, () => Navigator.pop(context))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKey(String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () => _onKeyTap(label),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
             BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 2, offset: const Offset(1, 1)),
          ],
        ),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      ),
    );
  }
  
  Widget _buildBackspace() {
    return InkWell(
      onTap: _onBackspace,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.backspace, size: 28),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
