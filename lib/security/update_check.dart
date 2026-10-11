import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';
import '../theme/app_theme.dart';

/// Enforced updates (MASVS-CODE). The parish website publishes
/// /app-version.json, e.g.
///   {"min_build": 4, "download_url": ".../downloads/ParishSched.apk"}
/// and any installed build below min_build is blocked until updated.
/// Raising min_build on the website forces everyone onto the new version.
class UpdateCheck {
  UpdateCheck._();

  /// Returns the download URL if this build is too old, or null if it's OK.
  /// Fails open (null) when offline, so no-signal doesn't lock users out.
  static Future<String?> requiredUpdateUrl() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final current = int.tryParse(info.buildNumber) ?? 0;
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/app-version.json'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final minBuild = (data['min_build'] as num?)?.toInt() ?? 0;
      if (current >= minBuild) return null;
      final url = data['download_url'] as String?;
      // Only ever send people to the parish's own site.
      if (url == null || !url.startsWith('${ApiConfig.baseUrl}/')) {
        return '${ApiConfig.baseUrl}/downloads/ParishSched.apk';
      }
      return url;
    } catch (_) {
      return null;
    }
  }
}

class UpdateRequiredScreen extends StatelessWidget {
  const UpdateRequiredScreen({super.key, required this.downloadUrl});

  final String downloadUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brand,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.system_update_outlined, size: 60, color: Colors.white),
                const SizedBox(height: 18),
                const Text(
                  'Update required',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                const Text(
                  'This version of ParishSched is no longer supported. '
                  'Please download the latest version from the parish website.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14.5, height: 1.5),
                ),
                const SizedBox(height: 26),
                ElevatedButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse(downloadUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.download),
                  label: const Text('DOWNLOAD UPDATE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.brand,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
