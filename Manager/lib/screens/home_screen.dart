import 'package:flutter/material.dart';
import 'package:manager/screens/product_list_screen.dart';
import 'package:manager/screens/qr_upload_screen.dart';
import 'package:manager/screens/sync_kiosk_screen.dart';
import 'package:manager/screens/settings_screen.dart';
import 'package:manager/l10n/app_localizations.dart';
import 'package:manager/widgets/kiosk_drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.appTitle)),
      drawer: const KioskDrawer(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _MenuButton(
              icon: Icons.add_shopping_cart,
              label: AppLocalizations.of(context)!.addProduct,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductListScreen()),
              ),
            ),
            const SizedBox(height: 20),
            _MenuButton(
              icon: Icons.qr_code_2,
              label: AppLocalizations.of(context)!.uploadQr,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QrUploadScreen()),
              ),
            ),
            const SizedBox(height: 20),
            _MenuButton(
              icon: Icons.sync,
              label: 'Sync Kiosk', // TODO: Add to arb
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SyncKioskScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 100,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
