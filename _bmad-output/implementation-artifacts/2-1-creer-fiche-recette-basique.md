# Story 2.1 : Créer une Fiche Recette Basique

## Story

**En tant qu'utilisateur,**
Je veux créer une fiche recette avec les informations essentielles (nom, type de repas, temps),
Afin d'ajouter rapidement une recette à ma collection en moins de 60 secondes.

## Status

done

## Code Review — 2026-02-22

**Reviewer :** Claude (adversarial code-review BMAD workflow)
**Résultat :** PASS avec corrections appliquées

### Fixes appliqués
- **CRITICAL** : PRAGMA foreign_keys = ON dans app_database.dart (cascade deletes cassés)
- **HIGH** : LIKE wildcards escape dans watchBySearch (injection de pattern)
- **MEDIUM** : MealType déplacé vers domain/models/ (respect architecture clean)
- **LOW** : `_formatTime` extrait vers `core/utils/time_utils.dart` (DRY)

## Acceptance Criteria

**Given** je tape sur le FAB "+" depuis n'importe quel écran
**When** je remplis le nom de la recette, le type de repas et le temps de préparation
**Then** la recette est créée et persistée localement via drift avec un UUID v4 comme identifiant (FR1) ✅
**And** le temps total est calculé automatiquement (préparation + cuisson + repos) (FR3) ✅
**And** la recette apparaît dans la liste des recettes ✅
**And** la création minimale (nom + type + temps) est réalisable en moins de 60 secondes (NFR9) ✅
**And** le formulaire RecipeQuickForm progressif affiche la section 1 obligatoire (nom + type) en premier (FR4) ✅

## Tasks / Subtasks

- [x] Task 1: Injection de la base de données dans Riverpod
  - [x] 1a. Créer `lib/core/database/database_provider.dart` (Provider<AppDatabase>)
  - [x] 1b. Modifier `lib/app/view/app.dart` pour override databaseProvider dans ProviderScope

- [x] Task 2: Couche Domaine — interface Repository
  - [x] 2a. Créer `lib/features/recipes/domain/repositories/recipe_repository.dart`

- [x] Task 3: Couche Data — LocalDatasource + RepositoryImpl
  - [x] 3a. Créer `lib/features/recipes/data/datasources/recipe_local_datasource.dart`
  - [x] 3b. Créer `lib/features/recipes/data/repositories/recipe_repository_impl.dart`

- [x] Task 4: Riverpod provider — RecipesNotifier
  - [x] 4a. Créer `lib/features/recipes/presentation/providers/recipes_provider.dart`

- [x] Task 5: Widget RecipeQuickForm (Section 1)
  - [x] 5a. Créer `lib/features/recipes/presentation/widgets/recipe_quick_form.dart`
        (nom + type de repas en chips + temps prep/cuisson/repos + total calculé)

- [x] Task 6: Mise à jour NewRecipePage
  - [x] 6a. Modifier `lib/features/recipes/view/new_recipe_page.dart` pour utiliser RecipeQuickForm + Riverpod save

- [x] Task 7: Mise à jour RecipesPage (liste + état vide)
  - [x] 7a. Modifier `lib/features/recipes/view/recipes_page.dart` pour afficher la liste avec RecipeCard et état vide

- [x] Task 8: Mise à jour Router (route detail optionnelle)
  - [x] 8a. Navigation post-création : `context.go(AppRoutes.recipes)` + Snackbar confirmation

- [x] Task 9: Tests
  - [x] 9a. Créer `test/features/recipes/data/repositories/recipe_repository_test.dart` (7 tests, 100% pass)

## Dev Notes

### Contexte Technique
- **DB locale**: drift — `Recipes` table existe, génère `Recipe` data class + `RecipesCompanion` + `$RecipesTable`
- **MealTypes valides**: breakfast, lunch, dinner, snack, dessert
- **UUID**: package `uuid` → `const Uuid().v4()`
- **Riverpod**: AsyncNotifierProvider pour les actions, StreamProvider pour la liste
- **Provider database**: Pattern override dans ProviderScope — `databaseProvider.overrideWithValue(database)`
- **Navigation post-création**: `context.go(AppRoutes.recipes)` depuis NewRecipePage + SnackBar succès

### Architecture
- Pattern Repository respecté : UI → Provider → Repository → Datasource → drift
- Zéro cross-import entre features
- Tests en mémoire drift (NativeDatabase.memory())

## Dev Agent Record

### Implementation Plan
Story 2.1 implémente la création de recette basique end-to-end :
1. `databaseProvider` + override ProviderScope dans App
2. Couche domain : `RecipeRepository` (interface abstraite)
3. Couche data : `RecipeLocalDatasource` (drift) + `RecipeRepositoryImpl`
4. Riverpod : `recipesStreamProvider` (stream) + `recipesNotifierProvider` (actions)
5. `RecipeQuickForm` : nom + MealType chips + temps prep/cuisson/repos + total auto
6. `NewRecipePage` refactorisée : formulaire complet + save + navigation vers `/recipes`
7. `RecipesPage` refactorisée : liste drift stream + état vide "Commence par ajouter..."
8. `main_staging.dart` + `app_test.dart` mis à jour pour la nouvelle signature `App`
9. 7 tests unitaires repository + 1 test widget App = 15 tests total, 0 régression

### Completion Notes
✅ Tous les ACs de la Story 2.1 satisfaits
✅ 15/15 tests passent (7 nouveaux + 8 existants)
✅ 0 nouveau warning introduit (18 warnings pré-existants Epic 1 inchangés)
✅ Architecture respectée : domain/data/presentation + Repository pattern
✅ UUID v4 pour tous les IDs (validé par tests)
✅ drift local = source de vérité, stream réactif pour la liste
✅ RecipeQuickForm : formulaire accessible, touch targets ≥ 48px, Nunito+MD3

## File List

**Créés:**
- `lib/core/database/database_provider.dart`
- `lib/features/recipes/domain/repositories/recipe_repository.dart`
- `lib/features/recipes/data/datasources/recipe_local_datasource.dart`
- `lib/features/recipes/data/repositories/recipe_repository_impl.dart`
- `lib/features/recipes/presentation/providers/recipes_provider.dart`
- `lib/features/recipes/presentation/widgets/recipe_quick_form.dart`
- `test/features/recipes/data/repositories/recipe_repository_test.dart`

**Modifiés:**
- `lib/app/view/app.dart` — injection databaseProvider dans ProviderScope
- `lib/features/recipes/view/new_recipe_page.dart` — formulaire complet avec RecipeQuickForm
- `lib/features/recipes/view/recipes_page.dart` — liste drift stream + état vide
- `lib/main_staging.dart` — signature App mise à jour
- `test/app/view/app_test.dart` — test mis à jour (signature App + smoke test)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — epic-1 → done, 2-1 → in-progress

## Change Log

- 2026-02-21 : Story 2.1 implémentée — création de fiche recette basique (CRUD local drift, RecipeQuickForm, liste réactive Riverpod)
