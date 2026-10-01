import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Fetches public parish content (announcements, etc.) — mirrors
/// HomeController::index, which reads the same `announcements` table
/// filtered to `show_on_home = true`.
class ContentService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchHomeAnnouncements() async {
    final rows = await _client
        .from('announcements')
        .select()
        .eq('show_on_home', true)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Builds the public Supabase Storage URL for an announcement image,
  /// same construction as the website's `home.blade.php`.
  String announcementImageUrl(String imagePath) {
    final path = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
    if (path.startsWith('http')) return path;
    final prefixed = path.startsWith('announcements/')
        ? path
        : 'announcements/$path';
    return '${SupabaseConfig.url}/storage/v1/object/public/$prefixed';
  }
}
