# Story 3.2 : Noter les Préférences d'un Membre par Recette

Status: done

## Story

En tant qu'utilisateur,
Je veux enregistrer les préférences de chaque membre pour chaque recette,
Afin que l'algorithme de génération respecte les goûts de chacun.

## Acceptance Criteria

1. **Given** je suis sur la fiche d'une recette avec des membres dans mon foyer **When** je consulte la section Préférences **Then** chaque membre est affiché avec des chips de notation via `MemberRatingRow` : Aimé / Neutre / Pas aimé (FR20)
2. **Given** je tape sur un chip **Then** la notation est sélectionnée de façon exclusive pour ce membre sur cette recette et persistée dans drift (table `meal_ratings`) (NFR4)
3. **Given** une notation existante **When** je tape sur un chip différent **Then** la notation est mise à jour immédiatement dans drift (FR21)
4. **Given** aucun membre dans le foyer **Then** la section Préférences n'affiche pas de `MemberRatingRow` (section absente ou message "Ajoute des membres dans l'onglet Foyer")
5. **Given** les chips de notation **Then** les couleurs respectent la palette : Aimé fond #FFE0CC texte #E8794A, Neutre fond #F0F0F0 texte #757575, Pas aimé fond #E8EAF6 texte #5C6BC0

## Tasks / Subtasks

- [x] Task 1 : Modèle MealRating + repository (AC: 2, 3)
  - [x] 1.1 Créé `lib/features/household/data/models/rating_value.dart` — enum `RatingValue { liked, neutral, disliked }` avec `dbValue`, `fromDb`, `label`, `emoji`
  - [x] 1.2 `MealRating` utilisé directement depuis drift (généré depuis `MealRatings` table)
  - [x] 1.3 Étendu `HouseholdRepository` : `watchRatingsForRecipe`, `upsertRating`, `deleteRatingsForRecipe`
  - [x] 1.4 Créé `lib/features/household/data/datasources/meal_rating_datasource.dart` — upsert two-step (update then insert)
  - [x] 1.5 Vérifié : `MealRatings` — id PK, memberId FK cascade, recipeId FK cascade, rating TEXT, updatedAt, isSynced

- [x] Task 2 : Provider ratings (AC: 2, 3)
  - [x] 2.1 Ajouté `recipeRatingsProvider` : `StreamProvider.family<List<MealRating>, String>` (réactivité automatique)
  - [x] 2.2 Ajouté `upsertRating()` dans `HouseholdNotifier`
  - [x] 2.3 Réactivité gérée automatiquement via `StreamProvider` — pas besoin d'invalidation manuelle

- [x] Task 3 : Widget MemberRatingRow (AC: 1, 2, 3, 5)
  - [x] 3.1 Créé `lib/features/household/presentation/widgets/member_rating_row.dart`
  - [x] 3.2 Avatar initiales + prénom + 3 chips avec emoji
  - [x] 3.3 Palette exacte : Aimé #FFE0CC/#E8794A, Neutre #F0F0F0/#757575, Pas aimé #E8EAF6/#5C6BC0
  - [x] 3.4 Mode direct-persist (recipeId fourni) + mode callback (onRatingChanged fourni) — Story 3.3 ready
  - [x] 3.5 Semantics sur la ligne et sur chaque chip
  - [x] 3.6 Touch target ≥ 48×48px via `BoxConstraints(minWidth: 48, minHeight: 48)`

- [x] Task 4 : Section Préférences dans RecipeDetailScreen (AC: 1, 4)
  - [x] 4.1 Ajouté `_PreferencesSection` dans `lib/features/recipes/view/recipe_detail_screen.dart`
  - [x] 4.2 Watch `membersStreamProvider` + `recipeRatingsProvider(recipeId)` — double `AsyncValue.when`
  - [x] 4.3 Affiche un `MemberRatingRow` par membre avec sa notation courante
  - [x] 4.4 Si aucun membre : "Ajoute des membres dans l'onglet Foyer"

- [x] Task 5 : Tests (AC: 1–5)
  - [x] 5.1 Ajouté dans `test/features/household/data/repositories/household_repository_test.dart`
  - [x] 5.2 5 tests ratings : liste vide, upsert create, upsert update, multi-membres, RatingValue round-trip — **15/15 ✅**

## Dev Notes

### Feature location
- Widget : `lib/features/household/presentation/widgets/member_rating_row.dart`
- Modèle : `lib/features/household/data/models/meal_rating.dart`
- Ce widget est **utilisé dans** `features/recipes/presentation/screens/recipe_detail_screen.dart`

### ⚠️ Cross-feature widget usage
Le widget `MemberRatingRow` appartient à `features/household/`. Pour l'utiliser dans `features/recipes/`, deux approches valides :
1. **Préféré** : exposer `MemberRatingRow` via `lib/features/household/household.dart` (barrel export) et importer depuis recipes
2. Déplacer vers `lib/core/widgets/` si réutilisé ailleurs aussi
**INTERDIT** : import direct `../../household/presentation/widgets/member_rating_row.dart` depuis recipes sans barrel file.

### Modèle MealRating
```dart
enum RatingValue { liked, neutral, disliked }

class MealRating {
  final String id;       // UUID v4
  final String memberId; // FK → members.id
  final String recipeId; // FK → recipes.id
  final RatingValue rating;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### UPSERT drift — pattern obligatoire
```dart
// Dans le DAO drift — INSERT OR REPLACE sur (member_id, recipe_id)
Future<void> upsertRating(MealRating rating) async {
  await into(ratingsTable).insertOnConflictUpdate(
    RatingsTableCompanion(
      id: Value(rating.id),
      memberId: Value(rating.memberId),
      recipeId: Value(rating.recipeId),
      ratingValue: Value(rating.rating.name),
      updatedAt: Value(DateTime.now().toIso8601String()),
    ),
  );
}
```

### Palette chips — EXACTE (AC5)
```dart
// Aimé
Color liked Bg    = Color(0xFFFFE0CC);
Color liked Text  = Color(0xFFE8794A);
// Neutre
Color neutralBg   = Color(0xFFF0F0F0);
Color neutralText = Color(0xFF757575);
// Pas aimé
Color dislikedBg  = Color(0xFFE8EAF6);
Color dislikedText= Color(0xFF5C6BC0);
```

### Provider family pattern
```dart
final recipeRatingsProvider = FutureProvider.family<List<MealRating>, String>(
  (ref, recipeId) async {
    final repo = ref.watch(householdRepositoryProvider);
    return repo.getRatingsForRecipe(recipeId);
  },
);
```

### UUID pour nouvelle notation
```dart
final String id = const Uuid().v4();
```

### Accès concurrent membres + ratings dans recipe_detail
```dart
final membersAsync = ref.watch(householdProvider);
final ratingsAsync = ref.watch(recipeRatingsProvider(recipe.id));

// Joindre les données
return membersAsync.when(
  loading: () => const CircularProgressIndicator(),
  error: (e, _) => ErrorWidget(e.toString()),
  data: (members) => ratingsAsync.when(
    loading: () => const CircularProgressIndicator(),
    error: (e, _) => ErrorWidget(e.toString()),
    data: (ratings) {
      return Column(
        children: members.map((m) {
          final rating = ratings.firstWhereOrNull((r) => r.memberId == m.id);
          return MemberRatingRow(member: m, currentRating: rating?.rating);
        }).toList(),
      );
    },
  ),
);
```

### Impact algorithme génération (Epic 5)
Les `meal_ratings` créées ici sont le carburant de l'algorithme (FR29, FR30) :
- `disliked` → recette exclue si ce membre est présent au repas
- `liked` → recette priorisée si ce membre est présent
Le schéma `meal_ratings` doit être stable avant Epic 5.

### Project Structure Notes
- Respecter les frontières features — pas de cross-import direct
- Tests miroir : `test/features/household/` reflète `lib/features/household/`

### References
- [Source: architecture.md#Communication Patterns] — Repository pattern, upsert
- [Source: architecture.md#Format Patterns] — UUID v4, AsyncValue pattern
- [Source: epics.md#Story 3.2] — AC complets, MemberRatingRow
- [Source: ux-design-specification.md#Custom Components] — MemberRatingRow spec
- [Source: ux-design-specification.md#Visual Design Foundation] — Palette chips notation
- [Source: architecture.md#Frontend Architecture] — Frontières features

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

N/A — 15/15 tests passent.

### Completion Notes List

- `MealRating` drift-généré utilisé directement (pas de fichier modèle séparé)
- Upsert implémenté en two-step (update → insert si 0 rows) pour compatibilité avec unique key (memberId, recipeId)
- `StreamProvider.family` utilisé à la place de `FutureProvider.family` pour réactivité automatique
- `MemberRatingRow` supporte deux modes via `onRatingChanged` callback (Story 3.3 ready)
- Barrel file `lib/features/household/household.dart` créé pour cross-feature imports propres
- 2 erreurs pré-existantes Epic 2 non causées par cette story

### File List

- `lib/features/household/data/models/rating_value.dart` (créé)
- `lib/features/household/data/datasources/meal_rating_datasource.dart` (créé)
- `lib/features/household/domain/repositories/household_repository.dart` (étendu)
- `lib/features/household/data/repositories/household_repository_impl.dart` (étendu)
- `lib/features/household/presentation/providers/household_provider.dart` (étendu)
- `lib/features/household/presentation/widgets/member_rating_row.dart` (créé)
- `lib/features/household/household.dart` (créé — barrel)
- `lib/features/recipes/view/recipe_detail_screen.dart` (étendu — section Préférences)
- `test/features/household/data/repositories/household_repository_test.dart` (étendu — 5 tests ratings)
