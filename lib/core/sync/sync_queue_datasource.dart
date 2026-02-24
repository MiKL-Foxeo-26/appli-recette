import 'package:appli_recette/core/database/app_database.dart';
import 'package:drift/drift.dart';

/// DAO wrapping AppDatabase.syncQueue pour la gestion de la file offline-first.
class SyncQueueDatasource {
  SyncQueueDatasource(this._db);

  final AppDatabase _db;

  /// Enfile une opération dans la sync_queue.
  Future<void> enqueue(SyncQueueCompanion companion) async {
    await _db.into(_db.syncQueue).insert(companion);
  }

  /// Retourne les N plus anciennes entrées en attente (FIFO par createdAt).
  Future<List<SyncQueueData>> getOldestPending({int limit = 50}) async {
    return (_db.select(_db.syncQueue)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Supprime une entrée après synchronisation réussie.
  Future<void> markSuccess(String id) async {
    await (_db.delete(_db.syncQueue)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  /// Incrémente le compteur d'erreurs et met à jour le message d'erreur.
  Future<void> incrementRetry(String id, String error) async {
    final existing = await (_db.select(_db.syncQueue)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (existing == null) return;

    await (_db.update(_db.syncQueue)
          ..where((t) => t.id.equals(id)))
        .write(
      SyncQueueCompanion(
        retryCount: Value(existing.retryCount + 1),
        lastError: Value(error),
      ),
    );
  }

  /// Supprime les entrées mortes (retryCount >= 3).
  Future<void> deleteProcessed() async {
    await (_db.delete(_db.syncQueue)
          ..where((t) => t.retryCount.isBiggerOrEqualValue(3)))
        .go();
  }

  /// Stream du nombre d'opérations en attente (pour le badge UI).
  Stream<int> watchPendingCount() {
    final countExpr = _db.syncQueue.id.count();
    return (_db.selectOnly(_db.syncQueue)
          ..addColumns([countExpr]))
        .map((row) => row.read(countExpr) ?? 0)
        .watchSingle();
  }
}
