import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manager/main.dart';
import 'package:manager/models/product.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:manager/screens/product_list_screen.dart';
import 'package:manager/screens/qr_upload_screen.dart';
import 'package:manager/l10n/app_localizations.dart';
import 'package:manager/screens/home_screen.dart';
import 'package:manager/services/kiosk_connection_service.dart';
import 'package:manager/models/kiosk.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockKioskConnectionService mockConnectionService;

  setUpAll(() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
       Hive.registerAdapter(ProductAdapter());
    }
    
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint('Warning: .env not loaded: $e');
    }

    mockConnectionService = MockKioskConnectionService();
    KioskConnectionService.mockInstance = mockConnectionService;
  });

  tearDownAll(() {
    KioskConnectionService.mockInstance = null;
  });

  testWidgets('Manager App Navigation Test - Product List', (WidgetTester tester) async {
    // 1. Pump App
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(tester.element(find.byType(HomeScreen)))!;

    // 2. Verify Home Screen Buttons
    final addProductBtn = find.byIcon(Icons.add_shopping_cart);
    expect(addProductBtn, findsOneWidget);
    expect(find.byIcon(Icons.qr_code_2), findsOneWidget);
    expect(find.text(l10n.addProduct), findsOneWidget);

    // 3. Navigate to Product List
    await tester.tap(addProductBtn);
    await tester.pumpAndSettle();

    // 4. Verify Product List Screen
    expect(find.byType(ProductListScreen), findsOneWidget);
    
    // 5. Go Back
    final backTooltip = MaterialLocalizations.of(
      tester.element(find.byType(Scaffold)),
    ).backButtonTooltip;
    Finder backBtn = find.byTooltip(backTooltip);
    if (!tester.any(backBtn)) {
      backBtn = find.byIcon(Icons.arrow_back);
    }
    if (!tester.any(backBtn)) {
      backBtn = find.byIcon(Icons.arrow_back_ios);
    }
    
    if (tester.any(backBtn)) {
      await tester.tap(backBtn);
    } else {
      await tester.pageBack();
    }
    await tester.pumpAndSettle();
    
    // 6. Verify Home Screen Again
    expect(find.byType(ProductListScreen), findsNothing);
    expect(addProductBtn, findsOneWidget);
  });

  testWidgets('Manager App Navigation Test - QR Upload', (WidgetTester tester) async {
    // 1. Pump App
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(tester.element(find.byType(HomeScreen)))!;

    // 2. Find and tap QR upload button
    final qrUploadBtn = find.byIcon(Icons.qr_code_2);
    expect(qrUploadBtn, findsOneWidget);
    expect(find.text(l10n.uploadQr), findsOneWidget);
    
    await tester.tap(qrUploadBtn);
    await tester.pumpAndSettle();

    // 3. Verify QR Upload Screen
    expect(find.byType(QrUploadScreen), findsOneWidget);
    
    // 4. Verify key UI elements on QR screen
    expect(find.byIcon(Icons.image), findsOneWidget); // Select image button icon
    expect(find.text(l10n.selectImage), findsOneWidget);
    expect(find.text(l10n.uploadToServer), findsOneWidget);
    
    // 5. Go Back
    final backTooltip = MaterialLocalizations.of(
      tester.element(find.byType(Scaffold)),
    ).backButtonTooltip;
    Finder backBtn = find.byTooltip(backTooltip);
    if (!tester.any(backBtn)) {
      backBtn = find.byIcon(Icons.arrow_back);
    }
    if (!tester.any(backBtn)) {
      backBtn = find.byIcon(Icons.arrow_back_ios);
    }
    
    if (tester.any(backBtn)) {
      await tester.tap(backBtn);
    } else {
      await tester.pageBack();
    }
    await tester.pumpAndSettle();
    
    // 6. Verify Home Screen Again
    expect(find.byType(QrUploadScreen), findsNothing);
    expect(qrUploadBtn, findsOneWidget);
  });
}

class MockKioskConnectionService extends KioskConnectionService {
  MockKioskConnectionService() : super.testing();

  final Kiosk _kiosk = Kiosk(
    id: 1,
    ip: '127.0.0.1',
    port: 8081,
    pin: '1234',
    name: 'Mock Kiosk',
    lastSynced: 0,
    deviceId: 'test-device',
  );

  @override
  List<Kiosk> get kiosks => [_kiosk];

  @override
  bool get hasConnectedKiosk => true;

  @override
  Kiosk? get connectedKiosk => _kiosk;

  @override
  bool isKioskConnected(int id) => id == _kiosk.id;

  @override
  void startMonitoring() {}

  @override
  void stopMonitoring() {}

  @override
  Future<void> refresh() async {}
}
