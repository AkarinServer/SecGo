// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Vending Kiosk';

  @override
  String get brandName => 'Baihui Convenience Store';

  @override
  String get cart => 'Cart';

  @override
  String get total => 'Total:';

  @override
  String totalWithAmount(Object amount) {
    return 'Total: $amount';
  }

  @override
  String itemsCount(Object count) {
    return '$count items';
  }

  @override
  String get payNow => 'PAY NOW';

  @override
  String get payment => 'Payment';

  @override
  String get scanQr => 'Scan QR code with your banking app';

  @override
  String get failedQr => 'Failed to load Payment QR';

  @override
  String get adminConfirm => 'Admin Confirmation';

  @override
  String get enterPin => 'Enter PIN';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get invalidPin => 'Invalid PIN';

  @override
  String get ok => 'OK';

  @override
  String get amountMismatchWaiting =>
      'Amount mismatch, still waiting for payment...';

  @override
  String get paymentTimeoutTitle => 'Payment timeout';

  @override
  String get paymentTimeoutContent =>
      'Auto confirmation timed out. Manual/admin handling required.';

  @override
  String get paymentMethodAlipay => 'Alipay';

  @override
  String get paymentMethodWechat => 'WeChat';

  @override
  String addedProduct(Object product) {
    return 'Added $product';
  }

  @override
  String productNotFound(Object barcode) {
    return 'Can\'t find product $barcode';
  }

  @override
  String scanError(Object error) {
    return 'Scan error: $error';
  }

  @override
  String get analyzingDebugImage => 'Analyzing debug image...';

  @override
  String foundBarcodes(Object count) {
    return 'Found $count barcodes in image';
  }

  @override
  String get noBarcodesFound => 'No barcodes found in debug image';

  @override
  String analyzeImageError(Object error) {
    return 'Error analyzing image: $error';
  }

  @override
  String get paymentSuccess => 'Payment Successful!';

  @override
  String get setupPin => 'Setup Admin PIN';

  @override
  String get setAdminPin => 'Set Admin PIN';

  @override
  String get pinDescription =>
      'This PIN will be used to access settings and connect to the manager app.';

  @override
  String get pinRequired => 'PIN is required';

  @override
  String get pinLength => 'PIN must be at least 4 digits';

  @override
  String get confirmPin => 'Confirm PIN';

  @override
  String get pinMismatch => 'PINs do not match';

  @override
  String get saveAndContinue => 'Save & Continue';

  @override
  String kioskIdLabel(Object id) {
    return 'ID: $id';
  }

  @override
  String get clearCart => 'Clear Cart';

  @override
  String get emptyCart => 'Your cart is empty';

  @override
  String get inputBarcode => 'Input Barcode';

  @override
  String get noBarcodeItem => 'No Barcode Item';

  @override
  String get debugScanFile => 'Debug Scan File';

  @override
  String get checkout => 'Checkout';

  @override
  String get unit => 'Unit: ';

  @override
  String get kioskSettings => 'Kiosk Settings';

  @override
  String get kioskReadyToSync => 'Kiosk is Ready to Sync';

  @override
  String ipAddressLabel(Object ip, Object port) {
    return 'IP: $ip:$port';
  }

  @override
  String get close => 'Close';

  @override
  String get serverStartFailedTitle => 'Failed to Start Server';

  @override
  String get serverStartFailedMessage =>
      'Could not find a valid IP address.\nPlease check your Wi-Fi, Hotspot, or Mobile Data connection.';

  @override
  String get retry => 'Retry';

  @override
  String get serverNoIp => 'Failed to start server: No IP address found';

  @override
  String get restoreComplete => 'Restore Complete';

  @override
  String get returningHome => 'Refreshing data...';

  @override
  String get openLauncher => 'Open Launcher';

  @override
  String launcherTarget(Object target) {
    return 'Target: $target';
  }

  @override
  String get launcherDefault => 'Launcher';

  @override
  String get homeAppPackageTitle => 'Home app package (optional)';

  @override
  String get homeAppPackageHint => 'e.g. com.secgo.home';

  @override
  String get homeAppNotSet => 'Not set (use Launcher)';

  @override
  String get homeAppTitle => 'Home App (optional)';

  @override
  String get searchApps => 'Search apps';

  @override
  String get noAppsFound => 'No apps found';

  @override
  String homeAppOpenFailed(Object package) {
    return 'Can\'t open $package. Opening Launcher instead.';
  }

  @override
  String get noBarcodeProductsTitle => 'No Barcode Products';

  @override
  String get noBarcodeProductsEmpty => 'No no-barcode products';

  @override
  String get categories => 'Categories';

  @override
  String get categoryAll => 'All';

  @override
  String get categoryUncategorized => 'Uncategorized';

  @override
  String get searchProducts => 'Search products';

  @override
  String get networkSettings => 'Network';

  @override
  String get hotspot => 'Hotspot';

  @override
  String get hotspotHint => 'Enable hotspot for pairing';

  @override
  String get ssidLabel => 'SSID';

  @override
  String get passwordLabel => 'Password';

  @override
  String get locationPermissionRequired =>
      'Location permission is required to enable hotspot.';

  @override
  String get locationServiceRequired =>
      'Please turn on Location service to enable hotspot.';

  @override
  String hotspotFailedWithReason(Object reason) {
    return 'Hotspot failed: $reason';
  }

  @override
  String get hotspotEnabledInSystemSettings =>
      'Hotspot is already enabled in system settings.';

  @override
  String get hotspotChangeInSystemSettings =>
      'Change hotspot in system settings.';

  @override
  String get mobileData => 'Mobile data';

  @override
  String get mobileDataHint => 'Toggle mobile data (may be restricted)';

  @override
  String get networkToggleFailed => 'Action failed. Opening system settings…';

  @override
  String get clear => 'Clear';

  @override
  String get save => 'Save';
}
