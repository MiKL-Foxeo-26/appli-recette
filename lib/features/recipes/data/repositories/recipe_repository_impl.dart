import 'dart:convert';

import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/core/sync/sync_queue_datasource.dart';
import 'package:appli_recette/features/recipes/data/datasources/ingredient_local_datasource.dart';
import 'package:appli_recette/features/recipes/data/datasources/recipe_local_datasource.dart';
import 'package:appli_recette/features/recipes/domain/repositories/ingredient_repository.dart';
import 'package:appli_recette/features/recipes/domain/repositories/recipe_repository.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Implémentation concrète du RecipeRepository.
/// Délègue au datasource local (drift) et enfile dans la sync_queue.
class RecipeRepositoryImpl implements RecipeRepository {
  RecipeRepositoryImpl(
    this._datasource,
    this._syncQueue, {
    IngredientLocalDatasource? ingredientDatasource,
  }) : _ingredientDatasource = ingredientDatasource;

  final RecipeLocalDatasource _datasource;
  final SyncQueueDatasource _syncQueue;
  // Optionnel pour retro-compat des tests existants. Utilisé uniquement par
  // updateWithIngredients pour enqueue les deletes/inserts d'ingredients.
  final IngredientLocalDatasource? _ingredientDatasource;

  static const _keyHouseholdId = 'household_id';

  Future<String?> _getHouseholdId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyHouseholdId);
  }

  @override
  Stream<List<Recipe>> watchAll(String householdId) =>
      _datasource.watchAll(householdId);

  @override
  Stream<List<Recipe>> watchBySearch(String query, String householdId) =>
      _datasource.watchBySearch(query, householdId);

  @override
  Future<Recipe?> getById(String id) => _datasource.getById(id);

  @override
  Stream<Recipe?> watchById(String id) => _datasource.watchById(id);

  @override
  Future<String> create({
    required String name,
    required String mealType,
    required int prepTimeMinutes,
    int cookTimeMinutes = 0,
    int restTimeMinutes = 0,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final householdId = await _getHouseholdId();
    final companion = RecipesCompanion.insert(
      id: id,
      name: name,
      mealType: mealType,
      prepTimeMinutes: Value(prepTimeMinutes),
      cookTimeMinutes: Value(cookTimeMinutes),
      restTimeMinutes: Value(restTimeMinutes),
      createdAt: now,
      updatedAt: now,
      householdId: Value(householdId),
    );
    final result = await _datasource.insert(companion);
    await _syncQueue.enqueue(
      SyncQueueCompanion.insert(
        id: const Uuid().v4(),
        operation: 'insert',
        entityTable: 'recipes',
        recordId: id,
        payload: jsonEncode({
          'id': id,
          'name': name,
          'meal_type': mealType,
          'prep_time_minutes': prepTimeMinutes,
          'cook_time_minutes': cookTimeMinutes,
          'rest_time_minutes': restTimeMinutes,
          'season': 'all',
          'is_vegetarian': false,
          'is_favorite': false,
          'servings': 4,
          'created_at': now.toUtc().toIso8601String(),
          'updated_at': now.toUtc().toIso8601String(),
          if (householdId != null) 'household_id': householdId,
        }),
        createdAt: now,
      ),
    );
    return result;
  }

  @override
  Future<void> update({
    required String id,
    required String name,
    required String mealType,
    required int prepTimeMinutes,
    required int cookTimeMinutes,
    required int restTimeMinutes,
    required String season,
    required bool isVegetarian,
    required int servings,
    String? notes,
    String? variants,
    String? sourceUrl,
    String? photoPath,
  }) async {
    final now = DateTime.now();
    final companion = RecipesCompanion(
      id: Value(id),
      name: Value(name),
      mealType: Value(mealType),
      prepTimeMinutes: Value(prepTimeMinutes),
      cookTimeMinutes: Value(cookTimeMinutes),
      restTimeMinutes: Value(restTimeMinutes),
      season: Value(season),
      isVegetarian: Value(isVegetarian),
      servings: Value(servings),
      notes: Value(notes),
      variants: Value(variants),
      sourceUrl: Value(sourceUrl),
      photoPath: Value(photoPath),
      updatedAt: Value(now),
    );
    await _datasource.update(companion);

    final householdId = await _getHouseholdId();
    await _syncQueue.enqueue(
      SyncQueueCompanion.insert(
        id: const Uuid().v4(),
        operation: 'update',
        entityTable: 'recipes',
        recordId: id,
        payload: jsonEncode({
          'id': id,
          'name': name,
          'meal_type': mealType,
          'prep_time_minutes': prepTimeMinutes,
          'cook_time_minutes': cookTimeMinutes,
          'rest_time_minutes': restTimeMinutes,
          'season': season,
          'is_vegetarian': isVegetarian,
          'servings': servings,
          if (notes != null) 'notes': notes,
          if (variants != null) 'variants': variants,
          if (sourceUrl != null) 'source_url': sourceUrl,
          if (photoPath != null) 'photo_path': photoPath,
          'updated_at': now.toUtc().toIso8601String(),
          if (householdId != null) 'household_id': householdId,
        }),
        createdAt: now,
      ),
    );
  }

  @override
  Future<void> updateWithIngredients({
    required String id,
    required String name,
    required String mealType,
    required int prepTimeMinutes,
    required int cookTimeMinutes,
    required int restTimeMinutes,
    required String season,
    required bool isVegetarian,
    required int servings,
    String? notes,
    String? variants,
    String? sourceUrl,
    String? photoPath,
    required List<IngredientInput> ingredients,
  }) async {
    final now = DateTime.now();
    final householdId = await _getHouseholdId();

    // 1. Lister les anciens ingrédients AVANT le replace, pour pouvoir
    //    enqueue les deletes cloud correspondants.
    final oldIngredients = _ingredientDatasource == null
        ? const <Ingredient>[]
        : await _ingredientDatasource.listForRecipe(id);

    final companion = RecipesCompanion(
      id: Value(id),
      name: Value(name),
      mealType: Value(mealType),
      prepTimeMinutes: Value(prepTimeMinutes),
      cookTimeMinutes: Value(cookTimeMinutes),
      restTimeMinutes: Value(restTimeMinutes),
      season: Value(season),
      isVegetarian: Value(isVegetarian),
      servings: Value(servings),
      notes: Value(notes),
      variants: Value(variants),
      sourceUrl: Value(sourceUrl),
      photoPath: Value(photoPath),
      updatedAt: Value(now),
    );

    // 2. Appliquer en drift (transaction atomique : update recette +
    //    delete old ingredients + insert new).
    await _datasource.updateWithIngredients(
      recipeCompanion: companion,
      recipeId: id,
      ingredients: ingredients,
    );

    // 3. Enqueue l'update de la recette.
    await _syncQueue.enqueue(
      SyncQueueCompanion.insert(
        id: const Uuid().v4(),
        operation: 'update',
        entityTable: 'recipes',
        recordId: id,
        payload: jsonEncode({
          'id': id,
          'name': name,
          'meal_type': mealType,
          'prep_time_minutes': prepTimeMinutes,
          'cook_time_minutes': cookTimeMinutes,
          'rest_time_minutes': restTimeMinutes,
          'season': season,
          'is_vegetarian': isVegetarian,
          'servings': servings,
          if (notes != null) 'notes': notes,
          if (variants != null) 'variants': variants,
          if (sourceUrl != null) 'source_url': sourceUrl,
          if (photoPath != null) 'photo_path': photoPath,
          'updated_at': now.toUtc().toIso8601String(),
          if (householdId != null) 'household_id': householdId,
        }),
        createdAt: now,
      ),
    );

    // 4. Enqueue les deletes pour chaque ancien ingrédient.
    for (final old in oldIngredients) {
      await _syncQueue.enqueue(
        SyncQueueCompanion.insert(
          id: const Uuid().v4(),
          operation: 'delete',
          entityTable: 'ingredients',
          recordId: old.id,
          payload: jsonEncode({'id': old.id}),
          createdAt: DateTime.now(),
        ),
      );
    }

    // 5. Relire les nouveaux ingrédients post-transaction pour récupérer
    //    les ids générés par le datasource, et les enqueue comme inserts.
    if (_ingredientDatasource != null) {
      final newIngredients = await _ingredientDatasource.listForRecipe(id);
      for (final ing in newIngredients) {
        await _syncQueue.enqueue(
          SyncQueueCompanion.insert(
            id: const Uuid().v4(),
            operation: 'insert',
            entityTable: 'ingredients',
            recordId: ing.id,
            payload: jsonEncode({
              'id': ing.id,
              'recipe_id': id,
              'name': ing.name,
              if (ing.quantity != null) 'quantity': ing.quantity,
              if (ing.unit != null) 'unit': ing.unit,
              if (ing.supermarketSection != null)
                'supermarket_section': ing.supermarketSection,
              if (householdId != null) 'household_id': householdId,
            }),
            createdAt: DateTime.now(),
          ),
        );
      }
    }
  }

  @override
  Future<void> delete(String id) async {
    await _datasource.delete(id);
    await _syncQueue.enqueue(
      SyncQueueCompanion.insert(
        id: const Uuid().v4(),
        operation: 'delete',
        entityTable: 'recipes',
        recordId: id,
        payload: jsonEncode({'id': id}),
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> setFavorite({
    required String id,
    required bool isFavorite,
  }) async {
    await _datasource.updateFavorite(id: id, isFavorite: isFavorite);
    final now = DateTime.now();
    await _syncQueue.enqueue(
      SyncQueueCompanion.insert(
        id: const Uuid().v4(),
        operation: 'update',
        entityTable: 'recipes',
        recordId: id,
        payload: jsonEncode({
          'id': id,
          'is_favorite': isFavorite,
          'updated_at': now.toUtc().toIso8601String(),
        }),
        createdAt: now,
      ),
    );
  }

  @override
  Future<void> updatePhotoPath({
    required String id,
    required String? photoPath,
  }) async {
    await _datasource.updatePhotoPath(id: id, photoPath: photoPath);
    final now = DateTime.now();
    await _syncQueue.enqueue(
      SyncQueueCompanion.insert(
        id: const Uuid().v4(),
        operation: 'update',
        entityTable: 'recipes',
        recordId: id,
        payload: jsonEncode({
          'id': id,
          'photo_path': photoPath,
          'updated_at': now.toUtc().toIso8601String(),
        }),
        createdAt: now,
      ),
    );
  }
}
