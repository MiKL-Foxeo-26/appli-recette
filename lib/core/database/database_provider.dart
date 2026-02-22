import 'package:appli_recette/core/database/app_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider de la base de données drift.
/// Doit être overridé dans ProviderScope avec l'instance réelle.
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
    'databaseProvider must be overridden with a real AppDatabase instance.',
  );
});
