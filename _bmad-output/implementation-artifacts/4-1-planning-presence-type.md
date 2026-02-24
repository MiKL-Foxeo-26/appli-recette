# Story 4.1 : Configurer le Planning de Présence Type

Status: done

## Story

En tant qu'utilisateur,
Je veux définir un planning de présence type pour chaque membre de mon foyer,
Afin que l'app sache automatiquement qui est présent à chaque repas par défaut.

## Acceptance Criteria

1. **Given** je suis sur l'écran Planning **When** je configure le planning type **Then** une grille PresenceToggleGrid affiche les membres en lignes et les jours/repas en colonnes (7 jours × midi/soir) (FR23)
2. **Given** la grille est affichée **When** je tape sur un toggle de présence **Then** la présence de ce membre pour ce créneau (jour + repas) est activée/désactivée immédiatement (FR23)
3. **Given** je modifie un toggle **Then** le changement est persisté dans drift (table `presence_schedules` avec `weekKey = null` pour le planning type) (NFR4)
4. **Given** aucun planning type n'existe **When** j'ouvre l'écran Planning **Then** l'état vide affiche une invitation à configurer les présences avec tous les toggles à `true` par défaut
5. **Given** des membres existent dans le foyer **Then** chaque membre apparaît comme une ligne de la grille avec son nom
6. **Given** aucun membre dans le foyer **Then** un message invite à ajouter des membres en premier, avec un lien vers l'écran Foyer

## Tasks / Subtasks

- [x] Task 1 : Créer le datasource local pour les présences (AC: 3)
  - [x] 1.1 Créer `lib/features/planning/data/datasources/presence_local_datasource.dart` — Provider Riverpod qui expose les opérations CRUD sur `PresenceSchedules` via drift
  - [x] 1.2 Méthodes : `watchDefaultSchedule()` (Stream, weekKey == null), `togglePresence(memberId, dayOfWeek, mealSlot)`, `initDefaultScheduleForMember(memberId)` (crée 14 entrées : 7 jours × 2 repas, toutes `isPresent = true`)
  - [x] 1.3 Méthode `deleteSchedulesForMember(memberId)` — déjà géré par CASCADE, mais garder pour cohérence API

- [x] Task 2 : Créer le repository planning (AC: 3)
  - [x] 2.1 Créer `lib/features/planning/domain/repositories/planning_repository.dart` — interface abstraite
  - [x] 2.2 Créer `lib/features/planning/data/repositories/planning_repository_impl.dart` — implémentation concrète utilisant le datasource
  - [x] 2.3 Méthodes repository : `watchDefaultPresences()`, `togglePresence(memberId, dayOfWeek, mealSlot)`, `initializeDefaultForMember(memberId)`

- [x] Task 3 : Créer les providers Riverpod (AC: 2, 3, 4, 5, 6)
  - [x] 3.1 Créer `lib/features/planning/presentation/providers/planning_provider.dart`
  - [x] 3.2 `presenceLocalDatasourceProvider` — accès au datasource
  - [x] 3.3 `planningRepositoryProvider` — accès au repository
  - [x] 3.4 `defaultPresencesStreamProvider` — StreamProvider des présences type (weekKey == null)
  - [x] 3.5 `planningNotifierProvider` — AsyncNotifier avec actions : `togglePresence(memberId, dayOfWeek, mealSlot)`, `initializeForNewMember(memberId)`, `initializeMissingMembers(members)`

- [x] Task 4 : Widget PresenceToggleGrid (AC: 1, 2, 5)
  - [x] 4.1 Créer `lib/features/planning/presentation/widgets/presence_toggle_grid.dart` — ConsumerWidget
  - [x] 4.2 Layout : en-tête colonnes (Lun-Dim × Midi/Soir = 14 colonnes), lignes = membres
  - [x] 4.3 Chaque cellule = Checkbox Material 3, couleur primary (#E8794A) quand actif
  - [x] 4.4 Tap sur un toggle → appelle `planningNotifierProvider.togglePresence()`
  - [x] 4.5 Scroll horizontal via SingleChildScrollView + DataTable
  - [x] 4.6 Labels accessibles : `Semantics(label: "Présence de {nom} — {jour} {repas}")` (WCAG AA)
  - [x] 4.7 En-têtes jours abrégés : Lun, Mar, Mer, Jeu, Ven, Sam, Dim
  - [x] 4.8 Sous-colonnes Midi / Soir sous chaque jour

- [x] Task 5 : Refonte PlanningPage (AC: 1, 4, 6)
  - [x] 5.1 Remplacer le placeholder `planning_page.dart` par un écran complet ConsumerStatefulWidget
  - [x] 5.2 Titre AppBar : "Planning de présence"
  - [x] 5.3 `ref.watch(membersStreamProvider)` pour les membres + `ref.watch(defaultPresencesStreamProvider)` pour les présences
  - [x] 5.4 État vide (pas de membres) : message "Ajoute les membres de ton foyer" + bouton vers `/household`
  - [x] 5.5 État normal : affiche PresenceToggleGrid avec les données
  - [x] 5.6 État loading : CircularProgressIndicator centré
  - [x] 5.7 État erreur : message d'erreur Material 3

- [x] Task 6 : Initialisation automatique des présences pour les membres existants (AC: 4)
  - [x] 6.1 Quand l'écran Planning charge et qu'il y a des membres mais aucune entrée `presence_schedules` avec `weekKey == null` pour un membre → auto-initialiser (14 entrées × isPresent = true)
  - [x] 6.2 Intégré dans `PlanningNotifier.initializeMissingMembers()` — appelé depuis `PlanningPage` via `addPostFrameCallback`

- [x] Task 7 : Barrel export + route vérification
  - [x] 7.1 Créé `lib/features/planning/planning.dart` barrel export
  - [x] 7.2 Route `/planning` dans `app_router.dart` pointe déjà vers `PlanningPage` — aucune modification nécessaire

- [x] Task 8 : Tests (AC: 1-6)
  - [x] 8.1 Tests unitaires datasource : `test/features/planning/data/datasources/presence_local_datasource_test.dart` — 11 tests (Story 4.1)
  - [x] 8.2 Tests unitaires repository : `test/features/planning/data/repositories/planning_repository_test.dart` — 4 tests (Story 4.1)
  - [x] 8.3 Test toggle : créer une présence, toggle → isPresent passe de true à false
  - [x] 8.4 Test init : nouveau membre → 14 entrées créées avec isPresent = true
  - [x] 8.5 Test stream : modification → stream émet la nouvelle valeur
  - [x] 8.6 Widget test PresenceToggleGrid : `test/features/planning/presentation/widgets/presence_toggle_grid_test.dart` — 9 tests (ajoutés par code review)

### Review Follow-ups (AI) — Résolus

- [x] [AI-Review][HIGH] Race condition dans `_DefaultModeContent` — refactorisé en `ConsumerStatefulWidget` avec gestion d'erreur [`planning_page.dart`]
- [x] [AI-Review][HIGH] Cross-feature import `household` → `planning` — créé `core/providers/member_providers.dart` comme bridge [`planning_page.dart:2`]
- [x] [AI-Review][HIGH] Widget tests manquants — 9 tests ajoutés [`presence_toggle_grid_test.dart`]
- [x] [AI-Review][MEDIUM] Scope overlap documenté — Stories 4.1 et 4.2 co-implémentées (voir note ci-dessous)

## Dev Notes

### Architecture Feature Planning

Structure créée suivant le pattern feature-first identique à `household/` :

```
lib/features/planning/
├── data/
│   ├── datasources/
│   │   └── presence_local_datasource.dart
│   ├── repositories/
│   │   └── planning_repository_impl.dart
│   └── utils/
│       └── week_utils.dart          (co-implémenté avec Story 4.2)
├── domain/
│   └── repositories/
│       └── planning_repository.dart
├── presentation/
│   ├── providers/
│   │   └── planning_provider.dart
│   └── widgets/
│       ├── presence_toggle_grid.dart
│       └── week_selector.dart       (co-implémenté avec Story 4.2)
├── view/
│   └── planning_page.dart   (refonte complète, mode type + mode semaine)
└── planning.dart          (barrel export)
```

### Co-implémentation Stories 4.1 et 4.2

**Note importante :** Les stories 4.1 et 4.2 ont été implémentées ensemble dans les mêmes fichiers. Chaque fichier contient du code pour les deux stories :
- `presence_local_datasource.dart` : méthodes planning type (4.1) + méthodes weekly overrides (4.2)
- `planning_repository.dart` / `planning_repository_impl.dart` : interface et implémentation couvrant les deux stories
- `planning_provider.dart` : providers et notifier pour les deux modes
- `planning_page.dart` : `SegmentedButton` avec mode "Planning type" (4.1) et mode "Semaine" (4.2)
- `presence_toggle_grid.dart` : supporte les deux modes via le paramètre `weekKey`
- Les fichiers de test couvrent les deux stories dans des groups séparés

Le code Story 4.2 dans ces fichiers est évalué dans la review de la story 4-2.

### Schema drift existant — PresenceSchedules

La table est **déjà définie** dans `lib/core/database/tables/presence_schedules_table.dart` :

```dart
class PresenceSchedules extends Table {
  TextColumn get id => text()();                    // UUID v4
  TextColumn get memberId => text()
    .references(Members, #id, onDelete: KeyAction.cascade)();
  IntColumn get dayOfWeek => integer()();            // 1=lundi, 7=dimanche
  TextColumn get mealSlot => text()();               // "lunch" ou "dinner"
  BoolColumn get isPresent => boolean()
    .withDefault(const Constant(true))();
  TextColumn get weekKey => text().nullable()();      // null = planning type

  @override
  Set<Column<Object>> get primaryKey => {id};
}
```

**Convention clé :** `weekKey == null` signifie **planning type** (cette story). `weekKey == "2026-W08"` signifie **override hebdomadaire** (Story 4.2).

### Project Structure Notes

- Convention `view/` conservée pour la cohérence avec `recipes/` et `household/`
- Pas de modèle custom — classes drift générées (`PresenceSchedule` dans `app_database.g.dart`)
- Import cross-feature résolu via `core/providers/member_providers.dart` (bridge)

### References

- [Source: epics.md#Story 4.1] — AC complets, PresenceToggleGrid, FR23
- [Source: ux-design-specification.md#Component Strategy] — PresenceToggleGrid spec
- [Source: architecture.md#Frontend Architecture] — Structure feature-first, Riverpod patterns
- [Source: architecture.md#Data Architecture] — drift source de vérité locale, UUID v4
- [Source: project-context.md] — Règles critiques agents IA

## Dev Agent Record

### Agent Model Used

claude-opus-4-6

### Debug Log References

N/A — tous les tests passent.

### Completion Notes List

- Datasource `PresenceLocalDatasource` créé avec `watchDefaultSchedule()`, `initDefaultScheduleForMember()`, `togglePresence()`, `deleteSchedulesForMember()`, `getMembersWithDefaultSchedule()`
- Repository pattern complet : interface `PlanningRepository` + implémentation `PlanningRepositoryImpl`
- Providers Riverpod : `presenceLocalDatasourceProvider`, `planningRepositoryProvider`, `defaultPresencesStreamProvider`, `planningNotifierProvider`
- Widget `PresenceToggleGrid` : DataTable avec Checkbox Material 3, scroll horizontal, Semantics WCAG AA
- `PlanningPage` refaite : 3 états (loading, vide sans membres, normal avec grille), auto-init des présences manquantes
- Barrel export `planning.dart` créé
- Route `/planning` déjà configurée dans `app_router.dart` — aucune modification
- Tests unitaires Story 4.1 : 11 datasource + 4 repository = 15 tests
- Tests widget : 9 tests (PresenceToggleGrid) — ajoutés par code review
- Tests unitaires Story 4.2 : 8 datasource + 6 repository = 14 tests (co-implémentés, revus dans story 4-2)
- Aucune régression sur les tests existants (40 tests non-recipes passent)
- Erreurs pré-existantes dans `recipes/` (paramètre `escape` drift) — non liées à cette story

### Code Review Fixes Applied

1. **Race condition corrigée** : `_DefaultModeContent` refactorisé de `ConsumerWidget` à `ConsumerStatefulWidget` avec `_initTriggered` flag géré localement, `try/catch` sur `initializeMissingMembers()`, et état d'erreur affiché si l'init échoue
2. **Cross-feature import résolu** : `planning_page.dart` importe désormais `core/providers/member_providers.dart` au lieu de `features/household/household.dart`
3. **Widget tests ajoutés** : 9 tests dans `test/features/planning/presentation/widgets/presence_toggle_grid_test.dart` couvrant rendu grille, checkboxes, Semantics, et interaction toggle
4. **Story file mis à jour** : File List complétée, test counts corrigés, co-implémentation 4.1/4.2 documentée

### File List

- `lib/features/planning/data/datasources/presence_local_datasource.dart` (créé)
- `lib/features/planning/data/repositories/planning_repository_impl.dart` (créé)
- `lib/features/planning/domain/repositories/planning_repository.dart` (créé)
- `lib/features/planning/presentation/providers/planning_provider.dart` (créé)
- `lib/features/planning/presentation/widgets/presence_toggle_grid.dart` (créé)
- `lib/features/planning/presentation/widgets/week_selector.dart` (créé — Story 4.2)
- `lib/features/planning/data/utils/week_utils.dart` (créé — Story 4.2)
- `lib/features/planning/view/planning_page.dart` (modifié — refonte complète)
- `lib/features/planning/planning.dart` (créé)
- `lib/core/providers/member_providers.dart` (créé — bridge cross-feature, code review)
- `test/features/planning/data/datasources/presence_local_datasource_test.dart` (créé)
- `test/features/planning/data/repositories/planning_repository_test.dart` (créé)
- `test/features/planning/presentation/widgets/presence_toggle_grid_test.dart` (créé — code review)
