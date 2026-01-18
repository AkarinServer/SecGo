import 'package:manager/models/product.dart';

abstract class ProductMiddleware {
  /// Parses the raw JSON response from an API into a [Product] object.
  /// Returns null if parsing fails or the product is invalid.
  Product? parse(String barcode, Map<String, dynamic> json);
}
