/// Supabase connection details.
///
/// These read from `--dart-define` at build time, falling back to the project's
/// values so the app runs without extra flags. The anon key is *publishable* by
/// design — it's safe in client code because Row-Level Security guards the data.
/// (Never put the `service_role` key here.)
///
/// To override at build/run time:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://dmldquewvfpawlgejnvn.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRtbGRxdWV3dmZwYXdsZ2VqbnZuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIxOTA0NzIsImV4cCI6MjA5Nzc2NjQ3Mn0.LLW5Zj1K88v-RPkVGhPtwevM4OGo3qhyEdxzU1A6QeA',
  );
}
