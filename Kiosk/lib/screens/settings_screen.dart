import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kiosk/services/server/kiosk_server.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:kiosk/l10n/app_localizations.dart';

import 'package:kiosk/services/android_launcher_service.dart';
import 'package:kiosk/services/android_network_service.dart';
import 'package:kiosk/services/settings_service.dart';
import 'package:kiosk/services/restore_notifier.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final KioskServerService _serverService;
  final TextEditingController _pinController = TextEditingController();
  final SettingsService _settingsService = SettingsService(); // Add SettingsService
  final AndroidLauncherService _launcherService = AndroidLauncherService();
  final AndroidNetworkService _networkService = AndroidNetworkService();
  bool _isServerRunning = false;
  bool _isLoading = false;
  bool _showRestoreComplete = false;
  String? _qrData;
  String? _homeAppPackage;
  String? _homeAppLabel;
  bool _hotspotEnabled = false;
  bool _mobileDataEnabled = false;
  String? _hotspotSsid;
  String? _hotspotPassword;
  bool _networkBusy = false;

  @override
  void initState() {
    super.initState();
    _serverService = KioskServerService(onRestoreComplete: _onRestoreComplete);
    _homeAppPackage = _settingsService.getHomeAppPackage();
    _homeAppLabel = _settingsService.getHomeAppLabel();
    // Pre-fill PIN if available
    final savedPin = _settingsService.getPin();
    if (savedPin != null) {
      _pinController.text = savedPin;
      // Auto-start server if PIN is available
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startServer();
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNetworkState();
    });
  }

  @override
  void dispose() {
    _serverService.stopServer();
    _pinController.dispose();
    super.dispose();
  }

  Future<bool> _confirmPin() async {
    final l10n = AppLocalizations.of(context)!;
    final expected = _settingsService.getPin() ?? _pinController.text.trim();
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.adminConfirm),
          content: TextField(
            controller: controller,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.enterPin),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim() == expected) {
                  Navigator.pop(context, true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.invalidPin)),
                  );
                }
              },
              child: Text(l10n.confirm),
            ),
          ],
        );
      },
    );
    return ok ?? false;
  }

  Future<void> _pickHomeApp() async {
    final l10n = AppLocalizations.of(context)!;
    final apps = await _launcherService.listLaunchableApps();
    apps.sort((a, b) {
      final al = (a['label'] ?? a['packageName'] ?? '').toLowerCase();
      final bl = (b['label'] ?? b['packageName'] ?? '').toLowerCase();
      return al.compareTo(bl);
    });

    if (!mounted) return;
    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (context) {
        var query = '';
        final searchController = TextEditingController();
        return StatefulBuilder(
          builder: (context, setState) {
            final filtered = query.isEmpty
                ? apps
                : apps.where((e) {
                    final label = (e['label'] ?? '').toLowerCase();
                    final pkg = (e['packageName'] ?? '').toLowerCase();
                    final q = query.toLowerCase();
                    return label.contains(q) || pkg.contains(q);
                  }).toList();

            return AlertDialog(
              title: Text(l10n.homeAppTitle),
              content: SizedBox(
                width: 520,
                height: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: l10n.searchApps,
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (v) => setState(() => query = v.trim()),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(child: Text(l10n.noAppsFound))
                          : ListView.builder(
                              itemCount: filtered.length + 1,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  final selected = _homeAppPackage == null;
                                  return ListTile(
                                    leading: const Icon(Icons.home_outlined),
                                    title: Text(l10n.launcherDefault),
                                    trailing: selected ? const Icon(Icons.check) : null,
                                    onTap: () => Navigator.pop(context, {'packageName': '', 'label': ''}),
                                  );
                                }
                                final app = filtered[index - 1];
                                final pkg = app['packageName'] ?? '';
                                final label = app['label'] ?? pkg;
                                final selected = _homeAppPackage == pkg;
                                return ListTile(
                                  title: Text(label),
                                  subtitle: Text(pkg),
                                  trailing: selected ? const Icon(Icons.check) : null,
                                  onTap: () => Navigator.pop(context, {'packageName': pkg, 'label': label}),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: Text(l10n.cancel),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (result == null) return;
    final pkg = (result['packageName'] ?? '').trim();
    final label = (result['label'] ?? '').trim();
    if (pkg.isEmpty) {
      await _settingsService.clearHomeAppSelection();
      if (!mounted) return;
      setState(() {
        _homeAppPackage = null;
        _homeAppLabel = null;
      });
      return;
    }
    await _settingsService.setHomeAppPackage(pkg);
    await _settingsService.setHomeAppLabel(label.isEmpty ? pkg : label);
    if (!mounted) return;
    setState(() {
      _homeAppPackage = pkg;
      _homeAppLabel = label.isEmpty ? pkg : label;
    });
  }

  Future<void> _openLauncher() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await _confirmPin();
    if (!ok) return;

    await _settingsService.setPendingPaymentOrderId(null);

    final pkg = _settingsService.getHomeAppPackage();
    bool launched = false;
    if (pkg != null && pkg.isNotEmpty) {
      launched = await _launcherService.openApp(pkg);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.homeAppOpenFailed(pkg))),
        );
      }
    }
    if (!launched) {
      await _launcherService.openLauncherHome();
    }

    if (!mounted) return;
    Navigator.pop(context, 'reset');
  }

  Widget _buildLauncherSection() {
    final l10n = AppLocalizations.of(context)!;
    final target = _homeAppLabel ?? _homeAppPackage ?? l10n.launcherDefault;
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: Text(l10n.openLauncher),
            subtitle: Text(l10n.launcherTarget(target)),
            onTap: _openLauncher,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.apps_outlined),
            title: Text(l10n.homeAppTitle),
            subtitle: Text(_homeAppLabel ?? _homeAppPackage ?? l10n.homeAppNotSet),
            onTap: _pickHomeApp,
          ),
        ],
      ),
    );
  }

  void _onRestoreComplete() {
    if (_showRestoreComplete) return;
    _runRestoreCompleteFlow();
  }

  Future<void> _runRestoreCompleteFlow() async {
    if (!mounted) return;
    RestoreNotifier.instance.notifyRestored();
    setState(() => _showRestoreComplete = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _showRestoreComplete = false);
  }

  Future<void> _loadNetworkState() async {
    try {
      final hotspotInfo = await _networkService.getHotspotInfo();
      final mobile = await _networkService.getMobileDataEnabled();
      if (!mounted) return;
      setState(() {
        _hotspotEnabled = hotspotInfo.enabled;
        _hotspotSsid = hotspotInfo.ssid;
        _hotspotPassword = hotspotInfo.password;
        _mobileDataEnabled = mobile;
      });
    } catch (_) {
    }
  }

  Future<void> _setHotspot(bool enabled) async {
    final l10n = AppLocalizations.of(context)!;
    if (enabled) {
      final status = await Permission.location.status;
      if (!status.isGranted) {
        final next = await Permission.location.request();
        if (!next.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.locationPermissionRequired)),
            );
          }
          return;
        }
      }
    }
    setState(() => _networkBusy = true);
    try {
      final ok = await _networkService.setHotspotEnabled(enabled);
      if (!ok) {
        final err = await _networkService.getHotspotLastError();
        final message = (err['message'] ?? '').toString();
        if (message == 'location_disabled') {
          await _networkService.openLocationSettings();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.locationServiceRequired)),
            );
          }
          return;
        }
        await _networkService.openHotspotSettings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                message.isEmpty ? l10n.networkToggleFailed : l10n.hotspotFailedWithReason(message),
              ),
            ),
          );
        }
      }
    } catch (_) {
      try {
        await _networkService.openHotspotSettings();
      } catch (_) {
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.networkToggleFailed)),
        );
      }
    } finally {
      await _loadNetworkState();
      if (mounted) setState(() => _networkBusy = false);
    }
  }

  Future<void> _setMobileData(bool enabled) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _networkBusy = true);
    try {
      final ok = await _networkService.setMobileDataEnabled(enabled);
      if (!ok) {
        await _networkService.openInternetSettings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.networkToggleFailed)),
          );
        }
      }
    } catch (_) {
      try {
        await _networkService.openInternetSettings();
      } catch (_) {
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.networkToggleFailed)),
        );
      }
    } finally {
      await _loadNetworkState();
      if (mounted) setState(() => _networkBusy = false);
    }
  }

  Widget _buildNetworkSection() {
    final l10n = AppLocalizations.of(context)!;
    final hotspotSubtitle = _hotspotEnabled && _hotspotSsid != null
        ? '${l10n.hotspotHint}\n${l10n.ssidLabel}: ${_hotspotSsid ?? '-'}\n${l10n.passwordLabel}: ${_hotspotPassword ?? '-'}'
        : l10n.hotspotHint;
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.wifi_tethering_outlined),
            title: Text(l10n.networkSettings),
          ),
          const Divider(height: 1),
          SwitchListTile(
            value: _hotspotEnabled,
            onChanged: _networkBusy ? null : _setHotspot,
            title: Text(l10n.hotspot),
            subtitle: Text(hotspotSubtitle),
          ),
          const Divider(height: 1),
          SwitchListTile(
            value: _mobileDataEnabled,
            onChanged: _networkBusy ? null : _setMobileData,
            title: Text(l10n.mobileData),
            subtitle: Text(l10n.mobileDataHint),
          ),
        ],
      ),
    );
  }

  Future<void> _startServer() async {
    final l10n = AppLocalizations.of(context)!;
    if (_pinController.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pinLength)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final deviceId = await _settingsService.getOrCreateDeviceId();
    await _serverService.startServer(_pinController.text, deviceId: deviceId);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (_serverService.ipAddress != null) {
          _isServerRunning = true;
          // QR Data format: {"ip": "192.168.x.x", "port": 8081, "pin": "1234"}
          _qrData = jsonEncode({
            'ip': _serverService.ipAddress,
            'port': _serverService.port,
            'pin': _pinController.text,
            'deviceId': deviceId,
          });
        } else {
           // Optional: Show error if IP is null (e.g. no wifi)
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.serverNoIp)),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.kioskSettings)),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: _isLoading 
                ? const CircularProgressIndicator() 
                : _isServerRunning
                  ? SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        Text(
                          l10n.kioskReadyToSync,
                          style: TextStyle(fontSize: 24, color: Colors.green),
                        ),
                        const SizedBox(height: 20),
                        if (_qrData != null)
                          Container(
                            color: Colors.white,
                            padding: const EdgeInsets.all(16),
                            child: QrImageView(
                              data: _qrData!,
                              size: 250,
                            ),
                          ),
                        const SizedBox(height: 20),
                        Text(
                          l10n.ipAddressLabel(
                            _serverService.ipAddress ?? '-',
                            _serverService.port,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildLauncherSection(),
                              const SizedBox(height: 16),
                              _buildNetworkSection(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            // Restart server logic or close page
                            Navigator.pop(context);
                          },
                          child: Text(l10n.close),
                        ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.red),
                        const SizedBox(height: 20),
                        Text(
                          l10n.serverStartFailedTitle,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.serverStartFailedMessage,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildLauncherSection(),
                              const SizedBox(height: 16),
                              _buildNetworkSection(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _startServer,
                          child: Text(l10n.retry),
                        ),
                        ],
                      ),
                    ),
            ),
          ),
          if (_showRestoreComplete)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.65),
                child: Center(
                  child: AnimatedScale(
                    scale: _showRestoreComplete ? 1 : 0.9,
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 96),
                        const SizedBox(height: 16),
                        Text(
                          l10n.restoreComplete,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.returningHome,
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
