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

  Order({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.timestamp,
    this.synced = false,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      items: (json['items'] as List)
          .map((i) => OrderItem.fromJson(i))
          .toList(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      timestamp: json['timestamp'],
      synced: json['synced'] == true || json['synced'] == 1,
    );
  }
}
