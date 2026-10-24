import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';

/// Optional service initialization. Firebase remains the required app backend;
/// Supabase is initialized only when public project settings are supplied.
class AppInitializer {
  AppInitializer._();

  static Future<void> initializeOptionalServices() async {
    if (SupabaseConfig.isConfigured) {
      await Supabase.initialize(
        url: SupabaseConfig.projectUrl,
        publishableKey: SupabaseConfig.anonKey,
      );
    }
  }
}
