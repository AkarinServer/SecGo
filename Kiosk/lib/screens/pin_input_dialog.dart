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
              const Divider(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
              const SizedBox(height: 16),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _buildRow(['1', '2', '3']),
                          const SizedBox(height: 10),
                          _buildRow(['4', '5', '6']),
                          const SizedBox(height: 10),
                          _buildRow(['7', '8', '9']),
                          const SizedBox(height: 10),
                          _buildBottomRow(l10n),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(List<String> labels) {
    return Expanded(
      child: Row(
        children: [
          Expanded(child: _buildKey(labels[0])),
          const SizedBox(width: 10),
          Expanded(child: _buildKey(labels[1])),
          const SizedBox(width: 10),
          Expanded(child: _buildKey(labels[2])),
        ],
      ),
    );
  }

  Widget _buildBottomRow(AppLocalizations l10n) {
    return Expanded(
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _onBackspace,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.backspace, size: 28),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: _buildKey('0')),
          const SizedBox(width: 10),
          Expanded(child: _buildActionButton(l10n.clear, Colors.orange, _onClear)),
        ],
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
        child: Text(label, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
