/// Centralized runtime configuration for OmniDrive.
///
/// Supports compile-time environment overrides via `--dart-define`:
/// - `API_BASE_URL`: Python AI backend endpoint
/// - `SUPABASE_URL`: Supabase project URL
/// - `SUPABASE_ANON_KEY`: Supabase public anon key
class AppConfig {
  AppConfig._();

  /// Base URL of the FastAPI AI Vision & RAG backend.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://omnidrive.onrender.com',
  );

  /// Supabase PostgreSQL & Auth endpoint.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://cqeubytgsrxdkfejxvan.supabase.co',
  );

  /// Supabase public anonymous client key.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNxZXVieXRnc3J4ZGtmZWp4dmFuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMwNzMwMTMsImV4cCI6MjA4ODY0OTAxM30.iTL7KvhVxLEJFZFO50OvkgNWAyKfhM8Q51wkbZZTuPk',
  );

  // Derived endpoints
  static String get predictUrl => '$apiBaseUrl/predict';
  static String get healthUrl => '$apiBaseUrl/health';
  static String get chatUrl => '$apiBaseUrl/chat';
}
