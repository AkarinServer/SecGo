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
  String get pairedKiosks => 'Paired Kiosks';

  @override
  String get noKiosksPaired => 'No kiosks paired';

  @override
  String get kioskLabel => 'Kiosk';

  @override
  String kioskWithId(Object id) {
    return 'Kiosk $id';
  }

  @override
  String kioskHistoryTitle(Object name) {
    return '$name History';
  }

  @override
  String get removeKioskTitle => 'Remove Kiosk';

  @override
  String removeKioskMessage(Object kiosk) {
    return 'Are you sure you want to remove $kiosk?';
  }

  @override
  String get viewOrderHistory => 'View Order History';

  @override
  String get connected => 'Connected';

  @override
  String get pairNewKiosk => 'Pair New Kiosk';

  @override
  String get runDiagnostics => 'Run Diagnostics';

  @override
  String get runningSyncTest => 'Running Sync Test...';

  @override
  String get runningBackupTest => 'Running Backup Test...';

  @override
  String get testsCompleteCheckLogs => 'Tests Complete. Check Logs.';

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
  String get barcodeLabel => 'Barcode';

  @override
  String get saveProduct => 'Save Product';

  @override
  String get save => 'Save';

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

  @override
  String get backupRestore => 'Backup & Restore';

  @override
  String get createNewBackup => 'Create New Backup';

  @override
  String get noBackupsFound => 'No backups found';

  @override
  String get backupCreated => 'Backup created successfully';

  @override
  String get backupCreateFailed => 'Failed to create backup';

  @override
  String backupCreateFailedWithReason(Object reason) {
    return 'Backup failed: $reason';
  }

  @override
  String get confirmRestore => 'Confirm Restore';

  @override
  String get restoreOverwriteWarning =>
      'This will overwrite the products on the Kiosk with this backup. Orders will be preserved. Continue?';

  @override
  String get restore => 'Restore';

  @override
  String get restoreCompleted => 'Restore completed successfully';

  @override
  String get restoreFailed => 'Restore failed';

  @override
  String get failedToConnectKiosk => 'Failed to connect to Kiosk';

  @override
  String get retry => 'Retry';

  @override
  String get noOrderHistory => 'No order history found';

  @override
  String orderNumber(Object number) {
    return 'Order #$number';
  }

  @override
  String quantityMultiplier(Object quantity) {
    return 'x$quantity';
  }

  @override
  String get noProductsFound => 'No products found';

  @override
  String uploadedToKiosks(Object count) {
    return 'Uploaded to $count kiosks';
  }

  @override
  String errorWithMessage(Object error) {
    return 'Error: $error';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get productApiUrlLabel => 'Product API URL';

  @override
  String get productApiUrlHint =>
      'https://barcode100.market.alicloudapi.com/getBarcode?Code=';

  @override
  String get cancel => 'Cancel';

  @override
  String get remove => 'Remove';

  @override
  String get connectKioskToEdit =>
      'Connect to a kiosk to add or edit products.';

  @override
  String get kioskNotConnected => 'No kiosk connected';

  @override
  String get syncFailed => 'Failed to sync to kiosk. Please try again.';

  @override
  String get pairKioskTitle => 'Scan Kiosk QR to Pair';

  @override
  String pairingKiosk(Object ip) {
    return 'Pairing with kiosk at $ip...';
  }

  @override
  String get pairFailed => 'Pairing failed';

  @override
  String get pairSuccess => 'Kiosk paired successfully';

  @override
  String get scanKioskHint => 'Scan the QR code on the Kiosk Settings screen';
}
