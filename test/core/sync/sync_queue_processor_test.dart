import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/core/sync/sync_queue_datasource.dart';
import 'package:appli_recette/core/sync/sync_queue_processor.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Mocks
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

AppDatabase _createDb() => AppDatabase.forTesting(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  late SyncQueueDatasource syncQueue;
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late SyncQueueProcessor processor;

  setUp(() {
    db = _createDb();
    syncQueue = SyncQueueDatasource(db);
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockClient.auth).thenReturn(mockAuth);
    processor = SyncQueueProcessor(syncQueue, mockClient);
  });

  tearDown(() async => db.close());

  Future<void> _enqueueEntry({String id = 'e1'}) async {
    await syncQueue.enqueue(
      SyncQueueCompanion.insert(
        id: id,
        operation: 'insert',
        entityTable: 'recipes',
        recordId: 'r1',
        payload: '{"id":"r1","name":"Test"}',
        createdAt: DateTime.now(),
      ),
    );
  }

  group('SyncQueueProcessor', () {
    test(
      'processQueue() skip silencieusement quand auth.currentSession est null (AC-8)',
      () async {
        when(() => mockAuth.currentSession).thenReturn(null);
        await _enqueueEntry();

        // Ne doit pas lever d'exception
        await expectLater(processor.processQueue(), completes);

        // L'entrée reste dans la queue — aucun traitement effectué
        final remaining = await syncQueue.getOldestPending();
        expect(remaining.length, 1, reason: 'Queue doit rester intacte sans auth');

        // Supabase.from() ne doit jamais être appelé
        verifyNever(() => mockClient.from(any()));
      },
    );

    test(
      'processQueue() ne lève pas d\'exception même si la queue est vide',
      () async {
        when(() => mockAuth.currentSession).thenReturn(null);
        await expectLater(processor.processQueue(), completes);
      },
    );

    test(
      'processQueue() avec session null — appels multiples restent silencieux',
      () async {
        when(() => mockAuth.currentSession).thenReturn(null);
        await _enqueueEntry(id: 'e1');
        await _enqueueEntry(id: 'e2');

        await processor.processQueue();
        await processor.processQueue();

        // Toujours 2 entrées, aucune n'a été traitée
        final remaining = await syncQueue.getOldestPending();
        expect(remaining.length, 2);
        verifyNever(() => mockClient.from(any()));
      },
    );
  });

  // Note: les tests de traitement complet (insert/update/delete vers Supabase)
  // nécessitent un vrai SupabaseClient et sont couverts par rls_isolation_test.dart
  // (Story 7.3) qui requiert une connexion Supabase réelle.
}
