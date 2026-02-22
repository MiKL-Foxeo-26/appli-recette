import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/features/recipes/data/datasources/ingredient_local_datasource.dart';
import 'package:appli_recette/features/recipes/domain/repositories/ingredient_repository.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Implémentation concrète du IngredientRepository.
class IngredientRepositoryImpl implements IngredientRepository {
  IngredientRepositoryImpl(this._datasource);

  final IngredientLocalDatasource _datasource;

  @override
  Stream<List<Ingredient>> watchForRecipe(String recipeId) =>
      _datasource.watchForRecipe(recipeId);

  @override
  Future<String> add({
    required String recipeId,
    required String name,
    double? quantity,
    String? unit,
    String? supermarketSection,
  }) {
    final id = const Uuid().v4();
    final companion = IngredientsCompanion.insert(
      id: id,
      recipeId: recipeId,
      name: name,
      quantity: Value(quantity),
      unit: Value(unit),
      supermarketSection: Value(supermarketSection),
    );
    return _datasource.insert(companion);
  }

  @override
  Future<void> update({
    required String id,
    required String name,
    double? quantity,
    String? unit,
    String? supermarketSection,
  }) {
    final companion = IngredientsCompanion(
      id: Value(id),
      name: Value(name),
      quantity: Value(quantity),
      unit: Value(unit),
      supermarketSection: Value(supermarketSection),
    );
    return _datasource.update(companion);
  }

  @override
  Future<void> delete(String id) => _datasource.delete(id);

  @override
  Future<void> deleteAllForRecipe(String recipeId) =>
      _datasource.deleteAllForRecipe(recipeId);

  @override
  Future<void> replaceAll({
    required String recipeId,
    required List<IngredientInput> ingredients,
  }) =>
      _datasource.replaceAll(recipeId: recipeId, ingredients: ingredients);
}
