import 'dart:ui';

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Matches church-web's `.ps-overlay` / `.ps-modal` notification component
/// (dimmed+blurred backdrop, icon badge, title, message, 1-2 actions), but
/// in white to match the rest of the app's cards instead of the site's
/// dark navy.
enum AppAlertType { success, error, warning }

class AppAlertAction {
  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  const AppAlertAction({
    required this.label,
    this.onPressed,
    this.primary = true,
  });
}

Future<void> showAppAlert(
  BuildContext context, {
  required AppAlertType type,
  required String title,
  required String message,
  List<AppAlertAction>? actions,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: const Color(0xBF060D1A),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
    transitionBuilder: (context, anim, secondaryAnim, child) {
      return BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 3 * anim.value,
          sigmaY: 3 * anim.value,
        ),
        child: FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween(
              begin: 0.92,
              end: 1.0,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: _AppAlertCard(
                  type: type,
                  title: title,
                  message: message,
                  actions: actions,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _AppAlertCard extends StatelessWidget {
  final AppAlertType type;
  final String title;
  final String message;
  final List<AppAlertAction>? actions;

  const _AppAlertCard({
    required this.type,
    required this.title,
    required this.message,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedActions =
        actions ??
        [
          AppAlertAction(
            label: 'OK',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ];

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(Icons.close, size: 18, color: Colors.grey.shade400),
              ),
            ),
            const Text(
              'PARISHSCHED',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(height: 14),
            _icon(),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                for (var i = 0; i < resolvedActions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: _button(context, resolvedActions[i])),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _icon() {
    late Color badgeTint;
    late Color glyphColor;
    late IconData glyph;
    switch (type) {
      case AppAlertType.success:
        badgeTint = const Color(0xFFFCA5A5);
        glyphColor = AppColors.brand;
        glyph = Icons.check;
      case AppAlertType.error:
        badgeTint = const Color(0xFFF87171);
        glyphColor = const Color(0xFFDC2626);
        glyph = Icons.close;
      case AppAlertType.warning:
        badgeTint = const Color(0xFFF0C778);
        glyphColor = const Color(0xFFB45309);
        glyph = Icons.priority_high;
    }
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: badgeTint.withValues(alpha: 0.14),
        border: Border.all(
          color: badgeTint.withValues(alpha: 0.45),
          width: 1.5,
        ),
      ),
      child: Center(child: Icon(glyph, color: glyphColor, size: 24)),
    );
  }

  Widget _button(BuildContext context, AppAlertAction action) {
    final onPressed = action.onPressed ?? () => Navigator.of(context).pop();
    if (action.primary) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
          ),
          elevation: 0,
        ),
        child: Text(action.label),
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.inkSoft,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
      ),
      child: Text(action.label),
    );
  }
}
