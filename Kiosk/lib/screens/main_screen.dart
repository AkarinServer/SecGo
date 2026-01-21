import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add intl for date formatting
import 'package:kiosk/models/product.dart';
import 'package:kiosk/screens/payment_screen.dart';
import 'package:kiosk/screens/settings_screen.dart';
import 'package:kiosk/services/api_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:kiosk/l10n/app_localizations.dart';

// Helper class for cart items
class CartItem {
  final Product product;
  int quantity;

  CartItem(this.product, {this.quantity = 1});

  double get total => product.price * quantity;
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final ApiService _apiService = ApiService();
  final Map<String, CartItem> _cartItems = {}; // Use Map for O(1) lookups
  bool _isProcessing = false;
  // Initialize with Front Camera
  final MobileScannerController _scannerController = MobileScannerController(
    facing: CameraFacing.front,
  );

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  double get _totalAmount => _cartItems.values.fold(0, (sum, item) => sum + item.total);
  int get _totalItems => _cartItems.values.fold(0, (sum, item) => sum + item.quantity);

  void _addToCart(Product product) {
    setState(() {
      if (_cartItems.containsKey(product.barcode)) {
        _cartItems[product.barcode]!.quantity++;
      } else {
        _cartItems[product.barcode] = CartItem(product);
      }
    });
  }

  void _removeFromCart(String barcode) {
    setState(() {
      if (_cartItems.containsKey(barcode)) {
        if (_cartItems[barcode]!.quantity > 1) {
          _cartItems[barcode]!.quantity--;
        } else {
          _cartItems.remove(barcode);
        }
      }
    });
  }

  void _clearCart() {
    setState(() {
      _cartItems.clear();
    });
  }

  Future<void> _handleBarcodeDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String code = barcodes.first.rawValue!;

      setState(() => _isProcessing = true);

      final product = await _apiService.getProduct(code);
      if (product != null) {
        _addToCart(product);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.addedProduct(product.name)),
              duration: const Duration(milliseconds: 1000),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.productNotFound)),
          );
        }
      }

      await Future.delayed(const Duration(seconds: 1)); // Faster scan interval
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _processPayment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          totalAmount: _totalAmount,
          onPaymentConfirmed: () {
            _clearCart();
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.paymentSuccess)),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    // Formatting currency
    final currencyFormat = NumberFormat.currency(symbol: '¥'); // Or '$' based on locale

    return Scaffold(
      body: Stack(
        children: [
          // Layer 1: Main UI
          Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: Colors.red, // Brand color from image
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            "惠友", // Logo/Brand placeholder
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            l10n.storeName,
                            style: const TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          const SizedBox(width: 20),
                          Text(
                            "ID: 0000", // Placeholder ID
                            style: TextStyle(color: Colors.white.withOpacity(0.8)),
                          ),
                          const SizedBox(width: 20),
                          Text(
                            DateFormat('HH:mm').format(DateTime.now()),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: _clearCart,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(side: BorderSide(color: Colors.white)),
                        ),
                        child: Text(l10n.clearCart),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Body: Cart List
              Expanded(
                child: _cartItems.isEmpty
                    ? Center(
                        child: Text(
                          "Your cart is empty",
                          style: theme.textTheme.headlineSmall?.copyWith(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _cartItems.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = _cartItems.values.elementAt(index);
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.product.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${l10n.unit}${currencyFormat.format(item.product.price)}",
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                                // Quantity Controls
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove, size: 16),
                                        onPressed: () => _removeFromCart(item.product.barcode),
                                      ),
                                      Text(
                                        "${item.quantity}",
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add, size: 16),
                                        onPressed: () => _addToCart(item.product),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    currencyFormat.format(item.total),
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Left Actions
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () {
                             // Manual barcode entry dialog
                             // Placeholder
                          },
                          icon: const Icon(Icons.keyboard, color: Colors.grey),
                          label: Text(l10n.inputBarcode, style: const TextStyle(color: Colors.grey)),
                        ),
                        const SizedBox(width: 16),
                        TextButton.icon(
                          onPressed: () {
                            // No barcode selection
                            // Placeholder
                          },
                          icon: const Icon(Icons.grid_view, color: Colors.grey),
                          label: Text(l10n.noBarcodeItem, style: const TextStyle(color: Colors.grey)),
                        ),
                        const SizedBox(width: 16),
                         // Settings Button (Hidden access)
                        IconButton(
                          icon: const Icon(Icons.settings, color: Colors.grey),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SettingsScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Right Actions
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Total: ${currencyFormat.format(_totalAmount)}",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "$_totalItems items",
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: _cartItems.isEmpty ? null : _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Text(
                        l10n.checkout,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Layer 2: Camera Overlay (Suspension at bottom-left)
          Positioned(
            left: 20,
            bottom: 100, // Above the footer
            child: Container(
              width: 200,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: MobileScanner(
                  controller: _scannerController,
                  onDetect: _handleBarcodeDetect,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
