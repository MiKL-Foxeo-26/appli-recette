# Story 2.5 : Modifier et Supprimer une Recette

## Story
En tant qu'utilisateur, je veux modifier une recette existante et la supprimer si nécessaire.

## Status
done

## Code Review — 2026-02-22

**Reviewer :** Claude (adversarial code-review BMAD workflow)
**Résultat :** PASS avec corrections appliquées

### Fixes appliqués
- **CRITICAL** : PRAGMA foreign_keys = ON (cascade deletes ne fonctionnaient pas)
- **HIGH** : Save atomique recette+ingrédients via transaction drift
- **HIGH** : recipeByIdProvider converti en StreamProvider (UI réactive après édition)
- **MEDIUM** : Nettoyage photo sur suppression recette

## Acceptance Criteria
- Modifier : tous les champs éditables, persistés — FR13, NFR4
- Supprimer : Dialog Material 3 (Annuler / Supprimer rouge) — NFR5, FR14
- Suppression uniquement après confirmation explicite
- Notations membres liées supprimées (cascade drift)

## Tasks / Subtasks
- [x] Task 1: Bouton Modifier dans RecipeDetailScreen → EditRecipeScreen pré-rempli
- [x] Task 2: Update complet (recette + ingrédients) dans repository
- [x] Task 3: Dialog de confirmation suppression
- [x] Task 4: Tests

## Dev Agent Record
### Completion Notes
- `RecipeDetailScreen` : bouton Edit (pencil icon) dans AppBar → push `/recipes/:id/edit`
- `EditRecipeScreen` : pré-remplit tous les champs (name, mealType, times, season, vegetarian, servings, notes, variants, sourceUrl, photo, ingredients) via `_initFromRecipe()` et `_initIngredients()`
- `update()` dans RecipeRepositoryImpl et `replaceAll()` pour les ingrédients — transaction atomique
- Suppression : `AlertDialog` Material 3 avec FilledButton rouge "Supprimer" + TextButton "Annuler"
- Cascade drift : `onDelete: KeyAction.cascade` dans IngredientsTable → ingrédients supprimés automatiquement
- Tests via recipe_repository_extended_test.dart (groups Story 2-2 et Story 2-5)

## File List
- `lib/features/recipes/view/recipe_detail_screen.dart` (boutons modifier + dialog suppression)
- `lib/features/recipes/view/edit_recipe_screen.dart` (pré-remplissage + update complet)
- `lib/features/recipes/data/repositories/recipe_repository_impl.dart` (update)
- `lib/features/recipes/data/repositories/ingredient_repository_impl.dart` (replaceAll)
- `test/features/recipes/data/repositories/recipe_repository_extended_test.dart`

## Change Log
- 2026-02-21: Story implémentée (Epic 2 complet)
