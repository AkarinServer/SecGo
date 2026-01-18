// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Vending Manager';

  @override
  String get addProduct => 'Add/Edit Product';

  @override
  String get uploadQr => 'Upload Payment QR';

  @override
  String get scanBarcode => 'Scan Barcode';

  @override
  String get productName => 'Product Name';

  @override
  String get price => 'Price';

  @override
  String get saveProduct => 'Save Product';

  @override
  String get successSave => 'Product saved successfully';

  @override
  String get errorSave => 'Failed to save product';

  @override
  String get successUpload => 'QR Code uploaded successfully';

  @override
  String get errorUpload => 'Failed to upload QR Code';

  @override
  String get selectImage => 'Select Image';

  @override
  String get uploadToServer => 'Upload to Server';

  @override
  String get barcodeRequired => 'Please enter barcode';

  @override
  String get nameRequired => 'Please enter name';

  @override
  String get priceRequired => 'Please enter price';
}
