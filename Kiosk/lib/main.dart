import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:kiosk/models/product.dart';
import 'package:kiosk/screens/main_screen.dart';
import 'package:kiosk/screens/pin_setup_screen.dart';
import 'package:kiosk/services/settings_service.dart';
import 'package:kiosk/l10n/app_localizations.dart';
import 'package:kiosk/widgets/screen_saver.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(ProductAdapter());
  
  final settingsService = SettingsService();
  await settingsService.init();

  // Set preferred orientations to landscape for Kiosk
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable Wakelock to keep screen always on
  WakelockPlus.enable();

  runApp(KioskApp(hasPin: settingsService.hasPin()));
}

class KioskApp extends StatelessWidget {
  final bool hasPin;

  const KioskApp({super.key, required this.hasPin});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      themeMode: ThemeMode.system,
      builder: (context, child) {
        return ScreenSaver(child: child!);
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark, // OLED optimization
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black, // Pure black for OLED
      ),
      home: hasPin ? const MainScreen() : const PinSetupScreen(),
    );
  }
}
