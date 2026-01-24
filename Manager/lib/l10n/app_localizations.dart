import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Vending Manager'**
  String get appTitle;

  /// No description provided for @pairedKiosks.
  ///
  /// In en, this message translates to:
  /// **'Paired Kiosks'**
  String get pairedKiosks;

  /// No description provided for @noKiosksPaired.
  ///
  /// In en, this message translates to:
  /// **'No kiosks paired'**
  String get noKiosksPaired;

  /// No description provided for @kioskLabel.
  ///
  /// In en, this message translates to:
  /// **'Kiosk'**
  String get kioskLabel;

  /// No description provided for @kioskWithId.
  ///
  /// In en, this message translates to:
  /// **'Kiosk {id}'**
  String kioskWithId(Object id);

  /// No description provided for @kioskHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} History'**
  String kioskHistoryTitle(Object name);

  /// No description provided for @removeKioskTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Kiosk'**
  String get removeKioskTitle;

  /// No description provided for @removeKioskMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove {kiosk}?'**
  String removeKioskMessage(Object kiosk);

  /// No description provided for @viewOrderHistory.
  ///
  /// In en, this message translates to:
  /// **'View Order History'**
  String get viewOrderHistory;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @pairNewKiosk.
  ///
  /// In en, this message translates to:
  /// **'Pair New Kiosk'**
  String get pairNewKiosk;

  /// No description provided for @runDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Run Diagnostics'**
  String get runDiagnostics;

  /// No description provided for @runningSyncTest.
  ///
  /// In en, this message translates to:
  /// **'Running Sync Test...'**
  String get runningSyncTest;

  /// No description provided for @runningBackupTest.
  ///
  /// In en, this message translates to:
  /// **'Running Backup Test...'**
  String get runningBackupTest;

  /// No description provided for @testsCompleteCheckLogs.
  ///
  /// In en, this message translates to:
  /// **'Tests Complete. Check Logs.'**
  String get testsCompleteCheckLogs;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add/Edit Product'**
  String get addProduct;

  /// No description provided for @uploadQr.
  ///
  /// In en, this message translates to:
  /// **'Upload Payment QR'**
  String get uploadQr;

  /// No description provided for @scanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode'**
  String get scanBarcode;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @barcodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcodeLabel;

  /// No description provided for @noBarcodeProduct.
  ///
  /// In en, this message translates to:
  /// **'No barcode product'**
  String get noBarcodeProduct;

  /// No description provided for @saveProduct.
  ///
  /// In en, this message translates to:
  /// **'Save Product'**
  String get saveProduct;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @successSave.
  ///
  /// In en, this message translates to:
  /// **'Product saved successfully'**
  String get successSave;

  /// No description provided for @errorSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save product'**
  String get errorSave;

  /// No description provided for @successUpload.
  ///
  /// In en, this message translates to:
  /// **'QR Code uploaded successfully'**
  String get successUpload;

  /// No description provided for @errorUpload.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload QR Code'**
  String get errorUpload;

  /// No description provided for @selectImage.
  ///
  /// In en, this message translates to:
  /// **'Select Image'**
  String get selectImage;

  /// No description provided for @uploadToServer.
  ///
  /// In en, this message translates to:
  /// **'Upload to Server'**
  String get uploadToServer;

  /// No description provided for @barcodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter barcode'**
  String get barcodeRequired;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter name'**
  String get nameRequired;

  /// No description provided for @priceRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter price'**
  String get priceRequired;

  /// No description provided for @priceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid price (max 2 decimals)'**
  String get priceInvalid;

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupRestore;

  /// No description provided for @createNewBackup.
  ///
  /// In en, this message translates to:
  /// **'Create New Backup'**
  String get createNewBackup;

  /// No description provided for @noBackupsFound.
  ///
  /// In en, this message translates to:
  /// **'No backups found'**
  String get noBackupsFound;

  /// No description provided for @backupCreated.
  ///
  /// In en, this message translates to:
  /// **'Backup created successfully'**
  String get backupCreated;

  /// No description provided for @backupCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create backup'**
  String get backupCreateFailed;

  /// No description provided for @backupCreateFailedWithReason.
  ///
  /// In en, this message translates to:
  /// **'Backup failed: {reason}'**
  String backupCreateFailedWithReason(Object reason);

  /// No description provided for @confirmRestore.
  ///
  /// In en, this message translates to:
  /// **'Confirm Restore'**
  String get confirmRestore;

  /// No description provided for @restoreOverwriteWarning.
  ///
  /// In en, this message translates to:
  /// **'This will overwrite the products on the Kiosk with this backup. Orders will be preserved. Continue?'**
  String get restoreOverwriteWarning;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @restoreCompleted.
  ///
  /// In en, this message translates to:
  /// **'Restore completed successfully'**
  String get restoreCompleted;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed'**
  String get restoreFailed;

  /// No description provided for @failedToConnectKiosk.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect to Kiosk'**
  String get failedToConnectKiosk;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noOrderHistory.
  ///
  /// In en, this message translates to:
  /// **'No order history found'**
  String get noOrderHistory;

  /// No description provided for @orderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order #{number}'**
  String orderNumber(Object number);

  /// No description provided for @quantityMultiplier.
  ///
  /// In en, this message translates to:
  /// **'x{quantity}'**
  String quantityMultiplier(Object quantity);

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noProductsFound;

  /// No description provided for @uploadedToKiosks.
  ///
  /// In en, this message translates to:
  /// **'Uploaded to {count} kiosks'**
  String uploadedToKiosks(Object count);

  /// No description provided for @errorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorWithMessage(Object error);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @productApiUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Product API URL'**
  String get productApiUrlLabel;

  /// No description provided for @productApiUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://barcode100.market.alicloudapi.com/getBarcode?Code='**
  String get productApiUrlHint;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @connectKioskToEdit.
  ///
  /// In en, this message translates to:
  /// **'Connect to a kiosk to add or edit products.'**
  String get connectKioskToEdit;

  /// No description provided for @kioskNotConnected.
  ///
  /// In en, this message translates to:
  /// **'No kiosk connected'**
  String get kioskNotConnected;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to sync to kiosk. Please try again.'**
  String get syncFailed;

  /// No description provided for @pairKioskTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Kiosk QR to Pair'**
  String get pairKioskTitle;

  /// No description provided for @pairingKiosk.
  ///
  /// In en, this message translates to:
  /// **'Pairing with kiosk at {ip}...'**
  String pairingKiosk(Object ip);

  /// No description provided for @pairFailed.
  ///
  /// In en, this message translates to:
  /// **'Pairing failed'**
  String get pairFailed;

  /// No description provided for @pairSuccess.
  ///
  /// In en, this message translates to:
  /// **'Kiosk paired successfully'**
  String get pairSuccess;

  /// No description provided for @scanKioskHint.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code on the Kiosk Settings screen'**
  String get scanKioskHint;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Product'**
  String get deleteProductTitle;

  /// No description provided for @deleteProductMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteProductMessage(Object name);

  /// No description provided for @deleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product deleted'**
  String get deleteSuccess;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete product'**
  String get deleteFailed;

  /// No description provided for @deleteSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Product deleted, but sync to kiosk failed.'**
  String get deleteSyncFailed;

  /// No description provided for @connectKioskToUpload.
  ///
  /// In en, this message translates to:
  /// **'Connect to a kiosk to upload the QR code.'**
  String get connectKioskToUpload;

  /// No description provided for @restoreFailedWithReason.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {reason}'**
  String restoreFailedWithReason(Object reason);

  /// No description provided for @enterPinPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN to pair'**
  String get enterPinPrompt;

  /// No description provided for @enterPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get enterPinTitle;

  /// No description provided for @enterPinHint.
  ///
  /// In en, this message translates to:
  /// **'Kiosk PIN'**
  String get enterPinHint;

  /// No description provided for @pinLength.
  ///
  /// In en, this message translates to:
  /// **'PIN must be at least 4 digits'**
  String get pinLength;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @payMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Pay: {method}'**
  String payMethodLabel(Object method);

  /// No description provided for @paymentMethodAlipay.
  ///
  /// In en, this message translates to:
  /// **'Alipay'**
  String get paymentMethodAlipay;

  /// No description provided for @paymentMethodWechat.
  ///
  /// In en, this message translates to:
  /// **'WeChat'**
  String get paymentMethodWechat;

  /// No description provided for @paymentMethodPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get paymentMethodPending;

  /// No description provided for @manualPair.
  ///
  /// In en, this message translates to:
  /// **'Manual Pair'**
  String get manualPair;

  /// No description provided for @ipLabel.
  ///
  /// In en, this message translates to:
  /// **'IP'**
  String get ipLabel;

  /// No description provided for @portLabel.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get portLabel;

  /// No description provided for @addAlipayQr.
  ///
  /// In en, this message translates to:
  /// **'Add Alipay QR'**
  String get addAlipayQr;

  /// No description provided for @addWechatQr.
  ///
  /// In en, this message translates to:
  /// **'Add WeChat QR'**
  String get addWechatQr;

  /// No description provided for @addCustomQr.
  ///
  /// In en, this message translates to:
  /// **'Add Custom QR'**
  String get addCustomQr;

  /// No description provided for @customPaymentMethodTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom payment method'**
  String get customPaymentMethodTitle;

  /// No description provided for @customPaymentMethodHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. bank_xyz'**
  String get customPaymentMethodHint;

  /// No description provided for @customPaymentMethodInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get customPaymentMethodInvalid;

  /// No description provided for @uploadedPaymentQrs.
  ///
  /// In en, this message translates to:
  /// **'Uploaded {count} payment QRs'**
  String uploadedPaymentQrs(Object count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
