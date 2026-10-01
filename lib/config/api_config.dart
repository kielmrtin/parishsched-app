/// Base URL for the handful of Laravel endpoints the app calls directly
/// instead of going through Supabase (currently just the contact/inquiry
/// form, since that's a plain email relay with nothing to persist).
class ApiConfig {
  static const String baseUrl = 'https://stjohnbaptistparish.org';
}
