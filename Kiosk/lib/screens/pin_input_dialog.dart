import 'package:flutter/material.dart';
import 'package:kiosk/l10n/app_localizations.dart';

class PinInputDialog extends StatefulWidget {
  final String? expectedPin;

  const PinInputDialog({
    super.key,
    this.expectedPin,
  });

  @override
  State<PinInputDialog> createState() => _PinInputDialogState();
}

class _PinInputDialogState extends State<PinInputDialog> {
  String _input = '';

  void _onKeyTap(String key) {
    if (_input.length >= 6) return;
    setState(() {
      _input += key;
    });
  }

  void _onBackspace() {
    if (_input.isNotEmpty) {
      setState(() {
        _input = _input.substring(0, _input.length - 1);
      });
    }
  }

  void _onClear() {
    setState(() {
      _input = '';
    });
  }

  void _onConfirm() {
    if (widget.expectedPin != null) {
      if (_input == widget.expectedPin) {
        Navigator.pop(context, true);
      } else {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(l10n.invalidPin)),
        );
        _onClear();
      }
    } else {
      Navigator.pop(context, _input);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Text(
                l10n.adminConfirm,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(l10n.enterPin, style: const TextStyle(color: Colors.grey)),
              const Divider(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _input.isEmpty ? '----' : '*' * _input.length,
                  style: TextStyle(
                    fontSize: 32,
                    color: _input.isEmpty ? Colors.grey : Colors.black,
                    letterSpacing: 8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 240,
                child: GridView.count(
                  crossAxisCount: 3,
                  childAspectRatio: 2.35,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (var i = 1; i <= 9; i++) _buildKey(i.toString()),
                    _buildBackspaceKey(),
                    _buildKey('0'),
                    _buildActionButton(l10n.clear, Colors.orange, _onClear),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      l10n.cancel,
                      Colors.grey,
                      () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _buildActionButton(l10n.confirm, Colors.blue, _onConfirm)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceKey() {
    return InkWell(
      onTap: _onBackspace,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.backspace, size: 24),
      ),
    );
  }

  Widget _buildKey(String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () => _onKeyTap(label),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 2,
              offset: const Offset(1, 1),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
