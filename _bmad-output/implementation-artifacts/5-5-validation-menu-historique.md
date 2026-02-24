# Story 5.5 : Validation du Menu & Historique

Status: done

---

## Story

En tant qu'utilisateur,
Je veux valider le menu de la semaine d'un tap et conserver l'historique,
Afin que l'algorithme évite les répétitions les semaines suivantes.

---

## Acceptance Criteria

1. **Given** un menu généré et ajusté sur la grille — **When** je tape sur **"Valider le menu"** — **Then** le menu est sauvegardé dans drift (`weekly_menus` + `menu_slots`) avec la date de début de la semaine (lundi ISO) comme clé de semaine (FR34).

2. **And** un **Snackbar vert** `Color(0xFF6BAE75)` s'affiche : `"Menu sauvegardé ✓"` — auto-dismiss après 3 secondes (pas de bouton action) (FR34).

3. **And** le menu validé est ajouté à l'historique (`menuHistoryProvider`) et devient **disponible pour l'anti-répétition** du `GenerationService` lors des prochaines générations (FR35, FR31).

4. **And** après validation, la `WeekGridComponent` affiche le menu en **mode lecture** (icônes verrou/refresh/supprimer masquées, bouton Générer remplacé par "Regénérer").

5. **And** les données sont persistées dans drift **sans perte** après fermeture et réouverture de l'app (NFR4).

6. **And** si le menu contient des **créneaux vides** (null) ou des **événements spéciaux**, ils sont sauvegardés tels quels (null slots = pas de `menu_slot` en DB pour ce créneau).

7. **And** un menu déjà validé pour la même semaine est **remplacé** (upsert) si l'utilisateur génère et revalide.

---

## Tasks / Subtasks

- [x] **Task 1 — Persistance dans drift** (AC: #1, #5, #6, #7)
  - [x] Créer `lib/features/generation/data/datasources/menu_local_datasource.dart`
  - [x] saveValidatedMenu(weekKey, slots) : delete+insert upsert, batch insert slots
  - [x] watchValidatedMenus() : stream trié par weekKey DESC
  - [x] getSlotsForMenu(menuId), getAllSlotsFromValidatedMenus()

- [x] **Task 2 — Repository & Interface** (AC: #1, #3)
  - [x] Créer `lib/features/generation/domain/repositories/menu_repository.dart`
  - [x] Créer `lib/features/generation/data/repositories/menu_repository_impl.dart`
  - [x] Conversion MealSlotResult → MenuSlotData (dayIndex+1=dayOfWeek, skip null et isSpecialEvent)

- [x] **Task 3 — Provider menuHistoryProvider** (AC: #3, #5)
  - [x] Créer `lib/features/generation/presentation/providers/menu_provider.dart`
  - [x] validatedMenusStreamProvider, menuForWeekProvider, MenuHistoryNotifier
  - [x] previousMenuSlotsProvider pour anti-répétition

- [x] **Task 4 — Bouton "Valider le menu" + Snackbar** (AC: #1, #2, #4)
  - [x] FilledButton "Valider le menu" en bas de HomeScreen
  - [x] Snackbar vert Color(0xFF6BAE75) "Menu sauvegardé ✓" 3s
  - [x] markValidated() → mode lecture (isPostGeneration=false dans grille)

- [x] **Task 5 — Tests** (AC: #1, #3, #5, #7)
  - [x] Créer `test/features/generation/data/repositories/menu_repository_test.dart`
  - [x] 5 tests : création, upsert, slots null, historique trié, événements spéciaux

---

## Dev Notes

### Modèles drift à Vérifier

Les tables `weekly_menus` et `menu_slots` sont définies dans le schéma drift de Story 1.4. Vérifier dans `lib/core/database/tables/` :

**Table `weekly_menus`** :
```dart
// Champs attendus
String id        // UUID v4, clé primaire
String weekStart // Date ISO 8601 du lundi de la semaine (ex: "2026-02-23")
DateTime validatedAt
```

**Table `menu_slots`** :
```dart
String id          // UUID v4, clé primaire
String weeklyMenuId // FK vers weekly_menus.id
String recipeId    // FK vers recipes.id (nullable si événement spécial)
int dayIndex       // 0=lundi, 1=mardi, ..., 6=dimanche
String mealType    // "lunch" ou "dinner"
```

> Si les tables existent mais ont des noms de colonnes différents, adapter les modèles `WeeklyMenu` et `MenuSlot` en conséquence — **ne pas changer le schéma drift** (les migrations sont en place).

### Calcul de `weekStart`

```dart
// ✅ Calculer le lundi de la semaine courante
DateTime getMondayOfWeek(DateTime date) {
  final daysFromMonday = date.weekday - 1; // weekday: 1=lundi, 7=dimanche
  return DateTime(date.year, date.month, date.day - daysFromMonday);
}
```

### Upsert Drift

drift ne supporte pas l'upsert natif sur toutes les versions — utiliser :
```dart
// ✅ Pattern recommandé
await (delete(weeklyMenus)
  ..where((t) => t.weekStart.equals(weekStart))).go();
await into(weeklyMenus).insert(menu);
await batch((batch) {
  batch.insertAll(menuSlots, slots);
});
```

### Mode Lecture Post-Validation

Après validation, la `WeekGridComponent` doit passer en mode "consultatif" :
- `MealSlotCard` : masquer les icônes verrou/refresh/supprimer
- Bouton "Générer" dans la top bar : reste visible (permet de regénérer)
- Bouton "Valider le menu" : masqué (déjà validé)

Implémenter via un paramètre `isReadOnly` dans `WeekGrid` ou un état `MenuDisplayMode.readOnly` dans le provider.

### Anti-Répétition (lien Story 5.1)

Après `save()`, `menuHistoryProvider` est invalidé et rechargé. Le `generateMenuProvider` doit **re-lire `menuHistoryProvider`** à chaque appel de `generate()` pour que l'anti-répétition soit à jour.

```dart
// ✅ Dans GenerateMenuNotifier.generate()
final previousMenus = ref.read(menuHistoryProvider).value ?? [];
final input = GenerationInput(
  ...,
  previousMenus: previousMenus,  // utilisé pour la couche anti-répétition
);
```

### References

- FR34 (validation menu) : [Source: `_bmad-output/planning-artifacts/epics.md` — Story 5.5]
- FR35 (historique) : [Source: `_bmad-output/planning-artifacts/epics.md` — Story 5.5]
- FR31 (anti-répétition depuis historique) : [Source: `_bmad-output/planning-artifacts/epics.md` — Story 5.1]
- NFR4 (persistance sans perte) : [Source: `_bmad-output/planning-artifacts/epics.md` — NonFunctional Requirements]
- Tables weekly_menus / menu_slots : [Source: `_bmad-output/planning-artifacts/architecture.md` — Complete Project Directory Structure / core/database/tables/]
- Snackbar vert : [Source: `_bmad-output/planning-artifacts/architecture.md` — Process Patterns / Gestion d'erreurs]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6 (create-story workflow)

### Debug Log References

### Completion Notes List

- `weekKey` utilisé comme clé de semaine (format "YYYY-Www") au lieu de `weekStart` DateTime — conforme au schéma drift réel
- Upsert implémenté via delete+insert (drift standard)
- Les événements spéciaux (isSpecialEvent=true) ne créent pas de menu_slot en DB
- `previousMenuSlotsProvider` expose `List<MenuSlot>` pour le GenerateMenuNotifier

### File List

- `lib/features/generation/data/datasources/menu_local_datasource.dart` (créé)
- `lib/features/generation/domain/repositories/menu_repository.dart` (créé)
- `lib/features/generation/data/repositories/menu_repository_impl.dart` (créé)
- `lib/features/generation/presentation/providers/menu_provider.dart` (créé)
- `lib/features/generation/presentation/screens/home_screen.dart` (mise à jour)
- `test/features/generation/data/repositories/menu_repository_test.dart` (créé)
