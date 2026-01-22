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
  String get pairedKiosks => '已配对终端';

  @override
  String get noKiosksPaired => '暂无已配对终端';

  @override
  String get kioskLabel => '终端';

  @override
  String kioskWithId(Object id) {
    return '终端 $id';
  }

  @override
  String kioskHistoryTitle(Object name) {
    return '$name 历史';
  }

  @override
  String get removeKioskTitle => '移除终端';

  @override
  String removeKioskMessage(Object kiosk) {
    return '确定要移除 $kiosk 吗？';
  }

  @override
  String get viewOrderHistory => '查看订单历史';

  @override
  String get connected => '已连接';

  @override
  String get pairNewKiosk => '配对新终端';

  @override
  String get runDiagnostics => '运行诊断';

  @override
  String get runningSyncTest => '正在运行同步测试...';

  @override
  String get runningBackupTest => '正在运行备份测试...';

  @override
  String get testsCompleteCheckLogs => '测试完成，请查看日志。';

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
  String get barcodeLabel => '条形码';

  @override
  String get saveProduct => '保存商品';

  @override
  String get save => '保存';

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

  @override
  String get backupRestore => '备份与恢复';

  @override
  String get createNewBackup => '创建新备份';

  @override
  String get noBackupsFound => '未找到备份';

  @override
  String get backupCreated => '备份创建成功';

  @override
  String get backupCreateFailed => '备份创建失败';

  @override
  String backupCreateFailedWithReason(Object reason) {
    return '备份失败：$reason';
  }

  @override
  String get confirmRestore => '确认恢复';

  @override
  String get restoreOverwriteWarning => '此操作将使用该备份覆盖终端商品数据，订单将被保留。是否继续？';

  @override
  String get restore => '恢复';

  @override
  String get restoreCompleted => '恢复成功';

  @override
  String get restoreFailed => '恢复失败';

  @override
  String get failedToConnectKiosk => '连接终端失败';

  @override
  String get retry => '重试';

  @override
  String get noOrderHistory => '未找到订单历史';

  @override
  String orderNumber(Object number) {
    return '订单 #$number';
  }

  @override
  String quantityMultiplier(Object quantity) {
    return 'x$quantity';
  }

  @override
  String get noProductsFound => '未找到商品';

  @override
  String uploadedToKiosks(Object count) {
    return '已上传至 $count 个终端';
  }

  @override
  String errorWithMessage(Object error) {
    return '错误：$error';
  }

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsSaved => '设置已保存';

  @override
  String get productApiUrlLabel => '商品API地址';

  @override
  String get productApiUrlHint =>
      'https://barcode100.market.alicloudapi.com/getBarcode?Code=';

  @override
  String get cancel => '取消';

  @override
  String get remove => '移除';

  @override
  String get connectKioskToEdit => '请先连接自助终端后再添加或编辑商品。';

  @override
  String get kioskNotConnected => '未连接自助终端';

  @override
  String get syncFailed => '同步到自助终端失败，请重试。';

  @override
  String get pairKioskTitle => '扫描终端二维码进行配对';

  @override
  String pairingKiosk(Object ip) {
    return '正在与终端 $ip 配对...';
  }

  @override
  String get pairFailed => '配对失败';

  @override
  String get pairSuccess => '终端配对成功';

  @override
  String get scanKioskHint => '请扫描自助终端设置页面上的二维码';

  @override
  String get delete => '删除';

  @override
  String get deleteProductTitle => '删除商品';

  @override
  String deleteProductMessage(Object name) {
    return '确定要删除$name吗？';
  }

  @override
  String get deleteSuccess => '商品已删除';

  @override
  String get deleteFailed => '删除失败';

  @override
  String get deleteSyncFailed => '商品已删除，但同步到自助终端失败。';

  @override
  String get connectKioskToUpload => '请先连接自助终端后再上传二维码。';

  @override
  String restoreFailedWithReason(Object reason) {
    return '恢复失败：$reason';
  }

  @override
  String get enterPinPrompt => '请输入PIN以完成配对';

  @override
  String get enterPinTitle => '输入PIN';

  @override
  String get enterPinHint => '终端PIN';

  @override
  String get pinLength => 'PIN至少4位';

  @override
  String get confirm => '确认';
}
