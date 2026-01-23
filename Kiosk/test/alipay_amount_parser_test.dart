import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk/services/alipay_payment_watch_service.dart';

void main() {
  group('AlipayAmountParser', () {
    test('parses common success format', () {
      final fen = AlipayPaymentWatchService.parseSuccessAmountFen(
        '支付宝成功收款0.01元，点击查看。',
      );
      expect(fen, 1);
    });

    test('parses with currency symbol and spaces', () {
      final fen = AlipayPaymentWatchService.parseSuccessAmountFen(
        '店员通 支付宝成功收款 ￥3.00 元',
      );
      expect(fen, 300);
    });

    test('parses integer amount', () {
      final fen = AlipayPaymentWatchService.parseSuccessAmountFen(
        '支付宝成功收款3元，点击查看。',
      );
      expect(fen, 300);
    });
  });
}

