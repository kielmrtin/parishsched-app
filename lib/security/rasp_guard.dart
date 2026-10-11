import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freerasp/freerasp.dart';

import '../theme/app_theme.dart';

/// Runtime app self-protection via freeRASP (Talsec): detects a modified /
/// re-signed APK, hooking frameworks (Frida, Xposed), an attached debugger,
/// rooted phones and emulators (MASVS-RESILIENCE).
///
/// Response policy:
///  * tampered app, hooking, debugger -> the app refuses to run;
///  * rooted phone / emulator          -> one-time warning, then continues
///    (some parishioners' phones are rooted; blocking them outright would
///    lock them out of booking entirely).
/// Sideloading itself is expected (the APK is downloaded from the parish
/// website, not a store), so "unofficial store" is deliberately ignored.
class RaspGuard {
  RaspGuard._();

  /// Set when the app must stop running; shown full-screen by [RaspGate].
  static final blockReason = ValueNotifier<String?>(null);

  /// Set when the device is rooted or an emulator; shown once as a warning.
  static final riskWarning = ValueNotifier<String?>(null);

  static const _packageName = 'org.stjohnbaptistparish.parishsched';
  // Base64 SHA-256 of the release signing certificate
  // (C:\Users\Snoopi\parishsched-keys\parishsched-release.jks).
  static const _signingCertHash = 'sPkInuj5iYQkgq+KdAo9I92viyCcY2GFL+COH7OrAOQ=';
  static const _watcherMail = 'security@stjohnbaptistparish.org';

  static Future<void> start() async {
    // Debug builds are signed with the debug key and run under a debugger,
    // so the checks only make sense (and only enforce) in release builds.
    if (!kReleaseMode || defaultTargetPlatform != TargetPlatform.android) return;

    void block(String reason) => blockReason.value ??= reason;
    void warn(String reason) => riskWarning.value ??= reason;

    await Talsec.instance.attachListener(ThreatCallback(
      onAppIntegrity: () => block(
        'This copy of ParishSched has been modified. Please download the '
        'official app from stjohnbaptistparish.org.',
      ),
      onHooks: () => block('A tool that tampers with apps was detected on this phone.'),
      onDebug: () => block('A debugger is attached to the app.'),
      onPrivilegedAccess: () => warn(
        'This phone appears to be rooted. Other apps may be able to read '
        'ParishSched data. Proceed with care.',
      ),
      onSimulator: () => warn('ParishSched is running on an emulator.'),
    ));

    try {
      await Talsec.instance.start(TalsecConfig(
        androidConfig: AndroidConfig(
          packageName: _packageName,
          signingCertHashes: const [_signingCertHash],
        ),
        watcherMail: _watcherMail,
        isProd: true,
      ));
    } on PlatformException catch (e) {
      debugPrint('freeRASP failed to start: ${e.code}');
    }
  }
}

/// Wraps the whole app: replaces it with a full-screen notice when
/// [RaspGuard.blockReason] is set, and shows [RaspGuard.riskWarning] once.
class RaspGate extends StatefulWidget {
  const RaspGate({super.key, required this.child, required this.navigatorKey});

  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<RaspGate> createState() => _RaspGateState();
}

class _RaspGateState extends State<RaspGate> {
  bool _warningShown = false;

  @override
  void initState() {
    super.initState();
    RaspGuard.riskWarning.addListener(_showWarning);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showWarning());
  }

  @override
  void dispose() {
    RaspGuard.riskWarning.removeListener(_showWarning);
    super.dispose();
  }

  void _showWarning() {
    final message = RaspGuard.riskWarning.value;
    final ctx = widget.navigatorKey.currentContext;
    if (message == null || _warningShown || ctx == null) return;
    _warningShown = true;
    showDialog<void>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('Security notice'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('I understand')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: RaspGuard.blockReason,
      builder: (context, reason, child) {
        if (reason == null) return child!;
        return Scaffold(
          backgroundColor: AppColors.brand,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.gpp_bad_outlined, size: 64, color: Colors.white),
                    const SizedBox(height: 20),
                    const Text(
                      'ParishSched cannot run',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      reason,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 14.5, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
