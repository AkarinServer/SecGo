import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 0)
class Product {
  @HiveField(0)
  final String barcode;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final double price;
  @HiveField(3)
  final int lastUpdated;
  @HiveField(4)
  final String? brand;
  @HiveField(5)
  final String? size;
  @HiveField(6)
  final String? type;
  @HiveField(7)
  final String? pinyin;
  @HiveField(8)
  final String? initials;

  Product({
    required this.barcode,
    required this.name,
    required this.price,
    required this.lastUpdated,
    this.brand,
    this.size,
    this.type,
    this.pinyin,
    this.initials,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      barcode: json['barcode'],
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      lastUpdated: json['last_updated'] ?? 0,
      brand: json['brand'],
      size: json['size'],
      type: json['type'],
      pinyin: json['pinyin'],
      initials: json['initials'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'name': name,
      'price': price,
      'last_updated': lastUpdated,
      'brand': brand,
      'size': size,
      'type': type,
      'pinyin': pinyin,
      'initials': initials,
    };
  }
}
