import 'package:flutter/material.dart';
import 'package:manager/screens/product_list_screen.dart';
import 'package:manager/screens/qr_upload_screen.dart';
import 'package:manager/screens/kiosk_backup_screen.dart';
import 'package:manager/l10n/app_localizations.dart';
import 'package:manager/widgets/kiosk_drawer.dart';
import 'package:manager/services/kiosk_connection_service.dart';
import 'package:manager/config/store_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final KioskConnectionService _connectionService = KioskConnectionService();

  @override
  void initState() {
    super.initState();
    _connectionService.startMonitoring();
  }

  @override
  void dispose() {
    _connectionService.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _connectionService,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context)!;
        final connectedKiosk = _connectionService.connectedKiosk;
        final isConnected = connectedKiosk != null;
        final storeName = StoreConfig.storeName;
        final titleStyle = Theme.of(context).textTheme.titleMedium;
        final subtitleStyle = Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.appTitle, style: titleStyle),
                Text(storeName, style: subtitleStyle),
              ],
            ),
          ),
          drawer: const KioskDrawer(),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MenuButton(
                  icon: Icons.add_shopping_cart,
                  label: l10n.addProduct,
                  onTap: isConnected
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ProductListScreen()),
                          )
                      : null,
                ),
                const SizedBox(height: 20),
                _MenuButton(
                  icon: Icons.qr_code_2,
                  label: l10n.uploadQr,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QrUploadScreen()),
                  ),
                ),
                const SizedBox(height: 20),
                _MenuButton(
                  icon: Icons.backup,
                  label: l10n.backupRestore,
                  onTap: isConnected
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => KioskBackupScreen(kiosk: connectedKiosk),
                            ),
                          )
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

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
