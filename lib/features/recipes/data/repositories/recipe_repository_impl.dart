import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/features/recipes/data/datasources/recipe_local_datasource.dart';
import 'package:appli_recette/features/recipes/domain/repositories/ingredient_repository.dart';
import 'package:appli_recette/features/recipes/domain/repositories/recipe_repository.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Implémentation concrète du RecipeRepository.
/// Délègue au datasource local (drift).
class RecipeRepositoryImpl implements RecipeRepository {
  RecipeRepositoryImpl(this._datasource);

  final RecipeLocalDatasource _datasource;

  @override
  Stream<List<Recipe>> watchAll() => _datasource.watchAll();

  @override
  Stream<List<Recipe>> watchBySearch(String query) =>
      _datasource.watchBySearch(query);

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
  }) {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final companion = RecipesCompanion.insert(
      id: id,
      name: name,
      mealType: mealType,
      prepTimeMinutes: Value(prepTimeMinutes),
      cookTimeMinutes: Value(cookTimeMinutes),
      restTimeMinutes: Value(restTimeMinutes),
      createdAt: now,
      updatedAt: now,
    );
    return _datasource.insert(companion);
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
  }) {
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
      updatedAt: Value(DateTime.now()),
    );
    return _datasource.update(companion);
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
  }) {
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
      updatedAt: Value(DateTime.now()),
    );
    return _datasource.updateWithIngredients(
      recipeCompanion: companion,
      recipeId: id,
      ingredients: ingredients,
    );
  }

  @override
  Future<void> delete(String id) => _datasource.delete(id);

  @override
  Future<void> setFavorite({
    required String id,
    required bool isFavorite,
  }) =>
      _datasource.updateFavorite(id: id, isFavorite: isFavorite);

  @override
  Future<void> updatePhotoPath({
    required String id,
    required String? photoPath,
  }) =>
      _datasource.updatePhotoPath(id: id, photoPath: photoPath);
}
