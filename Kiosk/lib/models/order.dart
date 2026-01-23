import 'dart:convert';

class OrderItem {
  final String barcode;
  final String name;
  final double price;
  final int quantity;

  OrderItem({
    required this.barcode,
    required this.name,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      barcode: json['barcode'],
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'],
    );
  }
}

class Order {
  final String id;
  final List<OrderItem> items;
  final double totalAmount;
  final int timestamp;
  final bool synced;
  final int? alipayCheckoutTimeMs;
  final bool alipayNotifyCheckedAmount;
  final String? alipayMatchedKey;
  final int? alipayMatchedPostTimeMs;
  final String? alipayMatchedTitle;
  final String? alipayMatchedText;
  final int? alipayMatchedParsedAmountFen;
  final int? wechatCheckoutTimeMs;
  final bool wechatNotifyCheckedAmount;
  final String? wechatMatchedKey;
  final int? wechatMatchedPostTimeMs;
  final String? wechatMatchedTitle;
  final String? wechatMatchedText;
  final int? wechatMatchedParsedAmountFen;

  Order({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.timestamp,
    this.synced = false,
    this.alipayCheckoutTimeMs,
    this.alipayNotifyCheckedAmount = false,
    this.alipayMatchedKey,
    this.alipayMatchedPostTimeMs,
    this.alipayMatchedTitle,
    this.alipayMatchedText,
    this.alipayMatchedParsedAmountFen,
    this.wechatCheckoutTimeMs,
    this.wechatNotifyCheckedAmount = false,
    this.wechatMatchedKey,
    this.wechatMatchedPostTimeMs,
    this.wechatMatchedTitle,
    this.wechatMatchedText,
    this.wechatMatchedParsedAmountFen,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items': jsonEncode(items.map((i) => i.toJson()).toList()),
      'total_amount': totalAmount,
      'timestamp': timestamp,
      'synced': synced ? 1 : 0,
      'alipay_checkout_time_ms': alipayCheckoutTimeMs,
      'alipay_notify_checked_amount': alipayNotifyCheckedAmount ? 1 : 0,
      'alipay_matched_key': alipayMatchedKey,
      'alipay_matched_post_time_ms': alipayMatchedPostTimeMs,
      'alipay_matched_title': alipayMatchedTitle,
      'alipay_matched_text': alipayMatchedText,
      'alipay_matched_parsed_amount_fen': alipayMatchedParsedAmountFen,
      'wechat_checkout_time_ms': wechatCheckoutTimeMs,
      'wechat_notify_checked_amount': wechatNotifyCheckedAmount ? 1 : 0,
      'wechat_matched_key': wechatMatchedKey,
      'wechat_matched_post_time_ms': wechatMatchedPostTimeMs,
      'wechat_matched_title': wechatMatchedTitle,
      'wechat_matched_text': wechatMatchedText,
      'wechat_matched_parsed_amount_fen': wechatMatchedParsedAmountFen,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'],
      items: (jsonDecode(map['items']) as List)
          .map((i) => OrderItem.fromJson(i))
          .toList(),
      totalAmount: (map['total_amount'] as num).toDouble(),
      timestamp: map['timestamp'],
      synced: (map['synced'] as int) == 1,
      alipayCheckoutTimeMs: map['alipay_checkout_time_ms'],
      alipayNotifyCheckedAmount: (map['alipay_notify_checked_amount'] ?? 0) == 1,
      alipayMatchedKey: map['alipay_matched_key'],
      alipayMatchedPostTimeMs: map['alipay_matched_post_time_ms'],
      alipayMatchedTitle: map['alipay_matched_title'],
      alipayMatchedText: map['alipay_matched_text'],
      alipayMatchedParsedAmountFen: map['alipay_matched_parsed_amount_fen'],
      wechatCheckoutTimeMs: map['wechat_checkout_time_ms'],
      wechatNotifyCheckedAmount: (map['wechat_notify_checked_amount'] ?? 0) == 1,
      wechatMatchedKey: map['wechat_matched_key'],
      wechatMatchedPostTimeMs: map['wechat_matched_post_time_ms'],
      wechatMatchedTitle: map['wechat_matched_title'],
      wechatMatchedText: map['wechat_matched_text'],
      wechatMatchedParsedAmountFen: map['wechat_matched_parsed_amount_fen'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((i) => i.toJson()).toList(),
      'total_amount': totalAmount,
      'timestamp': timestamp,
      'synced': synced,
      'alipay_checkout_time_ms': alipayCheckoutTimeMs,
      'alipay_notify_checked_amount': alipayNotifyCheckedAmount,
      'alipay_matched_key': alipayMatchedKey,
      'alipay_matched_post_time_ms': alipayMatchedPostTimeMs,
      'alipay_matched_title': alipayMatchedTitle,
      'alipay_matched_text': alipayMatchedText,
      'alipay_matched_parsed_amount_fen': alipayMatchedParsedAmountFen,
      'wechat_checkout_time_ms': wechatCheckoutTimeMs,
      'wechat_notify_checked_amount': wechatNotifyCheckedAmount,
      'wechat_matched_key': wechatMatchedKey,
      'wechat_matched_post_time_ms': wechatMatchedPostTimeMs,
      'wechat_matched_title': wechatMatchedTitle,
      'wechat_matched_text': wechatMatchedText,
      'wechat_matched_parsed_amount_fen': wechatMatchedParsedAmountFen,
    };
  }
}
