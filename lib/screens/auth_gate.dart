import 'package:flutter/material.dart';
import '../security/update_check.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'welcome_screen.dart';

/// Decides where to land on app start: skips straight to Home if there's
/// already a valid, non-disabled session (mirrors CheckCustomerStatus).
/// There's deliberately no splash of our own: the launcher's app-opening
/// card is the only launch visual, and this just shows the brand maroon
/// for the brief moment the session check takes.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checking = true;
  bool _signedIn = false;
  bool _started = false;
  // Set when this build is older than the website's app-version.json allows.
  String? _updateUrl;

  static const _backgroundColor = Color(0xFF6E1B29);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _start();
  }

  Future<void> _start() async {
    await Future.wait([
      _runAuthCheck(),
      UpdateCheck.requiredUpdateUrl().then((url) => _updateUrl = url),
      // WelcomeScreen's full-bleed photo is decoded first so the fade into
      // it doesn't stutter on a decode mid-transition.
      precacheImage(const AssetImage('assets/images/welcome_bg.jpg'), context),
      precacheImage(const AssetImage('assets/images/welcome_logo.jpg'), context),
    ]);
    if (mounted) setState(() => _checking = false);
  }

  Future<void> _runAuthCheck() async {
    final auth = AuthService();
    if (auth.currentSession != null) {
      final profile = await auth.refreshProfileOrSignOut();
      _signedIn = profile != null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget child = _checking
        ? const SizedBox.expand()
        : _updateUrl != null
            ? UpdateRequiredScreen(downloadUrl: _updateUrl!)
            : (_signedIn ? const HomeScreen() : const WelcomeScreen());
    // Maroon backing so the wait and the fade-in never show Flutter's
    // default black canvas.
    return ColoredBox(
      color: _backgroundColor,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOut,
        child: child,
      ),
    );
  }
}
