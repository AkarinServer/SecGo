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
  /// **'Vending Kiosk'**
  String get appTitle;

  /// No description provided for @brandName.
  ///
  /// In en, this message translates to:
  /// **'Baihui Convenience Store'**
  String get brandName;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total:'**
  String get total;

  /// No description provided for @totalWithAmount.
  ///
  /// In en, this message translates to:
  /// **'Total: {amount}'**
  String totalWithAmount(Object amount);

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemsCount(Object count);

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'PAY NOW'**
  String get payNow;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @scanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code with your banking app'**
  String get scanQr;

  /// No description provided for @failedQr.
  ///
  /// In en, this message translates to:
  /// **'Failed to load Payment QR'**
  String get failedQr;

  /// No description provided for @adminConfirm.
  ///
  /// In en, this message translates to:
  /// **'Admin Confirmation'**
  String get adminConfirm;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get enterPin;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @invalidPin.
  ///
  /// In en, this message translates to:
  /// **'Invalid PIN'**
  String get invalidPin;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @amountMismatchWaiting.
  ///
  /// In en, this message translates to:
  /// **'Amount mismatch, still waiting for payment...'**
  String get amountMismatchWaiting;

  /// No description provided for @paymentTimeoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment timeout'**
  String get paymentTimeoutTitle;

  /// No description provided for @paymentTimeoutContent.
  ///
  /// In en, this message translates to:
  /// **'Auto confirmation timed out. Manual/admin handling required.'**
  String get paymentTimeoutContent;

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

  /// No description provided for @addedProduct.
  ///
  /// In en, this message translates to:
  /// **'Added {product}'**
  String addedProduct(Object product);

  /// No description provided for @productNotFound.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find product {barcode}'**
  String productNotFound(Object barcode);

  /// No description provided for @scanError.
  ///
  /// In en, this message translates to:
  /// **'Scan error: {error}'**
  String scanError(Object error);

  /// No description provided for @analyzingDebugImage.
  ///
  /// In en, this message translates to:
  /// **'Analyzing debug image...'**
  String get analyzingDebugImage;

  /// No description provided for @foundBarcodes.
  ///
  /// In en, this message translates to:
  /// **'Found {count} barcodes in image'**
  String foundBarcodes(Object count);

  /// No description provided for @noBarcodesFound.
  ///
  /// In en, this message translates to:
  /// **'No barcodes found in debug image'**
  String get noBarcodesFound;

  /// No description provided for @analyzeImageError.
  ///
  /// In en, this message translates to:
  /// **'Error analyzing image: {error}'**
  String analyzeImageError(Object error);

  /// No description provided for @paymentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment Successful!'**
  String get paymentSuccess;

  /// No description provided for @setupPin.
  ///
  /// In en, this message translates to:
  /// **'Setup Admin PIN'**
  String get setupPin;

  /// No description provided for @setAdminPin.
  ///
  /// In en, this message translates to:
  /// **'Set Admin PIN'**
  String get setAdminPin;

  /// No description provided for @pinDescription.
  ///
  /// In en, this message translates to:
  /// **'This PIN will be used to access settings and connect to the manager app.'**
  String get pinDescription;

  /// No description provided for @pinRequired.
  ///
  /// In en, this message translates to:
  /// **'PIN is required'**
  String get pinRequired;

  /// No description provided for @pinLength.
  ///
  /// In en, this message translates to:
  /// **'PIN must be at least 4 digits'**
  String get pinLength;

  /// No description provided for @confirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get confirmPin;

  /// No description provided for @pinMismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match'**
  String get pinMismatch;

  /// No description provided for @saveAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Save & Continue'**
  String get saveAndContinue;

  /// No description provided for @kioskIdLabel.
  ///
  /// In en, this message translates to:
  /// **'ID: {id}'**
  String kioskIdLabel(Object id);

  /// No description provided for @clearCart.
  ///
  /// In en, this message translates to:
  /// **'Clear Cart'**
  String get clearCart;

  /// No description provided for @emptyCart.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get emptyCart;

  /// No description provided for @inputBarcode.
  ///
  /// In en, this message translates to:
  /// **'Input Barcode'**
  String get inputBarcode;

  /// No description provided for @noBarcodeItem.
  ///
  /// In en, this message translates to:
  /// **'No Barcode Item'**
  String get noBarcodeItem;

  /// No description provided for @debugScanFile.
  ///
  /// In en, this message translates to:
  /// **'Debug Scan File'**
  String get debugScanFile;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit: '**
  String get unit;

  /// No description provided for @kioskSettings.
  ///
  /// In en, this message translates to:
  /// **'Kiosk Settings'**
  String get kioskSettings;

  /// No description provided for @kioskReadyToSync.
  ///
  /// In en, this message translates to:
  /// **'Kiosk is Ready to Sync'**
  String get kioskReadyToSync;

  /// No description provided for @ipAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'IP: {ip}:{port}'**
  String ipAddressLabel(Object ip, Object port);

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @serverStartFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed to Start Server'**
  String get serverStartFailedTitle;

  /// No description provided for @serverStartFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not find a valid IP address.\nPlease check your Wi-Fi, Hotspot, or Mobile Data connection.'**
  String get serverStartFailedMessage;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @serverNoIp.
  ///
  /// In en, this message translates to:
  /// **'Failed to start server: No IP address found'**
  String get serverNoIp;

  /// No description provided for @restoreComplete.
  ///
  /// In en, this message translates to:
  /// **'Restore Complete'**
  String get restoreComplete;

  /// No description provided for @returningHome.
  ///
  /// In en, this message translates to:
  /// **'Refreshing data...'**
  String get returningHome;
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
