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
  String get cart => 'Cart';

  @override
  String get total => 'Total:';

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
  String addedProduct(Object product) {
    return 'Added $product';
  }

  @override
  String get productNotFound => 'Product not found';

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
  String get storeName => 'SecGo Store';

  @override
  String get clearCart => 'Clear Cart';

  @override
  String get inputBarcode => 'Input Barcode';

  @override
  String get noBarcodeItem => 'No Barcode Item';

  @override
  String get checkout => 'Checkout';

  @override
  String get unit => 'Unit: ';
}
