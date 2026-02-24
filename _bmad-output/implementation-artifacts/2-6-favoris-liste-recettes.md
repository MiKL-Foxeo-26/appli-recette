# Story 2.6 : Gérer les Favoris & Consulter la Liste des Recettes

## Story
En tant qu'utilisateur, je veux marquer mes recettes en favori et consulter ma collection facilement.

## Status
done

## Code Review — 2026-02-22

**Reviewer :** Claude (adversarial code-review BMAD workflow)
**Résultat :** PASS avec corrections appliquées

### Fixes appliqués
- **HIGH** : recipeByIdProvider en StreamProvider — toggle favori reflété immédiatement
- **MEDIUM** : Try/catch + SnackBar erreur sur toggleFavorite dans la fiche détail
- **LOW** : formatTime partagé, suppression des méthodes dupliquées

## Acceptance Criteria
- Toggle favori depuis fiche ou liste, persisté — FR15
- Favoris visuellement distingués dans la liste
- RecipeCard : image + nom + type + temps total
- Recherche par nom dans RecipesPage
- État vide : "Commence par ajouter une recette" + bouton Ajouter
- FAB "+" visible et fonctionnel — FR16

## Tasks / Subtasks
- [x] Task 1: Toggle favori dans RecipeDetailScreen + RecipesPage
- [x] Task 2: Barre de recherche dans RecipesPage (SearchBar Material 3)
- [x] Task 3: RecipeCard enrichie (photo si disponible, badge favori, tap vers détail)
- [x] Task 4: Tests

## Dev Agent Record
### Completion Notes
- `RecipesPage` converti en `ConsumerStatefulWidget` avec `_searchQuery` state
- `SearchBar` Material 3 dans AppBar.bottom avec bouton clear
- `recipesSearchProvider` (StreamProvider.family) pour le filtrage en temps réel
- `_RecipeCard` : `ConsumerWidget` avec photo locale (si disponible), icône MealType, temps, badge favori cliquable
- Toggle favori depuis la carte (IconButton) et depuis le détail (AppBar action)
- `setFavorite()` persisté en drift via `RecipeRepository`
- Tests : Story 2-6 group dans recipe_repository_extended_test.dart (toggle + watchBySearch)

## File List
- `lib/features/recipes/view/recipes_page.dart` (SearchBar + RecipeCard enrichie)
- `lib/features/recipes/presentation/providers/recipes_provider.dart` (recipesSearchProvider)
- `lib/features/recipes/view/recipe_detail_screen.dart` (toggle favori depuis détail)
- `test/features/recipes/data/repositories/recipe_repository_extended_test.dart` (group Story 2-6)

## Change Log
- 2026-02-21: Story implémentée (Epic 2 complet)
