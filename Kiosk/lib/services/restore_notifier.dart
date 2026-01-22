import 'package:flutter/foundation.dart';

class RestoreNotifier extends ChangeNotifier {
  RestoreNotifier._internal();

  static final RestoreNotifier instance = RestoreNotifier._internal();

  void notifyRestored() => notifyListeners();
}
