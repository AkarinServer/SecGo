// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '自动售货机';

  @override
  String get cart => '购物车';

  @override
  String get total => '总计:';

  @override
  String get payNow => '立即支付';

  @override
  String get payment => '支付';

  @override
  String get scanQr => '请使用银行App扫描二维码';

  @override
  String get failedQr => '无法加载支付二维码';

  @override
  String get adminConfirm => '管理员确认';

  @override
  String get enterPin => '输入PIN码';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get invalidPin => '无效的PIN码';

  @override
  String addedProduct(Object product) {
    return '已添加 $product';
  }

  @override
  String productNotFound(Object barcode) {
    return '未找到商品 $barcode';
  }

  @override
  String get paymentSuccess => '支付成功!';

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
  String get storeName => 'SecGo 便利店';

  @override
  String get clearCart => '清空购物车';

  @override
  String get inputBarcode => '输入商品条码';

  @override
  String get noBarcodeItem => '无条码商品';

  @override
  String get checkout => '去结算';

  @override
  String get unit => '单价: ';
}
