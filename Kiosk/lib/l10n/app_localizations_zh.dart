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
  String get brandName => '百惠便利店';

  @override
  String get cart => '购物车';

  @override
  String get total => '总计:';

  @override
  String totalWithAmount(Object amount) {
    return '总计: $amount';
  }

  @override
  String itemsCount(Object count) {
    return '$count 件';
  }

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
  String get ok => '确定';

  @override
  String get amountMismatchWaiting => '金额不匹配，仍在等待支付...';

  @override
  String get paymentTimeoutTitle => '支付超时';

  @override
  String get paymentTimeoutContent => '自动确认超时，需要人工/管理员处理。';

  @override
  String get paymentMethodAlipay => '支付宝';

  @override
  String get paymentMethodWechat => '微信';

  @override
  String addedProduct(Object product) {
    return '已添加 $product';
  }

  @override
  String productNotFound(Object barcode) {
    return '未找到商品 $barcode';
  }

  @override
  String scanError(Object error) {
    return '扫描出错: $error';
  }

  @override
  String get analyzingDebugImage => '正在分析调试图片...';

  @override
  String foundBarcodes(Object count) {
    return '在图片中发现 $count 个条码';
  }

  @override
  String get noBarcodesFound => '调试图片中未发现条码';

  @override
  String analyzeImageError(Object error) {
    return '分析图片出错: $error';
  }

  @override
  String get paymentSuccess => '支付成功!';

  @override
  String get setupPin => '设置管理员PIN码';

  @override
  String get setAdminPin => '设置管理员PIN码';

  @override
  String get pinDescription => '此PIN码将用于访问设置和连接管理应用。';

  @override
  String get pinRequired => '请输入PIN码';

  @override
  String get pinLength => 'PIN码至少需要4位数字';

  @override
  String get confirmPin => '确认PIN码';

  @override
  String get pinMismatch => '两次输入的PIN码不一致';

  @override
  String get saveAndContinue => '保存并继续';

  @override
  String kioskIdLabel(Object id) {
    return '编号: $id';
  }

  @override
  String get clearCart => '清空购物车';

  @override
  String get emptyCart => '购物车为空';

  @override
  String get inputBarcode => '输入商品条码';

  @override
  String get noBarcodeItem => '无条码商品';

  @override
  String get debugScanFile => '调试扫描文件';

  @override
  String get checkout => '去结算';

  @override
  String get unit => '单价: ';

  @override
  String get kioskSettings => '终端设置';

  @override
  String get kioskReadyToSync => '终端已准备好同步';

  @override
  String ipAddressLabel(Object ip, Object port) {
    return 'IP: $ip:$port';
  }

  @override
  String get close => '关闭';

  @override
  String get serverStartFailedTitle => '启动服务失败';

  @override
  String get serverStartFailedMessage => '无法找到有效的IP地址。\n请检查Wi-Fi、热点或移动数据连接。';

  @override
  String get retry => '重试';

  @override
  String get serverNoIp => '启动服务失败：未找到IP地址';

  @override
  String get restoreComplete => '恢复完成';

  @override
  String get returningHome => '正在刷新数据...';
}
