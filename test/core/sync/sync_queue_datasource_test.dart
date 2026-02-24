import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/core/sync/sync_queue_datasource.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

AppDatabase _createDb() => AppDatabase.forTesting(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  late SyncQueueDatasource datasource;

  setUp(() {
    db = _createDb();
    datasource = SyncQueueDatasource(db);
  });

  tearDown(() async => db.close());

  SyncQueueCompanion _makeEntry({
    String? id,
    String operation = 'insert',
    String entityTable = 'recipes',
    String recordId = 'record-1',
    String payload = '{"id":"record-1"}',
  }) {
    return SyncQueueCompanion.insert(
      id: id ?? const Uuid().v4(),
      operation: operation,
      entityTable: entityTable,
      recordId: recordId,
      payload: payload,
      createdAt: DateTime.now(),
    );
  }

  group('SyncQueueDatasource', () {
    test('enqueue() insère une entrée dans la queue', () async {
      await datasource.enqueue(_makeEntry(id: 'e1'));

      final entries = await datasource.getOldestPending();
      expect(entries.length, 1);
      expect(entries.first.id, 'e1');
      expect(entries.first.operation, 'insert');
      expect(entries.first.entityTable, 'recipes');
    });

    test('getOldestPending() retourne les entrées dans l\'ordre FIFO', () async {
      final t1 = DateTime(2026, 1, 1, 10, 0, 0);
      final t2 = DateTime(2026, 1, 1, 10, 0, 1);
      final t3 = DateTime(2026, 1, 1, 10, 0, 2);

      await db.into(db.syncQueue).insert(
            SyncQueueCompanion.insert(
              id: 'e3',
              operation: 'insert',
              entityTable: 'recipes',
              recordId: 'r3',
              payload: '{}',
              createdAt: t3,
            ),
          );
      await db.into(db.syncQueue).insert(
            SyncQueueCompanion.insert(
              id: 'e1',
              operation: 'insert',
              entityTable: 'recipes',
              recordId: 'r1',
              payload: '{}',
              createdAt: t1,
            ),
          );
      await db.into(db.syncQueue).insert(
            SyncQueueCompanion.insert(
              id: 'e2',
              operation: 'insert',
              entityTable: 'recipes',
              recordId: 'r2',
              payload: '{}',
              createdAt: t2,
            ),
          );

      final entries = await datasource.getOldestPending();
      expect(entries.map((e) => e.id).toList(), ['e1', 'e2', 'e3']);
    });

    test('getOldestPending() respecte le limit', () async {
      for (var i = 0; i < 5; i++) {
        await datasource.enqueue(_makeEntry(id: 'e$i', recordId: 'r$i'));
      }

      final entries = await datasource.getOldestPending(limit: 3);
      expect(entries.length, 3);
    });

    test('markSuccess() supprime l\'entrée de la queue', () async {
      await datasource.enqueue(_makeEntry(id: 'e1'));
      await datasource.markSuccess('e1');

      final entries = await datasource.getOldestPending();
      expect(entries, isEmpty);
    });

    test('incrementRetry() incrémente retryCount et met à jour lastError', () async {
      await datasource.enqueue(_makeEntry(id: 'e1'));
      await datasource.incrementRetry('e1', 'Network error');

      final entries = await datasource.getOldestPending();
      expect(entries.first.retryCount, 1);
      expect(entries.first.lastError, 'Network error');
    });

    test('incrementRetry() multiple fois accumule le count', () async {
      await datasource.enqueue(_makeEntry(id: 'e1'));
      await datasource.incrementRetry('e1', 'err1');
      await datasource.incrementRetry('e1', 'err2');

      final entries = await datasource.getOldestPending();
      expect(entries.first.retryCount, 2);
      expect(entries.first.lastError, 'err2');
    });

    test('deleteProcessed() supprime les entrées avec retryCount >= 3', () async {
      await datasource.enqueue(_makeEntry(id: 'e1'));
      await datasource.enqueue(_makeEntry(id: 'e2'));

      // e1 → 3 retries
      await datasource.incrementRetry('e1', 'err');
      await datasource.incrementRetry('e1', 'err');
      await datasource.incrementRetry('e1', 'err');

      await datasource.deleteProcessed();

      final entries = await datasource.getOldestPending();
      expect(entries.length, 1);
      expect(entries.first.id, 'e2');
    });

    test('watchPendingCount() émet le nombre courant', () async {
      await datasource.enqueue(_makeEntry(id: 'e1'));
      await datasource.enqueue(_makeEntry(id: 'e2'));

      final count = await datasource.watchPendingCount().first;
      expect(count, 2);
    });

    test('watchPendingCount() émet 0 quand la queue est vide', () async {
      final count = await datasource.watchPendingCount().first;
      expect(count, 0);
    });

    test('incrementRetry() ne fait rien si l\'ID n\'existe pas', () async {
      // Ne doit pas lever d'exception
      await expectLater(
        datasource.incrementRetry('inexistant', 'err'),
        completes,
      );
    });

    test('enqueue() multiples — tous récupérables', () async {
      for (var i = 0; i < 3; i++) {
        await datasource.enqueue(
          _makeEntry(id: 'e$i', operation: i == 2 ? 'delete' : 'insert'),
        );
      }

      final entries = await datasource.getOldestPending();
      expect(entries.length, 3);
      expect(entries.last.operation, 'delete');
    });
  });
}
