# Story 5.2 : Grille Semaine & Affichage du Menu Généré

Status: done

---

## Story

En tant qu'utilisateur,
Je veux voir le menu généré sous forme de grille semaine sur l'écran d'accueil,
Afin de visualiser d'un coup d'œil toute la semaine planifiée.

---

## Acceptance Criteria

1. **Given** l'écran Accueil est ouvert **sans menu généré** pour la semaine courante — **When** l'écran se charge — **Then** la `WeekGridComponent` affiche 7 colonnes (lundi → dimanche) × 2 lignes (midi/soir) avec des créneaux vides.

2. **And** le bouton **Générer** est visible dans la top bar de l'écran Accueil.

3. **And** l'état vide affiche le message `"Tape Générer pour planifier ta semaine"` sous la grille.

4. **Given** l'utilisateur tape sur **Générer** — **When** la génération est en cours — **Then** un `CircularProgressIndicator` centré est affiché sur l'écran (animation Progress indicator) pendant le calcul (FR26).

5. **Given** le menu vient d'être généré (Story 5.1 complétée) — **When** la génération est terminée — **Then** chaque `MealSlotCard` remplie affiche : le nom de la recette + les badges contextuels applicables (Favori ⭐, Végé 🌿, Saison 🍂).

6. **And** les icônes **verrou 🔒 / refresh 🔄 / supprimer 🗑** apparaissent sur chaque case remplie en mode post-génération.

7. **And** les créneaux non remplis (génération partielle, null retourné par Story 5.1) affichent un état vide avec une icône `+` permettant un ajout manuel futur (Story 5.4).

8. **And** l'écran Accueil est chargé en **moins de 1 seconde** (NFR2) — les données viennent de drift local, aucun appel réseau bloquant.

---

## Tasks / Subtasks

- [x] **Task 1 — Écran Accueil (HomeScreen)** (AC: #1, #2, #3, #8)
  - [x] Créer `lib/features/generation/presentation/screens/home_screen.dart`
  - [x] WeekGrid intégré comme widget central
  - [x] Bouton "Générer" / "Regénérer" dans AppBar
  - [x] État vide : "Tape Générer pour planifier ta semaine"
  - [x] Connexion bouton → generate(filters)

- [x] **Task 2 — WeekGridComponent** (AC: #1, #5, #6, #7)
  - [x] Créer `lib/features/generation/presentation/widgets/week_grid.dart`
  - [x] SingleChildScrollView horizontal + 7 colonnes × 2 lignes
  - [x] Headers Lun/Mar/Mer/Jeu/Ven/Sam/Dim et Midi/Soir
  - [x] Props : slots, recipesMap, isPostGeneration, isReadOnly, lockedSlotIndices, highlightEmptySlots, callbacks

- [x] **Task 3 — MealSlotCard** (AC: #5, #6, #7)
  - [x] Créer `lib/features/generation/presentation/widgets/meal_slot_card.dart`
  - [x] État vide : fond gris, icône +, bordure orange si isHighlighted
  - [x] État rempli : nom 2 lignes ellipsis, badges ⭐🌿 + saisons
  - [x] Mode post-génération : icônes verrou/refresh/delete en overlay
  - [x] isLocked : bordure orange + icône lock plein

- [x] **Task 4 — Loading state pendant génération** (AC: #4)
  - [x] AsyncLoading → CircularProgressIndicator centré
  - [x] AsyncError → texte d'erreur + bouton retry
  - [x] AsyncData → grille ou état vide

- [x] **Task 5 — Tests widget** (AC: #1, #3, #5)
  - [x] Créer `test/features/generation/presentation/widgets/week_grid_test.dart`
  - [x] Tests WeekGrid (14 cards, nom recette, headers)
  - [x] Tests MealSlotCard (badges, icônes, états)

---

## Dev Notes

### Composant UX Défini — WeekGridComponent

Défini dans la spec UX comme composant custom central de l'Epic 5 :
> `WeekGridComponent` : grille 7 jours × 2 repas (midi/soir)
> `MealSlotCard` : case individuelle avec icônes verrou/refresh/supprimer en mode post-génération

**Important :** la grille 7×2 = 14 cellules. L'ordre des `MenuSlotResult?` retournés par Story 5.1 est :
`[lundi-midi, lundi-soir, mardi-midi, mardi-soir, ..., dimanche-midi, dimanche-soir]`

### Palette de couleurs (Design System "Chaleur & Appétit")

```dart
// ✅ Couleurs à utiliser (défini dans lib/core/theme/app_colors.dart)
Primary   : Color(0xFFE8794A)   // bouton Générer, accents
Secondary : Color(0xFFF5C26B)   // badges saison
Background: Color(0xFFFDF6EF)  // fond écran
Success   : Color(0xFF6BAE75)   // confirmations
```

### Badges contextuels — implémentation suggérée

```dart
// ✅ Chips légers Material Design 3
if (recipe.isFavorite)
  Chip(label: Text('⭐'), backgroundColor: Color(0xFFFFE0CC), padding: EdgeInsets.zero),
if (recipe.isVegetarian)
  Chip(label: Text('🌿'), backgroundColor: Color(0xFFE8F5E9), padding: EdgeInsets.zero),
```

### Connexion avec Story 5.1

Cette story consomme directement `generateMenuProvider` créé en Story 5.1. Avant d'implémenter, vérifier que :
- `generateMenuProvider` expose `AsyncNotifierProvider<GenerateMenuNotifier, List<MenuSlotResult?>>`
- Le notifier a `generate(GenerationFilters? filters)` et `reset()`
- `MenuSlotResult` a : `recipeId`, `dayIndex` (0–6), `mealType` (MealType.lunch/dinner)

Le `HomeScreen` a besoin de **résoudre les recettes** à partir des `recipeId` dans les slots :
```dart
// ✅ Lookup rapide — construire une Map au niveau du provider ou du screen
final recipesMap = {for (final r in recipes) r.id: r};
final recipe = recipesMap[slot.recipeId]; // peut être null si recette supprimée
```

### Accessibilité & Touch Targets

- Chaque `MealSlotCard` : `minHeight: 64px`, `width` adaptative selon la largeur écran / 7
- Touch targets icônes (verrou/refresh/supprimer) : `IconButton` avec `constraints: BoxConstraints(minWidth: 32, minHeight: 32)` — les 3 icônes tiennent dans la card
- Sur petits écrans (< 360px), envisager un scroll horizontal sur la grille

### Localisation `home_screen.dart`

Selon la structure définie en architecture, `HomeScreen` est dans :
```
lib/features/generation/presentation/screens/home_screen.dart
```
Ce fichier peut déjà exister comme stub depuis l'Epic 1 (navigation shell). **Lire le fichier existant avant de modifier.**

### Performance (NFR2 : < 1s)

Les données de la grille viennent exclusivement de `drift` local — pas d'appel Supabase bloquant. Le `generateMenuProvider` doit lire depuis les providers locaux existants.

### References

- WeekGridComponent, MealSlotCard : [Source: `_bmad-output/planning-artifacts/epics.md` — Additional Requirements / UX Composants Custom]
- FR26 (animation génération), FR28-FR31 (badges contextuels) : [Source: `_bmad-output/planning-artifacts/epics.md` — Story 5.2]
- NFR2 (< 1s navigation) : [Source: `_bmad-output/planning-artifacts/epics.md` — NonFunctional Requirements]
- NFR8 (zone pouce, 48px) : [Source: `_bmad-output/planning-artifacts/epics.md` — NonFunctional Requirements]
- home_screen.dart emplacement : [Source: `_bmad-output/planning-artifacts/architecture.md` — Complete Project Directory Structure]
- Palette couleurs : [Source: `_bmad-output/planning-artifacts/architecture.md` — Starter Template Evaluation]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6 (create-story workflow)

### Debug Log References

### Completion Notes List

- HomeScreen remplace le stub `home_page.dart` — app_router.dart mis à jour
- WeekGrid utilise SingleChildScrollView horizontal (layout natif sans package externe)
- MealSlotCard supporte isHighlighted (bordure orange pour Story 5.6) dès cette story
- slotIndex = dayIndex * 2 + mealOffset (0=lunch, 1=dinner) utilisé pour le mapping

### File List

- `lib/features/generation/presentation/screens/home_screen.dart` (créé)
- `lib/features/generation/presentation/widgets/week_grid.dart` (créé)
- `lib/features/generation/presentation/widgets/meal_slot_card.dart` (créé)
- `lib/core/router/app_router.dart` (modifié — HomeScreen remplace HomePage)
- `test/features/generation/presentation/widgets/week_grid_test.dart` (créé)
