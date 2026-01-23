import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk/services/payment_notification_watch_service.dart';

void main() {
  group('AlipayAmountParser', () {
    test('parses common success format', () {
      final fen = PaymentNotificationWatchService.parseAlipaySuccessAmountFen(
        '支付宝成功收款0.01元，点击查看。',
      );
      expect(fen, 1);
    });

    test('parses with currency symbol and spaces', () {
      final fen = PaymentNotificationWatchService.parseAlipaySuccessAmountFen(
        '店员通 支付宝成功收款 ￥3.00 元',
      );
      expect(fen, 300);
    });

    test('parses integer amount', () {
      final fen = PaymentNotificationWatchService.parseAlipaySuccessAmountFen(
        '支付宝成功收款3元，点击查看。',
      );
      expect(fen, 300);
    });
  });

  group('WeChatAmountParser', () {
    test('parses 收款到账 format', () {
      final fen = PaymentNotificationWatchService.parseWeChatSuccessAmountFen(
        '微信支付 收款到账￥0.01',
      );
      expect(fen, 1);
    });

    test('parses 收款 with 元', () {
      final fen = PaymentNotificationWatchService.parseWeChatSuccessAmountFen(
        '微信支付收款3元',
      );
      expect(fen, 300);
    });

    test('parses with spaces', () {
      final fen = PaymentNotificationWatchService.parseWeChatSuccessAmountFen(
        '收款 到账 ￥ 12.34',
      );
      expect(fen, 1234);
    });
  });
}
