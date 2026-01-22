import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manager/screens/product_list_screen.dart';
import 'package:manager/services/kiosk_connection_service.dart';
import 'package:manager/models/product.dart';
import 'package:manager/db/database_helper.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:manager/l10n/app_localizations.dart';

// Mock KioskConnectionService
class MockKioskConnectionService extends KioskConnectionService {
  MockKioskConnectionService() : super.testing();

  bool _hasConnected = false;

  @override
  bool get hasConnectedKiosk => _hasConnected;

  void setConnected(bool value) {
    _hasConnected = value;
    notifyListeners();
  }
  
  @override
  void startMonitoring() {} // No-op
  
  @override
  void stopMonitoring() {} // No-op
}

// Mock DatabaseHelper
class MockDatabaseHelper extends DatabaseHelper {
  MockDatabaseHelper() : super.testing();

  @override
  Future<List<Product>> getAllProducts() async {
    return [];
  }
}

void main() {
  late MockKioskConnectionService mockService;

  setUp(() async {
    // Setup Mock Database
    DatabaseHelper.mockInstance = MockDatabaseHelper();

    // Setup Mock Service
    mockService = MockKioskConnectionService();
    KioskConnectionService.mockInstance = mockService;
  });

  tearDown(() {
    KioskConnectionService.mockInstance = null;
    DatabaseHelper.mockInstance = null;
  });

  testWidgets('FAB is hidden when Kiosk is disconnected', (WidgetTester tester) async {
    // Given disconnected
    mockService.setConnected(false);

    // Pump Widget
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ProductListScreen(),
    ));
    
    // Allow DB Future to settle (it might error out, but we care about FAB)
    await tester.pumpAndSettle();

    // Then
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('FAB is visible when Kiosk is connected', (WidgetTester tester) async {
    // Given connected
    mockService.setConnected(true);

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ProductListScreen(),
    ));
    
    await tester.pumpAndSettle();

    // Then
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
