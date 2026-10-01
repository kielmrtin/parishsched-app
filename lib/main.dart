import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/auth_gate.dart';
import 'screens/reset_password_screen.dart';
import 'theme/app_theme.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );
  runApp(const ParishSchedApp());
}

class ParishSchedApp extends StatefulWidget {
  const ParishSchedApp({super.key});

  @override
  State<ParishSchedApp> createState() => _ParishSchedAppState();
}

class _ParishSchedAppState extends State<ParishSchedApp> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    // Fires once supabase_flutter catches the parishsched://reset-callback
    // deep link and exchanges it for a recovery session.
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        final context = navigatorKey.currentContext;
        if (context != null) {
          // Fetched fresh from the global key in this same synchronous
          // callback (not held across an await), so it can't go stale here.
          // ignore: use_build_context_synchronously
          showResetPasswordDialog(context);
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'ParishSched',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AuthGate(),
    );
  }
}
