import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Blocks screenshots, screen recording and the recent-apps thumbnail while
/// a screen showing personal data is open (Android FLAG_SECURE, toggled in
/// MainActivity.kt). Counted, so nested secure screens (e.g. Login pushing
/// Register) keep it on until the last one closes.
class SecureScreen {
  SecureScreen._();

  static const _channel = MethodChannel('parishsched/secure_screen');
  static int _count = 0;

  static Future<void> _enter() async {
    _count++;
    if (_count == 1) await _channel.invokeMethod('enable');
  }

  static Future<void> _leave() async {
    if (_count == 0) return;
    _count--;
    if (_count == 0) await _channel.invokeMethod('disable');
  }
}

/// Mix into the State of any screen that shows sensitive data.
mixin SecureScreenMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    SecureScreen._enter();
  }

  @override
  void dispose() {
    SecureScreen._leave();
    super.dispose();
  }
}
