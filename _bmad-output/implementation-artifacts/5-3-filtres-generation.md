# Story 5.3 : Filtres de Génération

Status: done

---

## Story

En tant qu'utilisateur,
Je veux appliquer des filtres avant de lancer la génération,
Afin d'adapter le menu à des contraintes ponctuelles (végétarien, saison, temps de préparation).

---

## Acceptance Criteria

1. **Given** je suis sur l'écran Accueil avant de lancer la génération — **When** je tape sur l'icône filtres (dans la top bar ou à côté du bouton Générer) — **Then** une `GenerationFiltersSheet` (bottom sheet Material 3) s'affiche avec 3 contrôles (FR32) :
   - **Temps de préparation maximum** : `Slider` de 0 à 120 minutes (pas de 5 min), valeur par défaut = pas de limite
   - **Filtre végétarien** : `Switch` / `Toggle` (off par défaut)
   - **Filtre saison** : chips exclusifs pour Printemps / Été / Automne / Hiver / Toute saison (aucune sélection = pas de filtre)

2. **And** les filtres sélectionnés sont **persistés en mémoire** (provider Riverpod) et **appliqués à la prochaine génération** via `GenerationFilters` passé à `generateMenuProvider.notifier.generate(filters)`.

3. **And** quand des filtres actifs sont en place, une **indication visuelle** est affichée sur l'icône filtres (badge point orange `Color(0xFFE8794A)` ou label "Filtres actifs").

4. **And** un bouton **Réinitialiser** dans la `GenerationFiltersSheet` efface tous les filtres actifs et remet les valeurs par défaut.

5. **And** fermer la sheet sans valider **conserve les filtres** tels qu'ils étaient avant ouverture (pas de validation destructive).

6. **And** après modification des filtres, si l'utilisateur tape Générer, la génération utilise les nouveaux filtres appliqués — la `GenerationFiltersSheet` se ferme automatiquement au tap sur Générer.

---

## Tasks / Subtasks

- [x] **Task 1 — GenerationFiltersSheet** (AC: #1, #4, #5)
  - [x] Créer `lib/features/generation/presentation/widgets/generation_filters_sheet.dart`
  - [x] StatefulWidget avec DragHandle + Slider + SwitchListTile + FilterChips saisons
  - [x] Boutons Réinitialiser (TextButton) et Appliquer (FilledButton)
  - [x] Slider : "Pas de limite" si 0, "${val} min" sinon
  - [x] Callback `onApply` pour fermer et relancer la génération

- [x] **Task 2 — filtersProvider Riverpod** (AC: #2, #3, #4, #6)
  - [x] `filtersProvider` : `NotifierProvider<FiltersNotifier, GenerationFilters?>` dans generation_provider.dart
  - [x] FiltersNotifier.update() et reset()
  - [x] `hasActiveFiltersProvider` : Provider<bool>

- [x] **Task 3 — Intégration dans HomeScreen** (AC: #3, #6)
  - [x] Icône filtres dans AppBar avec badge point orange si hasActiveFiltersProvider
  - [x] showModalBottomSheet → GenerationFiltersSheet avec onApply
  - [x] Filtres passés à generate()

- [x] **Task 4 — Tests** (AC: #1, #2, #4)
  - [x] Créer `test/features/generation/presentation/widgets/generation_filters_sheet_test.dart`
  - [x] Tests sheet (valeurs défaut, réinitialiser, végétarien)
  - [x] Tests hasActiveFiltersProvider

---

## Dev Notes

### Dépendance sur Story 5.1

Le modèle `GenerationFilters` est défini en Story 5.1 (`lib/features/generation/domain/models/generation_filters.dart`) avec :
```dart
class GenerationFilters {
  final int? maxPrepTimeMinutes;  // null = pas de limite
  final bool vegetarianOnly;       // false par défaut
  final Season? season;            // null = pas de filtre saison

  const GenerationFilters({
    this.maxPrepTimeMinutes,
    this.vegetarianOnly = false,
    this.season,
  });

  GenerationFilters copyWith({...}); // obligatoire
}
```

**Vérifier que Story 5.1 est `done` avant de démarrer cette story.** Si non, implémenter `GenerationFilters` ici et le déplacer dans `domain/models/` lors du merge.

### Dépendance sur Story 5.2

La `GenerationFiltersSheet` est mentionnée dans Story 5.6 ("choisir Élargir les filtres rouvre la GenerationFiltersSheet") — l'exposer correctement pour permettre cet accès depuis une autre partie de l'app.

### Enum Season

```dart
// ✅ Défini dans les modèles recettes (Epic 2) — vérifier le chemin exact
enum Season { spring, summer, autumn, winter, allSeasons }
```
Les chips de la sheet doivent afficher les labels en français : Printemps / Été / Automne / Hiver.

### Comportement du Slider

- Valeur 0 = "Pas de limite" → `maxPrepTimeMinutes = null` dans le filtre
- Valeur > 0 = limite en minutes → `maxPrepTimeMinutes = value.toInt()`
- Divisons : 0, 5, 10, ..., 120 (25 divisions)

```dart
Slider(
  value: _prepTime,
  min: 0,
  max: 120,
  divisions: 24,
  label: _prepTime == 0 ? 'Pas de limite' : '${_prepTime.toInt()} min',
  onChanged: (v) => setState(() => _prepTime = v),
)
```

### Design Material 3

- La sheet doit avoir un `DragHandle` en haut (Material 3 convention)
- `showModalBottomSheet` avec `useSafeArea: true` pour éviter les encoches
- Titre "Filtres de génération" en `titleLarge` (Nunito, 22sp)
- Espacement entre sections : 16px (token M3)

### References

- FR32 (filtres génération) : [Source: `_bmad-output/planning-artifacts/epics.md` — Story 5.3]
- GenerationFiltersSheet composant : [Source: `_bmad-output/planning-artifacts/architecture.md` — Complete Project Directory Structure]
- GenerationFilters modèle : [Source: `_bmad-output/planning-artifacts/epics.md` — Story 5.1 (défini dans AC)]
- Design System tokens : [Source: `_bmad-output/planning-artifacts/architecture.md` — Implementation Patterns]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6 (create-story workflow)

### Debug Log References

### Completion Notes List

- filtersProvider implémenté avec `NotifierProvider` (Riverpod v2) plutôt que `StateNotifierProvider` (déprécié)
- GenerationFiltersSheet accepte `initialFilters` et `onApply` pour réutilisation depuis Story 5.6
- hasActiveFiltersProvider utilise `GenerationFilters.hasActiveFilters` getter

### File List

- `lib/features/generation/presentation/widgets/generation_filters_sheet.dart` (créé)
- `lib/features/generation/presentation/providers/generation_provider.dart` (mise à jour)
- `lib/features/generation/presentation/screens/home_screen.dart` (mise à jour)
- `test/features/generation/presentation/widgets/generation_filters_sheet_test.dart` (créé)
