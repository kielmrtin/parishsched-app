import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand colors pulled from church-web's own CSS (resources/views/layouts/app.blade.php,
/// auth/login.blade.php, auth/register.blade.php) so the app matches the website.
class AppColors {
  static const brand = Color(0xFFDC2626);
  static const brandDeep = Color(0xFFB91C1C);
  static const ink = Color(0xFF1E2430);
  static const inkSoft = Color(0xFF635C5C);
  static const border = Color(0xFFE3DEDE);
  static const scaffold = Color(0xFFF6F4F1);

  /// Dark red photo tint used on the Welcome/Login/Register hero photos,
  /// dark enough to keep white text legible over bright daytime shots.
  static const photoTint = Color(0xB87A1013);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      primary: AppColors.brand,
    ),
    scaffoldBackgroundColor: AppColors.scaffold,
  );

  final textTheme = GoogleFonts.ralewayTextTheme(base.textTheme);

  return base.copyWith(
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.scaffold,
      foregroundColor: AppColors.ink,
      elevation: 0,
      // Material 3 otherwise tints the AppBar when content scrolls under it.
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.raleway(
        color: AppColors.ink,
        fontWeight: FontWeight.w800,
        fontSize: 18,
      ),
    ),
  );
}
