// Tests unitaires pour la sécurité RLS via SyncQueueProcessor.
// Vérifie le comportement du processeur : guard auth (AC-5 Story 7.3, AC-8 Story 7.1).
// Ces tests utilisent des mocks pour éviter tout appel réseau réel.

import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/core/sync/sync_queue_datasource.dart';
import 'package:appli_recette/core/sync/sync_queue_processor.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

AppDatabase _createDb() => AppDatabase.forTesting(NativeDatabase.memory());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SyncQueueDatasource syncQueue;
  late _MockSupabaseClient mockClient;
  late _MockGoTrueClient mockAuth;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = _createDb();
    syncQueue = SyncQueueDatasource(db);
    mockClient = _MockSupabaseClient();
    mockAuth = _MockGoTrueClient();
    when(() => mockClient.auth).thenReturn(mockAuth);
  });

  tearDown(() async => db.close());

  // ── Garde d'authentification ───────────────────────────────────────────────

  group('SyncQueueProcessor — garde authentification (AC-8 Story 7.1, AC-5 Story 7.3)', () {
    test('ne fait aucun appel Supabase quand la session est nulle', () async {
      when(() => mockAuth.currentSession).thenReturn(null);

      final processor = SyncQueueProcessor(syncQueue, mockClient);
      await processor.processQueue();

      // Aucun appel réseau ne doit être effectué sans session
      verifyNever(() => mockClient.from(any()));
    });

    test('ne fait aucun appel Supabase même avec household_id en SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'household_id': 'test-household-uuid'});
      when(() => mockAuth.currentSession).thenReturn(null);

      final processor = SyncQueueProcessor(syncQueue, mockClient);
      await processor.processQueue();

      verifyNever(() => mockClient.from(any()));
    });

    test('ne fait aucun appel Supabase avec queue vide sans session', () async {
      when(() => mockAuth.currentSession).thenReturn(null);

      final processor = SyncQueueProcessor(syncQueue, mockClient);

      // Ne doit pas lever d'exception non plus
      await expectLater(processor.processQueue(), completes);
      verifyNever(() => mockClient.from(any()));
    });

    test('ne fait aucun appel Supabase sans session même si queue contient des entrées', () async {
      // Enqueue une opération
      await syncQueue.enqueue(
        SyncQueueCompanion.insert(
          id: 'test-id-001',
          entityTable: 'recipes',
          recordId: 'recipe-uuid',
          operation: 'insert',
          payload: '{"id":"recipe-uuid","name":"Test"}',
          createdAt: DateTime.now(),
        ),
      );

      when(() => mockAuth.currentSession).thenReturn(null);

      final processor = SyncQueueProcessor(syncQueue, mockClient);
      await processor.processQueue();

      // Malgré l'entrée en queue, aucun appel Supabase car pas de session
      verifyNever(() => mockClient.from(any()));
    });
  });
}
