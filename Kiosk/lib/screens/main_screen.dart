import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add intl for date formatting
import 'package:kiosk/db/database_helper.dart';
import 'package:kiosk/models/product.dart';
import 'package:kiosk/models/order.dart' as model; // Alias to avoid conflict if needed
import 'package:kiosk/screens/payment_screen.dart';
import 'package:kiosk/screens/settings_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:kiosk/l10n/app_localizations.dart';
import 'package:kiosk/config/store_config.dart';
import 'package:kiosk/services/restore_notifier.dart';
import 'package:kiosk/services/android_notification_listener_service.dart';

// Helper class for cart items
class CartItem {
  final Product product;
  int quantity;

  CartItem(this.product, {this.quantity = 1});

  double get total => product.price * quantity;
}

class BarcodeOverlayPainter extends CustomPainter {
  final BarcodeCapture capture;
  final Size widgetSize;

  BarcodeOverlayPainter({
    required this.capture,
    required this.widgetSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Use the image size from the capture
    final Size imageSize = capture.size; // e.g. 1280x720

    if (imageSize.width == 0 || imageSize.height == 0) {
      return;
    }

    // Calculate scale factors to map image coordinates to widget coordinates
    final double scaleX = widgetSize.width / imageSize.width;
    final double scaleY = widgetSize.height / imageSize.height;

    for (final barcode in capture.barcodes) {
      if (barcode.corners.isEmpty) continue;

      final path = Path();
      // Move to the first corner
      final first = barcode.corners.first;
      path.moveTo(first.dx * scaleX, first.dy * scaleY);

      // Draw lines to subsequent corners
      for (int i = 1; i < barcode.corners.length; i++) {
        final point = barcode.corners[i];
        path.lineTo(point.dx * scaleX, point.dy * scaleY);
      }
      
      // Close the loop
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BarcodeOverlayPainter oldDelegate) {
    return oldDelegate.capture != capture;
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final Map<String, CartItem> _cartItems = {}; // Use Map for O(1) lookups
  bool _isProcessing = false;
  final RestoreNotifier _restoreNotifier = RestoreNotifier.instance;
  final AndroidNotificationListenerService _notificationListenerService =
      AndroidNotificationListenerService();
  
  // Use the front camera as requested.
  final MobileScannerController _scannerController = MobileScannerController(
    facing: CameraFacing.front,
    cameraResolution: const Size(1280, 720),
    autoZoom: true,
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
      BarcodeFormat.qrCode,
    ],
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 250,
    returnImage: false, // Improves performance on older devices
  );

  @override
  void initState() {
    super.initState();
    _restoreNotifier.addListener(_handleRestore);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resumePendingPaymentIfAny();
    });
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _restoreNotifier.removeListener(_handleRestore);
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

  void _handleRestore() {
    if (!mounted) return;
    _clearCart();
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.restoreComplete),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _resumePendingPaymentIfAny() async {
    if (!mounted) return;
    final pending = await _db.getLatestPendingAlipayOrder();
    if (pending == null) return;
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          totalAmount: pending.totalAmount,
          orderId: pending.id,
          checkoutTimeMs: pending.alipayCheckoutTimeMs ?? pending.timestamp,
          baselineKeys: const [],
          autoConfirmEnabled: true,
          onPaymentConfirmed: () {
            if (!mounted) return;
            final l10n = AppLocalizations.of(context)!;
            final navigator = Navigator.of(context);
            final messenger = ScaffoldMessenger.of(context);
            navigator.popUntil((route) => route.isFirst);
            messenger.showSnackBar(
              SnackBar(
                content: Text(l10n.paymentSuccess),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleBarcodeDetect(BarcodeCapture capture) async {
    // Only process logic if not already processing
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String code = barcodes.first.rawValue!;
      debugPrint('Detected barcode: $code');

      setState(() => _isProcessing = true);
      
      // ... processing logic ...
      final product = await _db.getProduct(code);
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
            SnackBar(content: Text(AppLocalizations.of(context)!.productNotFound(code))),
          );
        }
      }

      await Future.delayed(const Duration(seconds: 1)); // Faster scan interval
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _handleBarcodeError(Object error, StackTrace stackTrace) {
    debugPrint('Barcode scan error: $error');
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.scanError(error))),
      );
    }
  }

  Future<void> _testScanFile() async {
    const String filePath = '/sdcard/DCIM/Camera/IMG_20260122_024901.jpg';
    try {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.analyzingDebugImage)),
        );
      }
      
      final BarcodeCapture? capture = await _scannerController.analyzeImage(filePath);
      
      if (capture != null && capture.barcodes.isNotEmpty) {
        await _handleBarcodeDetect(capture);
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.foundBarcodes(capture.barcodes.length))),
          );
        }
      } else {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.noBarcodesFound)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.analyzeImageError(e))),
        );
      }
    }
  }

  Future<void> _processPayment() async {
    if (_cartItems.isEmpty) return;
    if (_isProcessing) return;
    _isProcessing = true;
    final checkoutTimeMs = DateTime.now().millisecondsSinceEpoch;
    final order = model.Order(
      id: checkoutTimeMs.toString(),
      items: _cartItems.values
          .map((item) => model.OrderItem(
                barcode: item.product.barcode,
                name: item.product.name,
                price: item.product.price,
                quantity: item.quantity,
              ))
          .toList(),
      totalAmount: _totalAmount,
      timestamp: checkoutTimeMs,
      alipayCheckoutTimeMs: checkoutTimeMs,
    );

    var autoConfirmEnabled = false;
    var baselineKeys = <String>{};

    if (Platform.isAndroid) {
      autoConfirmEnabled = await _notificationListenerService.isEnabled();
      if (!autoConfirmEnabled && mounted) {
        final l10n = AppLocalizations.of(context)!;
        final action = await showDialog<String>(
          context: context,
          barrierDismissible: true,
          builder: (context) {
            return AlertDialog(
              title: Text(l10n.payment),
              content: const Text(
                'Auto-confirm requires Notification Access. Enable it to confirm Alipay payment automatically.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, 'continue'),
                  child: Text(l10n.confirm),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, 'open'),
                  child: const Text('Open Settings'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, 'retry'),
                  child: const Text('Retry'),
                ),
              ],
            );
          },
        );

        if (action == 'open') {
          await _notificationListenerService.openSettings();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Enable notification access, then tap Retry.')),
            );
          }
          autoConfirmEnabled = await _notificationListenerService.isEnabled();
        } else if (action == 'retry') {
          autoConfirmEnabled = await _notificationListenerService.isEnabled();
        } else {
          autoConfirmEnabled = false;
        }
      }

      if (autoConfirmEnabled) {
        final snapshot = await _notificationListenerService.getActiveAlipayNotificationsSnapshot();
        for (final n in snapshot) {
          final key = n['key'];
          final postTime = n['postTime'];
          if (key is! String || key.isEmpty) continue;
          if (postTime is int && postTime > checkoutTimeMs) continue;
          baselineKeys.add(key);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Auto confirmation unavailable. Manual confirmation required.')),
        );
      }
    }

    try {
      await _db.insertOrder(order);
    } catch (e) {
      debugPrint('Failed to save order: $e');
    }
    _isProcessing = false;

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          totalAmount: _totalAmount,
          orderId: order.id,
          checkoutTimeMs: checkoutTimeMs,
          baselineKeys: baselineKeys.toList(),
          autoConfirmEnabled: autoConfirmEnabled,
          onPaymentConfirmed: () {
            final l10n = AppLocalizations.of(context)!;
            final navigator = Navigator.of(context);
            final messenger = ScaffoldMessenger.of(context);

            _clearCart();
            navigator.pop();
            messenger.showSnackBar(
              SnackBar(content: Text(l10n.paymentSuccess)),
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
    final storeName = StoreConfig.storeName;
    
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
                          Text(
                            storeName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Text(
                            l10n.kioskIdLabel('0000'), // Placeholder ID
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
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
                          l10n.emptyCart,
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
                                  color: Colors.black.withValues(alpha: 0.05),
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
                      color: Colors.black.withValues(alpha: 0.1),
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
                        // Debug Scan Button
                        IconButton(
                          icon: const Icon(Icons.image_search, color: Colors.grey),
                          onPressed: _testScanFile,
                          tooltip: l10n.debugScanFile,
                        ),
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
                          l10n.totalWithAmount(currencyFormat.format(_totalAmount)),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          l10n.itemsCount(_totalItems),
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
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: MobileScanner(
                  controller: _scannerController,
                  onDetect: _handleBarcodeDetect,
                  onDetectError: _handleBarcodeError,
                  tapToFocus: true,
                  fit: BoxFit.cover,
                  overlayBuilder: (context, constraints) {
                    return ValueListenableBuilder(
                      valueListenable: _scannerController,
                      builder: (context, value, child) {
                        // In MobileScanner 7.x, value is MobileScannerState
                        // We need to check if we have a valid capture in the stream or state?
                        // Wait, MobileScannerState does NOT have 'capture'. 
                        // We must listen to the 'barcodes' stream for the overlay data.
                        return StreamBuilder<BarcodeCapture>(
                          stream: _scannerController.barcodes,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData || snapshot.data == null) {
                               return const SizedBox();
                            }
                            return IgnorePointer(
                              child: CustomPaint(
                                painter: BarcodeOverlayPainter(
                                  capture: snapshot.data!,
                                  widgetSize: Size(constraints.maxWidth, constraints.maxHeight),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
