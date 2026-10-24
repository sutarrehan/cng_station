/// Public Supabase project settings only. Never put a service-role key here.
/// Fill these values from your Supabase project before enabling uploads.
class SupabaseConfig {
  SupabaseConfig._();
  static const String projectUrl = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String complaintBucket = String.fromEnvironment(
    'SUPABASE_COMPLAINT_BUCKET', defaultValue: 'complaint-images',
  );
  static bool get isConfigured => projectUrl.startsWith('https://') && anonKey.isNotEmpty;
}
