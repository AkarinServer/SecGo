import 'package:manager/models/product.dart';
import 'package:manager/services/middleware/product_middleware.dart';

class UniversalProductMiddleware implements ProductMiddleware {
  @override
  Product? parse(String barcode, Map<String, dynamic> json) {
    // Check for success status (API uses "200" string)
    if (json['status'] == "200") {
      return Product(
        barcode: json['Barcode'] ?? barcode,
        name: json['ItemName'] ?? 'Unknown',
        price: 0.0, // Price is not in the API response, user must set it manually
        lastUpdated: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        brand: json['BrandName'],
        size: json['ItemSpecification'],
        type: json['ItemClassName'], // e.g., "即饮型调味饮料"
      );
    }
    return null;
  }
}
