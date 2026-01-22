import 'package:flutter_dotenv/flutter_dotenv.dart';

class StoreConfig {
  static String get storeName =>
      dotenv.env['STORE_NAME']?.trim().isNotEmpty == true
          ? dotenv.env['STORE_NAME']!.trim()
          : 'YOUR_STORE_NAME';
}
