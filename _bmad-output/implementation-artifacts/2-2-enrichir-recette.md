# Story 2.2 : Enrichir une Recette (Saison, Végé, Portions, Ingrédients)

## Story
En tant qu'utilisateur, je veux enrichir une recette existante avec la saison, le tag végétarien, les portions et les ingrédients structurés, afin que l'algorithme de génération puisse filtrer et utiliser ces informations.

## Status
done

## Code Review — 2026-02-22

**Reviewer :** Claude (adversarial code-review BMAD workflow)
**Résultat :** PASS avec corrections appliquées

### Fixes appliqués
- **HIGH** : Save atomique recette+ingrédients dans transaction drift
- **HIGH** : `updateWithIngredients()` ajouté au repository pattern (domain + data + provider)
- **MEDIUM** : MealType.tryFromValue() au lieu de firstWhere sans fallback

## Acceptance Criteria
- Saison (chips : printemps, été, automne, hiver, toute saison) — FR5
- Végétarien (Switch/Toggle) — FR6
- Portions (champ numérique) — FR7
- Ingrédients structurés (nom, quantité, unité, rayon supermarché) — FR8
- Persisté immédiatement dans drift sans perte — NFR4

## Tasks / Subtasks
- [x] Task 1: Étendre RecipeRepository (update, getById, watchBySearch)
- [x] Task 2: IngredientRepository (interface + impl + datasource)
- [x] Task 3: Providers (updateRecipe, ingredientsForRecipe, replaceIngredients)
- [x] Task 4: RecipeDetailScreen (lecture + actions)
- [x] Task 5: EditRecipeScreen — Section 2 (saison chips, végé switch, portions, ingrédients dynamiques)
- [x] Task 6: Mise à jour router (detail `/recipes/:id` + edit `/recipes/:id/edit`)
- [x] Task 7: Tap sur RecipeCard → RecipeDetailScreen
- [x] Task 8: Tests (update, getById, ingredient CRUD, replaceAll)

## Dev Agent Record
### Completion Notes
- `RecipeRepository` étendu avec `update()`, `getById()`, `watchBySearch()`, `updatePhotoPath()`
- `IngredientRepository` créé (interface domaine + impl + datasource)
- `EditRecipeScreen` : formulaire 3 sections avec chips saison, switch végétarien, champs ingrédients dynamiques
- `RecipeDetailScreen` : affichage complet avec ingrédients streamés
- Router mis à jour avec routes `/recipes/:id` et `/recipes/:id/edit`
- `RecipesPage` tape sur une carte → push `/recipes/:id`
- 28 tests passent (incluant 8 tests ingrédients + 13 tests extended repository)

## File List
- `lib/features/recipes/domain/repositories/recipe_repository.dart` (étendu)
- `lib/features/recipes/domain/repositories/ingredient_repository.dart` (créé)
- `lib/features/recipes/data/datasources/recipe_local_datasource.dart` (étendu)
- `lib/features/recipes/data/datasources/ingredient_local_datasource.dart` (créé)
- `lib/features/recipes/data/repositories/recipe_repository_impl.dart` (étendu)
- `lib/features/recipes/data/repositories/ingredient_repository_impl.dart` (créé)
- `lib/features/recipes/presentation/providers/recipes_provider.dart` (étendu)
- `lib/features/recipes/view/recipe_detail_screen.dart` (créé)
- `lib/features/recipes/view/edit_recipe_screen.dart` (créé)
- `lib/core/router/app_router.dart` (étendu)
- `lib/features/recipes/view/recipes_page.dart` (étendu)
- `test/features/recipes/data/repositories/recipe_repository_extended_test.dart` (créé)
- `test/features/recipes/data/datasources/ingredient_local_datasource_test.dart` (créé)

## Change Log
- 2026-02-21: Story implémentée (Epic 2 complet)
