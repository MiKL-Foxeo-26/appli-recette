# Story 4.2 : Modifier les Présences d'une Semaine Spécifique

Status: done

## Story

En tant qu'utilisateur,
Je veux modifier ponctuellement les présences d'une semaine donnée,
Afin de refléter les exceptions sans changer le planning type.

## Acceptance Criteria

1. **Given** je suis sur l'écran Planning avec une semaine sélectionnée **When** je modifie les présences pour cette semaine **Then** les overrides ponctuels sont enregistrés séparément du planning type (FR24)
2. **Given** un override existe pour un créneau **Then** le planning type n'est pas modifié par cet override
3. **Given** je suis sur l'écran Planning **When** j'utilise le sélecteur de semaine **Then** je peux naviguer entre les semaines (N-2 à N+8) (FR25)
4. **Given** une semaine est sélectionnée **Then** les présences affichées fusionnent overrides (prioritaires) et planning type (fallback)
5. **Given** des overrides existent pour une semaine **Then** une indication visuelle distingue les overrides du planning type
6. **Given** des overrides existent **When** je tape "Réinitialiser" **Then** tous les overrides de la semaine sont supprimés et on revient au planning type
7. **Given** les overrides sont créés **Then** ils sont persistés dans drift avec `weekKey = "YYYY-Www"` (NFR4)

## Tasks / Subtasks

- [x] Task 1 : Utilitaire weekKey (AC: 3, 7)
  - [x] 1.1 Créer `lib/features/planning/data/utils/week_utils.dart` — fonctions `dateToWeekKey(DateTime)` → `"2026-W09"`, `weekKeyToDateRange(String)` → `(DateTime start, DateTime end)`, `currentWeekKey()`, `weekKeyOffset(String weekKey, int offset)`
  - [x] 1.2 Tests unitaires `test/features/planning/data/utils/week_utils_test.dart` — 14 tests

- [x] Task 2 : Étendre le datasource pour les overrides hebdomadaires (AC: 1, 2, 4, 7)
  - [x] 2.1 Ajouter dans `presence_local_datasource.dart` : `watchWeeklySchedule(String weekKey)` — Stream qui retourne les overrides pour une semaine donnée (weekKey != null)
  - [x] 2.2 Ajouter `toggleWeeklyPresence(String weekKey, String memberId, int dayOfWeek, String mealSlot)` — crée ou modifie un override pour un créneau spécifique
  - [x] 2.3 Ajouter `deleteWeeklyOverrides(String weekKey)` — supprime tous les overrides d'une semaine
  - [x] 2.4 Ajouter `hasWeeklyOverrides(String weekKey)` — retourne true si des overrides existent pour la semaine
  - [x] 2.5 Tests unitaires pour les nouvelles méthodes du datasource — 7 tests

- [x] Task 3 : Étendre le repository planning (AC: 1, 2, 4, 6)
  - [x] 3.1 Ajouter à l'interface `PlanningRepository` : `watchWeeklyPresences(String weekKey)`, `toggleWeeklyPresence(weekKey, memberId, dayOfWeek, mealSlot)`, `resetWeekToDefault(String weekKey)`, `watchMergedPresences(String weekKey)`, `hasWeeklyOverrides(String weekKey)`
  - [x] 3.2 Implémenter dans `PlanningRepositoryImpl` — `watchMergedPresences()` utilise `Rx.combineLatest2` pour fusionner default + overrides (override prioritaire)
  - [x] 3.3 Tests unitaires repository pour les méthodes weekly — 6 tests

- [x] Task 4 : Étendre les providers Riverpod (AC: 1, 3, 4, 6)
  - [x] 4.1 Ajouter `selectedWeekKeyProvider` — `NotifierProvider<SelectedWeekKeyNotifier, String>` (Riverpod 3 pattern, initialisé à semaine courante)
  - [x] 4.2 `mergedPresencesStreamProvider` — `StreamProvider.family<List<PresenceSchedule>, String>` qui retourne les présences fusionnées
  - [x] 4.3 `weeklyOverridesExistProvider` — `FutureProvider.family<bool, String>` + `weeklyOverridesStreamProvider` pour les overrides bruts
  - [x] 4.4 Ajouter actions au `PlanningNotifier` : `toggleWeeklyPresence()`, `resetWeekToDefault()` avec invalidation du cache

- [x] Task 5 : Widget WeekSelector (AC: 3)
  - [x] 5.1 Créer `lib/features/planning/presentation/widgets/week_selector.dart` — ConsumerWidget
  - [x] 5.2 Affichage : "Semaine du {lundi} au {dimanche}" avec flèches ‹ › de navigation
  - [x] 5.3 Tap sur le label → DatePicker pour sélection de semaine
  - [x] 5.4 Limites : N-2 à N+8 semaines, semaine courante par défaut
  - [x] 5.5 Met à jour `selectedWeekKeyProvider` via `SelectedWeekKeyNotifier.select()`

- [x] Task 6 : Adapter PresenceToggleGrid pour les overrides (AC: 1, 4, 5)
  - [x] 6.1 Ajouter paramètre `weekKey` (String?) à PresenceToggleGrid
  - [x] 6.2 Ajouter paramètre `overrideSlots` (Set<String>) — clés "memberId|dayOfWeek|mealSlot" des créneaux override
  - [x] 6.3 Distinction visuelle : fond `#FFF8E1` et bordure accentuée via `_PresenceCell` widget
  - [x] 6.4 Tap toggle en mode semaine → appelle `toggleWeeklyPresence()` au lieu de `togglePresence()`

- [x] Task 7 : Refonte PlanningPage pour le mode semaine (AC: 1, 3, 4, 5, 6)
  - [x] 7.1 SegmentedButton "Planning type" | "Semaine" avec enum `_PlanningMode`
  - [x] 7.2 Mode "Planning type" : `_DefaultModeContent` — comportement Story 4.1 inchangé
  - [x] 7.3 Mode "Semaine" : `_WeekModeContent` — WeekSelector + PresenceToggleGrid avec données fusionnées
  - [x] 7.4 Bouton "Réinitialiser à planning type" visible uniquement si overrides existent (via pattern matching `AsyncData`)
  - [x] 7.5 Badge "Cette semaine" dans WeekSelector quand semaine courante sélectionnée

- [x] Task 8 : Barrel export + vérifications (AC: all)
  - [x] 8.1 `planning.dart` barrel export mis à jour avec `week_utils.dart` et `week_selector.dart`
  - [x] 8.2 `flutter analyze lib/features/planning/` : 0 erreurs, 0 warnings (infos stylistiques uniquement)

- [x] Task 9 : Tests (AC: 1-7)
  - [x] 9.1 Tests unitaires week_utils : 14 tests (conversions, limites, offsets, passage d'année)
  - [x] 9.2 Tests unitaires datasource weekly : 7 tests (toggle crée override, toggle bascule, isolation type, watch vide, delete, hasOverrides, cross-week)
  - [x] 9.3 Tests unitaires repository : 6 tests (merge default, merge override, type isolation, reset, hasOverrides, watchWeekly)
  - [x] 9.4 Test : toggle weekly ne modifie pas le planning type ✅ (datasource + repository)
  - [x] 9.5 Test : resetWeekToDefault supprime les overrides ✅
  - [x] 9.6 Test : merged presences retourne override quand existe, default sinon ✅

## Dev Notes

### Architecture Feature Planning — Extension Weekly Override

La Story 4.1 a créé la base du planning de présence type. Cette story étend le système avec les overrides hebdomadaires.

**Convention weekKey :**
- `null` = planning type (Story 4.1) — NE PAS MODIFIER
- `"2026-W09"` = override semaine 9 de 2026 (format ISO 8601)

**Logique de fusion (merge) :**
Pour un créneau donné (memberId, dayOfWeek, mealSlot) et une semaine weekKey :
1. Chercher override (weekKey = "2026-W09")
2. Si override existe → utiliser `override.isPresent`
3. Sinon → fallback sur planning type (weekKey = null)

**Toggle weekly :**
- Si aucun override n'existe pour ce créneau → copier la valeur du planning type, puis la basculer
- Si un override existe → basculer sa valeur

**Table drift existante :** `PresenceSchedules` (déjà utilisée par Story 4.1)
- Colonne `weekKey` nullable = clé de partition type vs override
- Pas de migration nécessaire, la table gère déjà les deux cas

**Dépendance ajoutée :** `rxdart ^0.28.0` — pour `Rx.combineLatest2` dans `watchMergedPresences()`

### Fichiers de Story 4.1 étendus (SANS CASSER)

- `presence_local_datasource.dart` — 4 nouvelles méthodes weekly ajoutées, méthodes default intactes
- `planning_repository.dart` — 5 nouvelles méthodes à l'interface
- `planning_repository_impl.dart` — implémentations avec rxdart pour merge
- `planning_provider.dart` — 4 nouveaux providers + 2 actions notifier, providers Story 4.1 intacts
- `presence_toggle_grid.dart` — paramètres optionnels weekKey + overrideSlots, widget `_PresenceCell` pour distinction visuelle
- `planning_page.dart` — SegmentedButton avec 2 modes, widgets extraits en classes privées

### UX Specifications

- **WeekSelector** : "Semaine du {lundi} au {dimanche}" avec flèches ‹ ›, DatePicker au tap
- **Override visuel** : fond `#FFF8E1`, bordure accentuée (primaryColor 40% opacity)
- **Reset** : bouton "Réinitialiser à planning type" (visible si overrides, via pattern matching)
- **Limites navigation** : N-2 à N+8 semaines
- **Badge** : "Cette semaine" affiché quand weekKey == currentWeekKey()

### Project Structure Notes

- Pattern feature-first identique à Story 4.1
- Nouveau dossier : `data/utils/` pour les utilitaires
- Nouveau widget : `week_selector.dart` dans `presentation/widgets/`
- Convention `view/` conservée pour cohérence
- Riverpod 3 : `NotifierProvider` au lieu de `StateProvider` (supprimé en v3)

### References

- [Source: epics.md#Story 4.2] — AC, FR24, FR25
- [Source: architecture.md#Data Architecture] — weekKey pattern, drift
- [Source: ux-design-specification.md#Component Strategy] — PresenceToggleGrid override, WeekSelector
- [Source: 4-1-planning-presence-type.md] — Implémentation Story 4.1, patterns établis

## Dev Agent Record

### Agent Model Used

claude-opus-4-6

### Debug Log References

N/A — tous les tests passent (42/42 planning + 14 household = 0 régression).

### Completion Notes List

- Utilitaire `week_utils.dart` : conversion ISO 8601 date ↔ weekKey, offsets, ranges
- Datasource étendu : `watchWeeklySchedule()`, `toggleWeeklyPresence()`, `deleteWeeklyOverrides()`, `hasWeeklyOverrides()` — logique de création d'override inverse du type
- Repository étendu : `watchMergedPresences()` via `Rx.combineLatest2` pour fusion default + overrides
- Providers Riverpod : `SelectedWeekKeyNotifier`, `mergedPresencesStreamProvider`, `weeklyOverridesStreamProvider`, `weeklyOverridesExistProvider`
- Widget `WeekSelector` : navigation semaine avec flèches + DatePicker, badge "Cette semaine"
- `PresenceToggleGrid` adapté : mode weekly avec distinction visuelle (`_PresenceCell` avec fond `#FFF8E1`)
- `PlanningPage` refaite avec SegmentedButton : mode "Planning type" et mode "Semaine"
- Bouton "Réinitialiser à planning type" conditionnel avec pattern matching `AsyncData`
- Dépendance `rxdart` ajoutée au projet
- 27 nouveaux tests (14 week_utils + 7 datasource weekly + 6 repository weekly)
- Aucune régression : 15 tests Story 4.1 + 14 household = tous passent

### File List

- `lib/features/planning/data/utils/week_utils.dart` (créé)
- `lib/features/planning/data/datasources/presence_local_datasource.dart` (modifié — 4 méthodes weekly ajoutées)
- `lib/features/planning/domain/repositories/planning_repository.dart` (modifié — 5 méthodes weekly ajoutées)
- `lib/features/planning/data/repositories/planning_repository_impl.dart` (modifié — implémentations weekly + rxdart)
- `lib/features/planning/presentation/providers/planning_provider.dart` (modifié — providers weekly + SelectedWeekKeyNotifier)
- `lib/features/planning/presentation/widgets/week_selector.dart` (créé)
- `lib/features/planning/presentation/widgets/presence_toggle_grid.dart` (modifié — weekKey, overrideSlots, _PresenceCell)
- `lib/features/planning/view/planning_page.dart` (modifié — SegmentedButton, _WeekModeContent)
- `lib/features/planning/planning.dart` (modifié — exports week_utils + week_selector)
- `test/features/planning/data/utils/week_utils_test.dart` (créé — 14 tests)
- `test/features/planning/data/datasources/presence_local_datasource_test.dart` (modifié — 7 tests weekly ajoutés)
- `test/features/planning/data/repositories/planning_repository_test.dart` (modifié — 6 tests weekly ajoutés)
- `pubspec.yaml` (modifié — ajout rxdart)

### Code Review Fixes Applied

1. **Parsing weekKey sécurisé** : `weekKeyToDateRange()` lève `FormatException` si format invalide (validation longueur, parties, bornes 1-53) [`week_utils.dart`]
2. **Spinner infini corrigé** : `_WeekModeContent` affiche un message informatif au lieu d'un `CircularProgressIndicator` quand les présences fusionnées sont vides [`planning_page.dart`]
3. **Test semaine 53 ajouté** : `weekKeyOffset('2021-W01', -1)` → `'2020-W53'` + 3 tests validation format [`week_utils_test.dart`]
4. **Feedback visuel Material** : `GestureDetector` remplacé par `InkWell` avec ripple sur le label semaine [`week_selector.dart`]
