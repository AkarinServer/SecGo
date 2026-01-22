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

  Order({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.timestamp,
    this.synced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items': jsonEncode(items.map((i) => i.toJson()).toList()),
      'total_amount': totalAmount,
      'timestamp': timestamp,
      'synced': synced ? 1 : 0,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((i) => i.toJson()).toList(),
      'total_amount': totalAmount,
      'timestamp': timestamp,
      'synced': synced,
    };
  }
}
