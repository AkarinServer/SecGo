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
}
