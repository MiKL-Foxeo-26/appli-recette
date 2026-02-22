import 'package:appli_recette/core/database/app_database.dart';

/// Données d'entrée pour créer/remplacer un ingrédient.
class IngredientInput {
  const IngredientInput({
    required this.name,
    this.quantity,
    this.unit,
    this.supermarketSection,
  });

  final String name;
  final double? quantity;
  final String? unit;
  final String? supermarketSection;
}

/// Interface du Repository Ingrédients.
abstract class IngredientRepository {
  /// Stream de tous les ingrédients d'une recette.
  Stream<List<Ingredient>> watchForRecipe(String recipeId);

  /// Ajoute un ingrédient. Retourne son ID UUID v4.
  Future<String> add({
    required String recipeId,
    required String name,
    double? quantity,
    String? unit,
    String? supermarketSection,
  });

  /// Met à jour un ingrédient existant.
  Future<void> update({
    required String id,
    required String name,
    double? quantity,
    String? unit,
    String? supermarketSection,
  });

  /// Supprime un ingrédient par son ID.
  Future<void> delete(String id);

  /// Supprime tous les ingrédients d'une recette.
  Future<void> deleteAllForRecipe(String recipeId);

  /// Remplace tous les ingrédients d'une recette (transaction atomique).
  Future<void> replaceAll({
    required String recipeId,
    required List<IngredientInput> ingredients,
  });
}
