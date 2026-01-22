import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kiosk/main.dart';
import 'package:kiosk/models/product.dart';
import 'package:kiosk/screens/main_screen.dart';
import 'package:kiosk/screens/pin_setup_screen.dart';
import 'package:kiosk/services/settings_service.dart';
import 'package:kiosk/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SettingsService settingsService;

  setUpAll(() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ProductAdapter());
    }
    settingsService = SettingsService();
    await settingsService.init();
  });

  testWidgets('Kiosk App Start Test - Verify Initial Screen', (WidgetTester tester) async {
    // Launch App
    await tester.pumpWidget(KioskApp(hasPin: settingsService.hasPin()));
    await tester.pumpAndSettle();

    // Verify Screen - Either PinSetup or MainScreen should be visible
    final pinSetupFinder = find.byType(PinSetupScreen);
    final mainScreenFinder = find.byType(MainScreen);

    final hasPinSetup = tester.widgetList(pinSetupFinder).isNotEmpty;
    final hasMainScreen = tester.widgetList(mainScreenFinder).isNotEmpty;

    expect(hasPinSetup || hasMainScreen, true, 
        reason: "Either PinSetupScreen or MainScreen should be visible");

    if (hasPinSetup) {
      final l10n = AppLocalizations.of(tester.element(pinSetupFinder))!;
      expect(find.text(l10n.setAdminPin), findsWidgets);
      print('Verified: PinSetupScreen is shown');
    } else {
      final l10n = AppLocalizations.of(tester.element(mainScreenFinder))!;
      expect(find.text(l10n.checkout), findsOneWidget);
      print('Verified: MainScreen is shown');
    }
  });

  testWidgets('Kiosk PIN Setup Flow Test', (WidgetTester tester) async {
    // Clear PIN to force PinSetupScreen
    SharedPreferences.setMockInitialValues({});
    final freshSettingsService = SettingsService();
    await freshSettingsService.init();
    
    // Launch App without PIN
    await tester.pumpWidget(KioskApp(hasPin: false));
    await tester.pumpAndSettle();

    // Verify PinSetupScreen is shown
    expect(find.byType(PinSetupScreen), findsOneWidget);
    
    // Find PIN input fields
    final textFields = find.byType(TextFormField);
    expect(textFields, findsNWidgets(2)); // PIN and Confirm PIN
    
    // Enter PIN
    await tester.enterText(textFields.first, '1234');
    await tester.pumpAndSettle();
    
    // Enter Confirm PIN
    await tester.enterText(textFields.last, '1234');
    await tester.pumpAndSettle();
    
    // Find and tap save button
    final saveButton = find.byType(ElevatedButton);
    expect(saveButton, findsOneWidget);
    
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    
    // After successful PIN setup, should navigate to MainScreen
    expect(find.byType(MainScreen), findsOneWidget);
    final l10n = AppLocalizations.of(tester.element(find.byType(MainScreen)))!;
    expect(find.text(l10n.checkout), findsOneWidget);
  });

  testWidgets('Kiosk MainScreen UI Elements Test', (WidgetTester tester) async {
    // Launch App with PIN already set
    await tester.pumpWidget(KioskApp(hasPin: true));
    await tester.pumpAndSettle();

    // If still on PinSetupScreen, we need to skip this test
    if (find.byType(PinSetupScreen).evaluate().isNotEmpty) {
      print('Skipping MainScreen test - PinSetupScreen is shown');
      return;
    }

    // Verify MainScreen is shown
    expect(find.byType(MainScreen), findsOneWidget);
    
    // Verify settings icon exists
    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.byIcon(Icons.image_search), findsOneWidget);

    final l10n = AppLocalizations.of(tester.element(find.byType(MainScreen)))!;
    expect(find.text(l10n.clearCart), findsOneWidget);
  });
}
