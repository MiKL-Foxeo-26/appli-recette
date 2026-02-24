/// Tests vérifiant que RecipeRepositoryImpl enfile correctement dans la
/// sync_queue après chaque opération drift (AC-1 Story 7.1).
library;

import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/core/sync/sync_queue_datasource.dart';
import 'package:appli_recette/features/recipes/data/datasources/recipe_local_datasource.dart';
import 'package:appli_recette/features/recipes/data/repositories/recipe_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

AppDatabase _createDb() => AppDatabase.forTesting(NativeDatabase.memory());

void main() {
  // Initialiser le binding Flutter (requis par SharedPreferences)
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late RecipeRepositoryImpl repo;
  late SyncQueueDatasource syncQueue;

  setUp(() {
    // Mock SharedPreferences sans household_id
    SharedPreferences.setMockInitialValues({});

    db = _createDb();
    final datasource = RecipeLocalDatasource(db);
    syncQueue = SyncQueueDatasource(db);
    repo = RecipeRepositoryImpl(datasource, syncQueue);
  });

  tearDown(() async => db.close());

  group('RecipeRepositoryImpl — sync queue (AC-1 Story 7.1)', () {
    test('create() enfile une opération "insert" dans la sync_queue', () async {
      await repo.create(
        name: 'Poulet rôti',
        mealType: 'dinner',
        prepTimeMinutes: 15,
      );

      final queue = await syncQueue.getOldestPending();
      expect(queue.length, 1);
      expect(queue.first.operation, 'insert');
      expect(queue.first.entityTable, 'recipes');
    });

    test('create() — le payload contient les champs snake_case', () async {
      await repo.create(
        name: 'Salade',
        mealType: 'lunch',
        prepTimeMinutes: 10,
        cookTimeMinutes: 5,
      );

      final queue = await syncQueue.getOldestPending();
      final payload = queue.first.payload;
      expect(payload, contains('"name"'));
      expect(payload, contains('"meal_type"'));
      expect(payload, contains('"prep_time_minutes"'));
      expect(payload, contains('"cook_time_minutes"'));
      expect(payload, contains('"created_at"'));
      expect(payload, contains('"updated_at"'));
    });

    test('update() enfile une opération "update" dans la sync_queue', () async {
      final id = await repo.create(
        name: 'Recette initiale',
        mealType: 'lunch',
        prepTimeMinutes: 10,
      );
      // Vider la queue de l'insert
      final initialQueue = await syncQueue.getOldestPending();
      await syncQueue.markSuccess(initialQueue.first.id);

      await repo.update(
        id: id,
        name: 'Recette modifiée',
        mealType: 'dinner',
        prepTimeMinutes: 20,
        cookTimeMinutes: 30,
        restTimeMinutes: 0,
        season: 'all',
        isVegetarian: false,
        servings: 4,
      );

      final queue = await syncQueue.getOldestPending();
      expect(queue.length, 1);
      expect(queue.first.operation, 'update');
      expect(queue.first.entityTable, 'recipes');
      expect(queue.first.recordId, id);
    });

    test('delete() enfile une opération "delete" dans la sync_queue', () async {
      final id = await repo.create(
        name: 'À supprimer',
        mealType: 'snack',
        prepTimeMinutes: 5,
      );
      final initialQueue = await syncQueue.getOldestPending();
      await syncQueue.markSuccess(initialQueue.first.id);

      await repo.delete(id);

      final queue = await syncQueue.getOldestPending();
      expect(queue.length, 1);
      expect(queue.first.operation, 'delete');
      expect(queue.first.recordId, id);
    });

    test('setFavorite() enfile une opération "update" dans la sync_queue', () async {
      final id = await repo.create(
        name: 'Recette',
        mealType: 'lunch',
        prepTimeMinutes: 10,
      );
      final initialQueue = await syncQueue.getOldestPending();
      await syncQueue.markSuccess(initialQueue.first.id);

      await repo.setFavorite(id: id, isFavorite: true);

      final queue = await syncQueue.getOldestPending();
      expect(queue.length, 1);
      expect(queue.first.operation, 'update');
      expect(queue.first.payload, contains('"is_favorite":true'));
    });

    test('recordId dans la queue correspond à l\'ID de la recette', () async {
      final id = await repo.create(
        name: 'Test',
        mealType: 'lunch',
        prepTimeMinutes: 5,
      );

      final queue = await syncQueue.getOldestPending();
      expect(queue.first.recordId, id);
    });
  });
}
