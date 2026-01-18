// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '自动售货机管理';

  @override
  String get addProduct => '添加/编辑商品';

  @override
  String get uploadQr => '上传支付二维码';

  @override
  String get scanBarcode => '扫描条形码';

  @override
  String get productName => '商品名称';

  @override
  String get price => '价格';

  @override
  String get saveProduct => '保存商品';

  @override
  String get successSave => '商品保存成功';

  @override
  String get errorSave => '商品保存失败';

  @override
  String get successUpload => '二维码上传成功';

  @override
  String get errorUpload => '二维码上传失败';

  @override
  String get selectImage => '选择图片';

  @override
  String get uploadToServer => '上传到服务器';

  @override
  String get barcodeRequired => '请输入条形码';

  @override
  String get nameRequired => '请输入商品名称';

  @override
  String get priceRequired => '请输入价格';
}
