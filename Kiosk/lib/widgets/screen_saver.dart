import 'dart:async';
import 'package:flutter/material.dart';

class ScreenSaver extends StatefulWidget {
  final Widget child;
  final Duration timeout;

  const ScreenSaver({
    super.key,
    required this.child,
    this.timeout = const Duration(minutes: 3),
  });

  @override
  State<ScreenSaver> createState() => _ScreenSaverState();
}

class _ScreenSaverState extends State<ScreenSaver> {
  Timer? _timer;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resetTimer() {
    _timer?.cancel();
    if (_isActive) return; // Don't restart timer if already active (waiting for tap)

    _timer = Timer(widget.timeout, () {
      setState(() {
        _isActive = true;
      });
    });
  }

  void _wakeUp() {
    setState(() {
      _isActive = false;
    });
    _resetTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _resetTimer(),
      onPointerHover: (_) => _resetTimer(),
      onPointerMove: (_) => _resetTimer(),
      child: Stack(
        children: [
          widget.child,
          if (_isActive)
            Positioned.fill(
              child: GestureDetector(
                onTap: _wakeUp,
                onPanDown: (_) => _wakeUp(), // Catch all touches
                behavior: HitTestBehavior.opaque, // Catch all events
                child: Container(
                  color: Colors.black,
                  // Optional: Add a subtle hint or logo if needed, but user asked for black
                ),
              ),
            ),
        ],
      ),
    );
  }
}
