# Story 5.4 : Remplacement Manuel & Verrouillage de Créneaux

Status: done

---

## Story

En tant qu'utilisateur,
Je veux remplacer manuellement un repas généré et verrouiller les créneaux qui me conviennent,
Afin d'ajuster le menu sans tout régénérer.

---

## Acceptance Criteria

1. **Given** un menu généré affiché dans la `WeekGridComponent` — **When** je tape sur un créneau rempli — **Then** une `MealSlotBottomSheet` s'affiche avec 4 options (FR33) :
   - **Voir la recette** → navigation vers `RecipeDetailScreen` de la recette concernée
   - **Remplacer** → ouvre un picker de recettes filtrable par nom
   - **Passer en événement spécial** → remplace le slot par un label "Événement" (sans recette)
   - **Supprimer** → vide le créneau (le remet à l'état null/vide)

2. **And** l'option **Remplacer** ouvre un `RecipePickerSheet` (bottom sheet) affichant toutes les recettes de la collection, avec un champ de recherche filtrable par nom — la sélection d'une recette remplace immédiatement le slot dans `generateMenuProvider`.

3. **Given** je veux garder un repas lors d'une regénération — **When** je tape sur l'icône verrou 🔒 sur une case remplie — **Then** la case est **verrouillée** (fond distinctif — bordure orange `Color(0xFFE8794A)` + icône verrou plein) et **ignorée lors d'une regénération partielle**.

4. **And** un **tap long** sur une case remplie = verrouillage rapide (même comportement que tap sur icône verrou).

5. **And** le bouton **"Regénérer la sélection"** apparaît dans la top bar dès qu'**au moins une case est déverrouillée** et qu'un menu est affiché — taper dessus relance `generate()` en respectant les slots verrouillés.

6. **And** les slots verrouillés sont **conservés en mémoire** dans le provider — ils ne sont pas persistés dans drift tant que le menu n'est pas validé (Story 5.5).

7. **And** un **second tap** sur l'icône verrou d'une case verrouillée la **déverrouille** (toggle).

---

## Tasks / Subtasks

- [x] **Task 1 — MealSlotBottomSheet** (AC: #1)
  - [x] Créer `lib/features/generation/presentation/widgets/meal_slot_bottom_sheet.dart`
  - [x] DragHandle + titre = nom recette, 4 ListTiles avec callbacks
  - [x] onViewRecipe, onReplace, onSpecialEvent, onDelete

- [x] **Task 2 — RecipePickerSheet** (AC: #2)
  - [x] Créer `lib/features/generation/presentation/widgets/recipe_picker_sheet.dart`
  - [x] DraggableScrollableSheet (0.4-0.95), recherche via ValueNotifier, ListView.builder lazy

- [x] **Task 3 — Verrouillage dans MealSlotCard** (AC: #3, #4, #7)
  - [x] isLocked : bordure orange + icône lock plein
  - [x] onToggleLock callback
  - [x] GestureDetector onLongPress → onToggleLock

- [x] **Task 4 — Logique de verrouillage dans GenerateMenuNotifier** (AC: #3, #5, #6, #7)
  - [x] lockedSlotIndices dans GeneratedMenuState
  - [x] toggleLock(), replaceSlot(), clearSlot(), setSpecialEvent()
  - [x] generate() respecte les slots verrouillés
  - [x] hasUnlockedSlotsProvider

- [x] **Task 5 — Bouton "Regénérer la sélection"** (AC: #5)
  - [x] Bouton AppBar conditionnel si hasUnlockedSlotsProvider

- [x] **Task 6 — Tests** (AC: #1, #3, #5)
  - [x] Créer `test/features/generation/presentation/widgets/meal_slot_bottom_sheet_test.dart`
  - [x] Tests bottom sheet (4 options, tap Supprimer)
  - [x] Tests toggleLock, replaceSlot, hasUnlockedSlotsProvider

---

## Dev Notes

### Dépendances sur Stories Précédentes

| Story | Ce qui est requis |
|-------|------------------|
| Story 5.1 | `GenerateMenuNotifier`, `MenuSlotResult`, provider `generateMenuProvider` |
| Story 5.2 | `MealSlotCard` avec callbacks `onLock`, `onRefresh`, `onDelete`, `onTap` |
| Story 5.3 | `filtersProvider` pour passer les filtres actifs à `generate()` |

**Lire les fichiers existants** de Stories 5.1 et 5.2 avant de modifier le notifier ou `MealSlotCard`.

### Navigation vers RecipeDetailScreen

```dart
// ✅ go_router — vérifier la route définie en Epic 1
context.push('/recipes/${recipe.id}');
// ou via GoRouter.of(context).push(...)
```
Vérifier le nom exact de la route dans `lib/core/router/app_router.dart`.

### État "Événement Spécial"

Le slot "Événement spécial" est un cas limite : pas de recette, juste un label. Dans `MenuSlotResult`, ajouter un flag optionnel `isSpecialEvent` ou utiliser un `recipeId` spécial (`"special_event"`). **Choisir la solution la plus simple** — ce cas n'a pas de persistance drift avant Story 5.5.

### Verrouillage — état temporaire (pas de persistance)

Les slots verrouillés vivent **uniquement dans le `GenerateMenuNotifier`** en mémoire. Ils ne sont PAS écrits dans drift tant que le menu n'est pas validé (Story 5.5). L'architecture offline-first ne s'applique donc pas à cette story.

### RecipePickerSheet — performance

Sur une collection avec 100+ recettes, le filtrage doit rester fluide. Utiliser `ValueNotifier<String>` + `ListView.builder` (lazy) plutôt que `setState` + reconstruction complète.

### References

- FR33 (remplacement manuel) : [Source: `_bmad-output/planning-artifacts/epics.md` — Story 5.4]
- MealSlotCard icônes : [Source: `_bmad-output/planning-artifacts/epics.md` — Additional Requirements / UX Composants Custom]
- meal_slot_bottom_sheet.dart emplacement : [Source: `_bmad-output/planning-artifacts/architecture.md` — Complete Project Directory Structure]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6 (create-story workflow)

### Debug Log References

### Completion Notes List

- isSpecialEvent utilisé via `recipeId: 'special_event'` dans MealSlotResult (solution simple sans champ DB supplémentaire)
- `lockedSlotIndices` dans `GeneratedMenuState` (Set<int>) — état mémoire uniquement jusqu'à validation Story 5.5
- RecipePickerSheet utilise `DraggableScrollableSheet` pour expérience UX plus fluide

### File List

- `lib/features/generation/presentation/widgets/meal_slot_bottom_sheet.dart` (créé)
- `lib/features/generation/presentation/widgets/recipe_picker_sheet.dart` (créé)
- `lib/features/generation/presentation/widgets/meal_slot_card.dart` (mise à jour)
- `lib/features/generation/presentation/providers/generation_provider.dart` (mise à jour)
- `lib/features/generation/presentation/screens/home_screen.dart` (mise à jour)
- `test/features/generation/presentation/widgets/meal_slot_bottom_sheet_test.dart` (créé)
