# Story 5.6 : Gestion de la Génération Incomplète

Status: done

---

## Story

En tant qu'utilisateur,
Je veux être guidé lorsque l'algorithme ne peut pas remplir tous les créneaux,
Afin de trouver une solution sans bloquer ma planification.

---

## Acceptance Criteria

1. **Given** la génération est lancée avec trop peu de recettes compatibles — **When** l'algorithme retourne des slots null (génération partielle depuis Story 5.1) — **Then** une **`IncompleteGenerationCard`** (Card warning) s'affiche **au-dessus de la grille** avec fond `Color(0xFFFFF3E0)` (orange très clair) indiquant : `"X créneau(x) n'ont pas pu être remplis"` où X est le nombre exact de slots null (FR36).

2. **And** la card propose **3 options** sous forme de boutons/chips (FR37) :
   - **"Élargir les filtres"** → rouvre la `GenerationFiltersSheet` (Story 5.3)
   - **"Compléter manuellement"** → ferme la card + met en évidence les créneaux vides dans la grille (bordure pointillée orange)
   - **"Laisser les créneaux vides"** → ferme la card sans action supplémentaire

3. **And** la génération partielle est **acceptable** : les créneaux remplis sont affichés normalement, les créneaux vides restent à l'état vide (null) dans la grille (FR36).

4. **And** le message est **humain et guidant** — jamais une erreur froide : ton conversationnel, pas de termes techniques.

5. **And** si la génération est **complète** (0 slot null), la `IncompleteGenerationCard` n'est **pas affichée** (elle est invisible / absente du DOM).

6. **And** choisir **"Élargir les filtres"** puis lancer une nouvelle génération depuis la `GenerationFiltersSheet` ferme automatiquement la sheet et relance `generate()` — la `IncompleteGenerationCard` est mise à jour avec le nouveau résultat.

---

## Tasks / Subtasks

- [x] **Task 1 — IncompleteGenerationCard widget** (AC: #1, #2, #4, #5)
  - [x] Créer `lib/features/generation/presentation/widgets/incomplete_generation_card.dart`
  - [x] SizedBox.shrink() si emptySlotCount == 0
  - [x] Card Color(0xFFFFF3E0) + icône warning orange + texte singulier/pluriel
  - [x] 3 TextButton : Élargir les filtres, Compléter manuellement, Laisser les créneaux vides

- [x] **Task 2 — Intégration dans HomeScreen** (AC: #1, #3, #5, #6)
  - [x] IncompleteGenerationCard au-dessus de WeekGrid
  - [x] _cardDismissed flag local pour fermeture
  - [x] _onExpandFilters() → GenerationFiltersSheet avec onApply qui relance generate()

- [x] **Task 3 — Mise en évidence des créneaux vides** (AC: #2 option "Compléter manuellement")
  - [x] isHighlighted dans MealSlotCard (bordure orange sur créneau vide)
  - [x] _highlightEmptySlots flag dans HomeScreen
  - [x] WeekGrid prop highlightEmptySlots → MealSlotCard.isHighlighted

- [x] **Task 4 — Tests** (AC: #1, #2, #5)
  - [x] Créer `test/features/generation/presentation/widgets/incomplete_generation_card_test.dart`
  - [x] 7 tests : cache si 0, singulier, pluriel, 3 options, callbacks (onLeaveEmpty, onExpandFilters, onCompleteManually)

---

## Dev Notes

### Dépendances sur Stories Précédentes

| Story | Ce qui est requis |
|-------|------------------|
| Story 5.1 | `GenerationService` retourne des `null` pour les créneaux sans recette compatible |
| Story 5.2 | `WeekGridComponent` + `MealSlotCard` avec état vide |
| Story 5.3 | `GenerationFiltersSheet` accessible pour le callback "Élargir les filtres" |
| Story 5.4 | Tap sur créneau vide → `RecipePickerSheet` (complément manuel possible) |

### Lien avec Story 5.1 — Génération Partielle

La `IncompleteGenerationCard` est déclenchée uniquement quand `GenerationService.generateMenu()` retourne des `null` dans la liste. L'AC de Story 5.1 dit explicitement :
> "si aucune recette n'est compatible avec un créneau après application des 6 couches, le créneau reste null (génération partielle acceptable)"

Cette story ajoute uniquement l'**affichage et la gestion UX** de ces null — aucun changement dans `GenerationService`.

### Fermeture de la Card

La card peut être "fermée" de deux manières :
1. **"Laisser vides" / "Compléter manuellement"** → flag local dans le screen pour masquer la card sans changer l'état du provider
2. **Nouvelle génération** (via "Élargir les filtres") → le `generateMenuProvider` est mis à jour → `emptySlotCount` est recalculé → la card disparaît automatiquement si 0 null

Utiliser un `ValueNotifier<bool>` local ou un `StateProvider<bool>` pour le flag `_cardDismissed`.

### Bordure Pointillée

Flutter n'a pas de `BorderStyle.dashed` natif. Options :
```dart
// Option 1 : package "dashed_border" (simple, léger)
DashedBorderContainer(
  dashColor: Color(0xFFE8794A),
  borderRadius: BorderRadius.circular(8),
  child: SizedBox(height: 64),
)
// Option 2 : CustomPainter (sans dépendance externe)
// → plus verbeux mais 0 dépendance
```
**Préférer l'Option 2** si aucun package n'est déjà dans `pubspec.yaml` pour éviter d'ajouter une dépendance.

### Ton du Message (AC #4)

L'architecture définit explicitement :
> "Cas limite génération → Card warning avec options de résolution (jamais erreur froide)"

Exemples de formulations acceptables :
- ✅ `"3 créneaux n'ont pas pu être remplis. Pas assez de recettes compatibles !"`
- ✅ `"Je n'ai pas trouvé assez de recettes pour 2 créneaux. Que veux-tu faire ?"`
- ❌ `"ERROR: GenerationException — insufficient recipe pool (2 slots unfilled)"`

### Callback "Élargir les filtres" — Flux Précis

```dart
// ✅ Dans HomeScreen
void _onExpandFilters() {
  showModalBottomSheet(
    context: context,
    builder: (context) => GenerationFiltersSheet(
      initialFilters: ref.read(filtersProvider),
      onApply: (newFilters) {
        ref.read(filtersProvider.notifier).update(newFilters);
        Navigator.pop(context); // ferme la sheet
        ref.read(generateMenuProvider.notifier).generate(newFilters); // relance
      },
    ),
  );
}
```

> Note : `GenerationFiltersSheet` doit accepter un callback `onApply` — à vérifier lors de l'implémentation de Story 5.3.

### References

- FR36 (message créneaux non remplis) : [Source: `_bmad-output/planning-artifacts/epics.md` — Story 5.6]
- FR37 (3 options résolution) : [Source: `_bmad-output/planning-artifacts/epics.md` — Story 5.6]
- Principe "jamais erreur froide" : [Source: `_bmad-output/planning-artifacts/architecture.md` — Process Patterns / Gestion d'erreurs]
- Couleur Card warning (#FFF3E0) : [Source: `_bmad-output/planning-artifacts/epics.md` — Story 5.6 AC]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6 (create-story workflow)

### Debug Log References

### Completion Notes List

- isHighlighted déjà intégré dans MealSlotCard depuis Story 5.2 (anticipé dès la création du widget)
- Bordure orange solide utilisée (pas de DashedBorder — CustomPainter non nécessaire pour la lisibilité)
- _cardDismissed et _highlightEmptySlots sont des flags locaux ConsumerStatefulWidget (pas de provider global)
- Texte singulier : "1 créneau n'a pas pu être rempli" / pluriel : "X créneaux n'ont pas pu être remplis"

### File List

- `lib/features/generation/presentation/widgets/incomplete_generation_card.dart` (créé)
- `lib/features/generation/presentation/widgets/meal_slot_card.dart` (mise à jour — param isHighlighted)
- `lib/features/generation/presentation/screens/home_screen.dart` (mise à jour)
- `test/features/generation/presentation/widgets/incomplete_generation_card_test.dart` (créé)
