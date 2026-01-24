import 'package:flutter/material.dart';
import 'package:kiosk/screens/main_screen.dart';
import 'package:kiosk/services/settings_service.dart';
import 'package:kiosk/l10n/app_localizations.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final SettingsService _settingsService = SettingsService();
  String _pin = '';
  String _confirmPin = '';
  bool _editingConfirm = false;

  void _onKeyTap(String key) {
    final value = _editingConfirm ? _confirmPin : _pin;
    if (value.length >= 6) return;
    setState(() {
      if (_editingConfirm) {
        _confirmPin += key;
      } else {
        _pin += key;
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (_editingConfirm) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      } else {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      }
    });
  }

  void _onClear() {
    setState(() {
      if (_editingConfirm) {
        _confirmPin = '';
      } else {
        _pin = '';
      }
    });
  }

  Future<void> _savePin() async {
    final l10n = AppLocalizations.of(context)!;
    if (_pin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pinRequired)),
      );
      return;
    }
    if (_pin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pinLength)),
      );
      return;
    }
    if (_confirmPin != _pin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pinMismatch)),
      );
      return;
    }

    await _settingsService.setPin(_pin);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.setupPin),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.setAdminPin,
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.pinDescription,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _PinDisplay(
                label: l10n.enterPin,
                value: _pin,
                selected: !_editingConfirm,
                icon: Icons.lock,
                onTap: () => setState(() => _editingConfirm = false),
              ),
              const SizedBox(height: 12),
              _PinDisplay(
                label: l10n.confirmPin,
                value: _confirmPin,
                selected: _editingConfirm,
                icon: Icons.lock_outline,
                onTap: () => setState(() => _editingConfirm = true),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 320,
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: _PinKey(label: '1', onTap: () => _onKeyTap('1'))),
                          const SizedBox(width: 10),
                          Expanded(child: _PinKey(label: '2', onTap: () => _onKeyTap('2'))),
                          const SizedBox(width: 10),
                          Expanded(child: _PinKey(label: '3', onTap: () => _onKeyTap('3'))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: _PinKey(label: '4', onTap: () => _onKeyTap('4'))),
                          const SizedBox(width: 10),
                          Expanded(child: _PinKey(label: '5', onTap: () => _onKeyTap('5'))),
                          const SizedBox(width: 10),
                          Expanded(child: _PinKey(label: '6', onTap: () => _onKeyTap('6'))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: _PinKey(label: '7', onTap: () => _onKeyTap('7'))),
                          const SizedBox(width: 10),
                          Expanded(child: _PinKey(label: '8', onTap: () => _onKeyTap('8'))),
                          const SizedBox(width: 10),
                          Expanded(child: _PinKey(label: '9', onTap: () => _onKeyTap('9'))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _PinKey(
                              onTap: _onBackspace,
                              child: const Icon(Icons.backspace, size: 28),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: _PinKey(label: '0', onTap: () => _onKeyTap('0'))),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _PinKey(
                              label: l10n.clear,
                              color: Colors.orange,
                              textStyle: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              onTap: _onClear,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _savePin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  l10n.saveAndContinue,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinDisplay extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  const _PinDisplay({
    required this.label,
    required this.value,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = selected ? theme.colorScheme.primary : Colors.grey;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? theme.colorScheme.primary : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value.isEmpty ? '----' : '*' * value.length,
                    style: const TextStyle(fontSize: 22, letterSpacing: 4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinKey extends StatelessWidget {
  final String? label;
  final Widget? child;
  final VoidCallback onTap;
  final Color? color;
  final TextStyle? textStyle;

  const _PinKey({
    this.label,
    this.child,
    required this.onTap,
    this.color,
    this.textStyle,
  }) : assert(label != null || child != null);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: color ?? Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          boxShadow: color == null
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 2,
                    offset: const Offset(1, 1),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: child ??
            Text(
              label!,
              style: textStyle ?? const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
      ),
    );
  }
}
