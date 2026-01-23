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
  final bool alipayNotifyCheckedAmount;
  final bool wechatNotifyCheckedAmount;

  Order({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.timestamp,
    this.synced = false,
    this.alipayNotifyCheckedAmount = false,
    this.wechatNotifyCheckedAmount = false,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    bool asBool(Object? v) {
      if (v == null) return false;
      if (v is bool) return v;
      if (v is num) return v != 0;
      final s = v.toString().trim().toLowerCase();
      if (s == 'true') return true;
      final n = num.tryParse(s);
      if (n != null) return n != 0;
      return false;
    }

    return Order(
      id: json['id'],
      items: (json['items'] as List)
          .map((i) => OrderItem.fromJson(i))
          .toList(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      timestamp: json['timestamp'],
      synced: json['synced'] == true || json['synced'] == 1,
      alipayNotifyCheckedAmount: asBool(json['alipay_notify_checked_amount']),
      wechatNotifyCheckedAmount: asBool(json['wechat_notify_checked_amount']),
    );
  }
}
