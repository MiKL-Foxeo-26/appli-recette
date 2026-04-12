import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Service d'upload/suppression de photos sur Supabase Storage.
/// Bucket : `recipe-photos`, chemin : `{householdId}/{recipeId}.jpg`
class SupabaseStorageService {
  SupabaseStorageService(this._client);

  final SupabaseClient _client;

  static const _bucket = 'recipe-photos';

  /// Uploade une image compressée et retourne l'URL publique.
  Future<String> uploadRecipePhoto({
    required Uint8List bytes,
    required String householdId,
    required String recipeId,
  }) async {
    final path = '$householdId/$recipeId.jpg';
    await _client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
    // Cache-buster : Supabase renvoie la même URL publique pour un même chemin,
    // ce qui empêche CachedNetworkImage de voir qu'une nouvelle version a été
    // uploadée. Un query param ?v=timestamp force le rafraîchissement côté client.
    final url = _client.storage.from(_bucket).getPublicUrl(path);
    final v = DateTime.now().millisecondsSinceEpoch;
    return '$url?v=$v';
  }

  /// Supprime la photo d'une recette du Storage.
  Future<void> deleteRecipePhoto({
    required String householdId,
    required String recipeId,
  }) async {
    final path = '$householdId/$recipeId.jpg';
    await _client.storage.from(_bucket).remove([path]);
  }

  /// Supprime une photo à partir de son URL publique Supabase Storage.
  /// Extrait le chemin relatif depuis l'URL pour effectuer la suppression.
  Future<void> deleteByPublicUrl(String publicUrl) async {
    final uri = Uri.tryParse(publicUrl);
    if (uri == null) return;
    final segments = uri.pathSegments;
    final bucketIdx = segments.indexOf(_bucket);
    if (bucketIdx == -1 || bucketIdx + 1 >= segments.length) return;
    final path = segments.sublist(bucketIdx + 1).join('/');
    await _client.storage.from(_bucket).remove([path]);
  }
}
