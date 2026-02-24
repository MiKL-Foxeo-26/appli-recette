# Story 5.1 : Service de Génération — Algorithme Multi-Critères

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story

En tant qu'utilisateur,
Je veux que l'algorithme de génération produise un menu pertinent respectant les présences et préférences,
Afin de pouvoir valider le menu sans le modifier manuellement à chaque fois.

---

## Acceptance Criteria

1. **Given** des recettes dans ma collection, des membres avec notations, et un planning de présence configuré — **When** la génération est lancée pour une semaine — **Then** le `GenerationService` (classe pure Dart dans `features/generation/domain/services/`) applique ces 6 couches séquentielles dans cet ordre exact :
   - Couche 1 : Filtrer les recettes selon le **type de repas** (lunch / dinner) ET les **présences du créneau** (FR27)
   - Couche 2 : Exclure les recettes notées **pas-aimé** par au moins un membre présent au créneau (FR29)
   - Couche 3 : Prioriser les recettes **favorites** (`isFavorite = true`) (FR28)
   - Couche 4 : Prioriser les recettes **aimées** (`loved`) par les membres présents (FR30)
   - Couche 5 : Anti-répétition — écarter les recettes figurant dans les **menus validés des semaines précédentes** (FR31)
   - Couche 6 : Compléter **aléatoirement** avec les recettes restantes (seed reproductible pour les tests) (FR26)

2. **And** l'exécution complète de la génération pour une semaine entière (14 créneaux max) prend **moins de 2 secondes** sur device standard (NFR1).

3. **And** si aucune recette n'est compatible avec un créneau après application des 6 couches, le créneau reste **null** (génération partielle acceptable — FR36 sera traité en Story 5.6).

4. **And** des **tests unitaires** couvrent chaque couche dans `test/features/generation/domain/services/generation_service_test.dart` — minimum un test de validation et un test de rejet par couche.

5. **And** le service accepte un paramètre `GenerationFilters` (optionnel) contenant `maxPrepTime`, `vegetarianOnly`, `season` — ces filtres sont appliqués comme une **sous-couche de la Couche 1** (pré-filtrage avant les couches 2–6) — l'API est conçue pour Story 5.3 sans en implémenter l'UI.

6. **And** le service expose une méthode `generateMenu(GenerationInput input) → List<MenuSlot?>` qui retourne une liste de 14 entrées (`MenuSlot?`) correspondant à 7 jours × 2 repas (lunch/dinner) dans cet ordre : lundi-midi, lundi-soir, mardi-midi, …, dimanche-soir.

---

## Tasks / Subtasks

- [x] **Task 1 — Définir les modèles de domaine** (AC: #1, #6)
  - [x] Créer `lib/features/generation/domain/models/generation_input.dart`
  - [x] Créer `lib/features/generation/domain/models/generation_filters.dart` avec copyWith
  - [x] Créer `lib/features/generation/domain/models/meal_slot_result.dart` avec `isSpecialEvent`
  - [x] Créer `lib/features/recipes/domain/models/season.dart` (enum Season manquant)

- [x] **Task 2 — Implémenter `GenerationService`** (AC: #1, #2, #3, #5, #6)
  - [x] Créer `lib/features/generation/domain/services/generation_service.dart`
  - [x] 6 couches séquentielles implémentées
  - [x] Random injectable pour reproductibilité en test
  - [x] Set<String> usedRecipeIds pour déduplication intra-génération
  - [x] Slots verrouillés ignorés via `lockedSlotIndices`

- [x] **Task 3 — Écrire les tests unitaires** (AC: #4)
  - [x] Créer `test/features/generation/domain/services/generation_service_test.dart`
  - [x] Tous les groupes de tests implémentés (couches 1-6, filtres, performance, intégration)

- [x] **Task 4 — Exposer via Provider Riverpod** (AC: #6)
  - [x] `generation_provider.dart` avec `GenerateMenuNotifier` (AsyncNotifierProvider)
  - [x] `GeneratedMenuState` avec slots, weekKey, lockedSlotIndices, isValidated
  - [x] Méthodes : generate(), toggleLock(), replaceSlot(), clearSlot(), setSpecialEvent(), markValidated(), reset()

- [x] **Task 5 — Vérification intégration** (AC: #1, #2)
  - [x] GenerationService : zéro import Flutter/Material, 100% Dart pur
  - [x] Provider lit via recipesStreamProvider, membersStreamProvider, mergedPresencesStreamProvider, allRatingsStreamProvider, previousMenuSlotsProvider

---

## Dev Notes

### Contexte Architectural Clé

**Le `GenerationService` est la pièce centrale de cet Epic.** Il doit être une classe Dart pure — zéro import Flutter, zéro dépendance UI, 100% testable unitairement. C'est la seule entité de l'app qui a accès cross-feature (recettes, household, planning) via ses paramètres d'entrée — jamais via import direct.

**Algorithme exact défini dans l'architecture :**
```
1. Filtrer recettes selon présences du repas
2. Exclure "pas aimé" des membres présents
3. Prioriser favoris
4. Prioriser "aimé" des membres présents
5. Anti-répétition (historique menus validés)
6. Appliquer filtres utilisateur (saison / végé / temps max)   ← ici "filtres" = couche 1bis dans notre story
7. Compléter aléatoirement (seed reproductible) si besoin
8. Génération partielle + messages guidants si stock insuffisant  ← Story 5.6
```

> Note : L'architecture liste 8 sous-étapes mais les étapes 6-8 sont traitées séparément (filtres = Story 5.3 UI, partielle = Story 5.6). Cette story implémente les couches 1–5+6(complétion) + l'API pour les filtres.

### Emplacements Fichiers (obligatoires)

| Fichier | Chemin |
|---------|--------|
| Service principal | `lib/features/generation/domain/services/generation_service.dart` |
| Modèle input | `lib/features/generation/domain/models/generation_input.dart` |
| Modèle filtres | `lib/features/generation/domain/models/generation_filters.dart` |
| Modèle résultat slot | `lib/features/generation/domain/models/meal_slot_result.dart` |
| Provider génération | `lib/features/generation/presentation/providers/generation_provider.dart` |
| Tests service | `test/features/generation/domain/services/generation_service_test.dart` |

### Modèles Existants à Réutiliser

Ces modèles ont été créés dans les Epics 1–4. **NE PAS recréer, importer directement :**
- `Recipe` : `lib/features/recipes/data/models/recipe.dart` — champs clés : `id` (String UUID), `mealType` (MealType enum : lunch/dinner/breakfast/snack/dessert), `isFavorite` (bool), `isVegetarian` (bool), `season` (Season? enum), `prepTimeMinutes` (int)
- `Member` : `lib/features/household/data/models/member.dart` — champs clés : `id` (String UUID), `name` (String)
- `MealRating` : `lib/features/household/data/models/meal_rating.dart` — champs clés : `memberId` (String), `recipeId` (String), `rating` (RatingValue enum : loved/neutral/disliked)
- `PresenceSchedule` : `lib/features/planning/data/models/presence_schedule.dart`
- `WeeklyMenu` + `MenuSlot` : `lib/features/generation/data/models/` — peuvent être en cours de création dans cette même Epic

> **Vérifier les noms exacts** des champs et enums dans les fichiers réels avant d'écrire le service — ils peuvent légèrement différer de ce qui est listé ici.

### Pattern Repository pour la collecte de données

Le `generateMenuProvider` doit lire depuis :
```dart
// ✅ Pattern correct — toujours via les providers existants
final recipes = ref.read(recipesProvider).value ?? [];
final members = ref.read(householdProvider).value ?? [];
final ratings = ref.read(ratingsProvider).value ?? [];
final presences = ref.read(planningProvider).value;
final previousMenus = ref.read(menuHistoryProvider).value ?? [];
```
**Jamais d'accès direct à drift ou Supabase dans le service ou le notifier.**

### Pattern UUID

```dart
// ✅ Pour tout nouvel ID créé dans cette story
import 'package:uuid/uuid.dart';
final String id = const Uuid().v4();
```

### Pattern AsyncValue Riverpod

```dart
// ✅ Le generateMenuProvider doit exposer AsyncValue
final generationAsync = ref.watch(generateMenuProvider);
return generationAsync.when(
  loading: () => const CircularProgressIndicator(),
  error: (e, st) => ErrorWidget(e.toString()),
  data: (slots) => WeekGrid(slots: slots),
);
```

### Seed Reproductible pour les Tests

```dart
// ✅ Dans GenerationService — permettre l'injection du Random
class GenerationService {
  final Random _random;
  GenerationService({Random? random}) : _random = random ?? Random();
  // ...
}
// ✅ Dans les tests
final service = GenerationService(random: Random(42)); // seed fixe
```

### Garantie de Déduplication

Dans la boucle sur les 14 créneaux, maintenir un `Set<String> usedRecipeIds` et l'exclure du pool de chaque créneau après sélection. Cela évite qu'une même recette apparaisse deux fois dans la même semaine.

### Performance (NFR1 : < 2s)

L'algorithme opère sur des listes en mémoire (déjà chargées depuis drift) — aucun I/O pendant la génération. Avec ≤ 500 recettes et ≤ 10 membres, les opérations de filtrage/tri sont O(n) à O(n log n) — largement dans les 2 secondes. Le test de performance (Stopwatch) valide cela.

### Project Structure Notes

- Cette story ne touche que `features/generation/` — aucun import cross-feature direct (les données arrivent via les paramètres de `GenerationInput`)
- Le `generateMenuProvider` est dans `presentation/providers/` (il orchestre les providers des autres features via `ref.read`)
- Aucun widget UI créé dans cette story (la WeekGridComponent est Story 5.2)
- Les fichiers `weekly_menu.dart` et `menu_slot.dart` dans `generation/data/models/` peuvent ne pas encore exister — les créer si nécessaire avec les champs minimaux requis par le service

### Références

- Algorithme de génération : [Source: `_bmad-output/planning-artifacts/architecture.md` — Frontend Architecture / Algorithme de génération]
- FR26-FR31 (génération, priorités, anti-répétition) : [Source: `_bmad-output/planning-artifacts/epics.md` — Story 5.1]
- NFR1 (< 2s) : [Source: `_bmad-output/planning-artifacts/epics.md` — NonFunctional Requirements]
- Pattern Repository : [Source: `_bmad-output/planning-artifacts/architecture.md` — Communication Patterns]
- Structure feature-first : [Source: `_bmad-output/planning-artifacts/architecture.md` — Project Structure & Boundaries]
- Emplacement exact du service : [Source: `_bmad-output/planning-artifacts/architecture.md` — Complete Project Directory Structure]
- Tests miroir : [Source: `_bmad-output/planning-artifacts/architecture.md` — Structure Patterns]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6 (create-story workflow)

### Debug Log References

_Aucun pour l'instant._

### Completion Notes List

- Season enum créé dans `lib/features/recipes/domain/models/season.dart` (manquait dans les epics précédents)
- `MealSlotResult` enrichi avec `isSpecialEvent` pour Story 5.4/5.6
- `GeneratedMenuState` classe wrappant la liste de slots + weekKey + lockedSlotIndices + isValidated
- `GenerationInput` utilise `weekKey` (String ISO "YYYY-Www") au lieu de `weekStart` (DateTime) conformément au schéma drift réel
- `allRatingsStreamProvider` ajouté via méthode `watchAll()` ajoutée à `MealRatingDatasource`
- Filtres utilisateur appliqués en Couche 1bis (sous-couche de la Couche 1) comme spécifié

### File List

- `lib/features/recipes/domain/models/season.dart` (créé — Season enum)
- `lib/features/generation/domain/models/generation_filters.dart` (créé)
- `lib/features/generation/domain/models/meal_slot_result.dart` (créé)
- `lib/features/generation/domain/models/generation_input.dart` (créé)
- `lib/features/generation/domain/services/generation_service.dart` (créé)
- `lib/features/household/data/datasources/meal_rating_datasource.dart` (modifié — watchAll())
- `lib/features/generation/presentation/providers/generation_provider.dart` (créé)
- `test/features/generation/domain/services/generation_service_test.dart` (créé)
