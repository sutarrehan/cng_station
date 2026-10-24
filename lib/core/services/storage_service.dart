import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Uploads complaint images into a user-scoped Supabase Storage path and
/// returns a 1-hour signed URL. Keep the bucket private and enforce Storage RLS.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  bool get isConfigured => SupabaseConfig.isConfigured;

  Future<String> uploadComplaintImage({
    required String userId,
    required String localFilePath,
  }) async {
    if (!isConfigured) {
      throw StateError('Supabase is not configured. Pass SUPABASE_URL and SUPABASE_ANON_KEY with --dart-define.');
    }
    if (userId.trim().isEmpty || localFilePath.trim().isEmpty) {
      throw ArgumentError('User ID and image path are required.');
    }
    final file = File(localFilePath);
    if (!await file.exists()) throw ArgumentError('The selected image file does not exist.');

    final ext = localFilePath.split('.').last.toLowerCase();
    const allowed = {'jpg', 'jpeg', 'png', 'webp'};
    if (!allowed.contains(ext)) throw ArgumentError('Only JPG, PNG, and WEBP images are supported.');

    final objectPath = '$userId/complaints/${DateTime.now().toUtc().microsecondsSinceEpoch}.$ext';
    final storage = Supabase.instance.client.storage.from(SupabaseConfig.complaintBucket);
    await storage.upload(
      objectPath,
      file,
      fileOptions: const FileOptions(upsert: false),
    );
    return await storage.createSignedUrl(objectPath, 60 * 60);
  }
}
