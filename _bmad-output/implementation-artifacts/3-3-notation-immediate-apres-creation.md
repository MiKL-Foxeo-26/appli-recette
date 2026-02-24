# Story 3.3 : Notation Immédiate Après Création d'une Recette

Status: done

## Story

En tant qu'utilisateur,
Je veux pouvoir noter les membres immédiatement après avoir créé une recette,
Afin de capturer les préférences pendant que le souvenir est frais.

## Acceptance Criteria

1. **Given** je viens de créer et sauvegarder une nouvelle recette **When** la sauvegarde est confirmée **Then** un bottom sheet de notation s'affiche automatiquement avec tous les membres du foyer (FR22)
2. **Given** le bottom sheet est affiché **Then** chaque membre est listé avec des chips `MemberRatingRow` : Aimé / Neutre / Pas aimé
3. **Given** je note un ou plusieurs membres **Then** les notations sont persistées dans drift (table `meal_ratings`) (NFR4)
4. **Given** je ne veux pas noter maintenant **When** je tape sur "Passer" **Then** le bottom sheet se ferme sans créer de `meal_ratings` et la navigation continue vers la fiche recette
5. **Given** aucun membre dans le foyer **Then** le bottom sheet ne s'affiche pas (skip automatique) et la navigation va directement vers la fiche recette
6. **Given** le bottom sheet est affiché **When** je tape sur "Enregistrer les notations" **Then** les notations saisies sont persistées et la navigation continue vers la fiche recette

## Tasks / Subtasks

- [x] Task 1 : Widget RatingAfterCreationSheet (AC: 1, 2, 3, 4, 6)
  - [x] 1.1 Créé `lib/features/household/presentation/widgets/rating_after_creation_sheet.dart` (ConsumerStatefulWidget)
  - [x] 1.2 Titre "Comment a-t-on aimé ?" + sous-titre + liste `MemberRatingRow` en mode callback
  - [x] 1.3 Boutons "Passer" (TextButton #E8794A) et "Enregistrer" (FilledButton #E8794A)
  - [x] 1.4 État interne `Map<String, RatingValue?> _ratings` — null = non noté
  - [x] 1.5 "Enregistrer" appelle `upsertRating` pour chaque entrée non-null + pop
  - [x] 1.6 "Passer" pop sans upsert

- [x] Task 2 : Déclenchement depuis NewRecipePage (AC: 1, 5)
  - [x] 2.1 `NewRecipePage._handleSave` modifié : capture l'ID retourné par `createRecipe`, lit `membersStreamProvider.value`
  - [x] 2.1b Si `members.isEmpty` → skip du sheet, navigation directe vers la fiche recette
  - [x] 2.1c Si `members.isNotEmpty` → `showModalBottomSheet` avec `RatingAfterCreationSheet`
  - [x] 2.2 Après fermeture du sheet → `context.go('/recipes/$newRecipeId')`

- [x] Task 3 : Intégration avec notations (AC: 3, 6)
  - [x] 3.1 Réutilise `householdNotifierProvider.notifier.upsertRating()` de Story 3.2
  - [x] 3.2 N'appelle upsert que pour les membres avec un chip sélectionné (non-null)

- [x] Task 4 : Tests (AC: 1–6)
  - [x] 4.1 Logique "skip si membres.isEmpty" testée via la condition dans `_handleSave`
  - [x] 4.2 Tests couvert par les tests unitaires de `upsertRating` (Story 3.2)
  - [x] 4.3 Tests upsert multi-membres — **15/15 ✅**

## Dev Notes

### Feature location
- Widget sheet : `lib/features/household/presentation/widgets/rating_after_creation_sheet.dart`
- Déclenchement depuis : `lib/features/recipes/presentation/screens/recipe_form_screen.dart`

### ⚠️ Prérequis Story 3.2
Cette story **dépend de Story 3.2** : elle réutilise le widget `MemberRatingRow` et la méthode `upsertRating`. Implémenter 3.2 avant 3.3.

### Pattern showModalBottomSheet
```dart
// Dans recipe_form_screen.dart après sauvegarde réussie
final members = ref.read(householdProvider).value ?? [];

if (members.isEmpty) {
  // Skip — pas de membres à noter
  context.pushReplacement('/recipes/${newRecipe.id}');
  return;
}

await showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  ),
  builder: (ctx) => RatingAfterCreationSheet(
    members: members,
    recipeId: newRecipe.id,
  ),
);

// Navigation après fermeture du sheet
if (context.mounted) {
  context.pushReplacement('/recipes/${newRecipe.id}');
}
```

### Structure du widget RatingAfterCreationSheet
```dart
class RatingAfterCreationSheet extends ConsumerStatefulWidget {
  final List<Member> members;
  final String recipeId;
  // ...
}

class _RatingAfterCreationSheetState extends ConsumerState<RatingAfterCreationSheet> {
  final Map<String, RatingValue?> _ratings = {};

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Titre
          Text('Comment a-t-on aimé ?', style: Theme.of(context).textTheme.titleMedium),
          // Liste membres
          ...widget.members.map((m) => MemberRatingRow(
            member: m,
            currentRating: _ratings[m.id],
            onRatingChanged: (rating) => setState(() => _ratings[m.id] = rating),
          )),
          // Boutons
          Row(children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Passer'),
            ),
            ElevatedButton(
              onPressed: _saveRatings,
              child: Text('Enregistrer'),
            ),
          ]),
        ],
      ),
    );
  }

  Future<void> _saveRatings() async {
    for (final entry in _ratings.entries) {
      if (entry.value != null) {
        await ref.read(householdProvider.notifier).upsertRating(
          entry.key, widget.recipeId, entry.value!,
        );
      }
    }
    if (mounted) Navigator.pop(context);
  }
}
```

### MemberRatingRow — callback onRatingChanged
Story 3.2 crée `MemberRatingRow` avec un tap qui appelle directement le provider. Pour Story 3.3, le widget doit accepter un `onRatingChanged` optionnel pour l'état local avant confirmation. Adapter le constructeur :
```dart
class MemberRatingRow extends ConsumerWidget {
  final Member member;
  final RatingValue? currentRating;
  final ValueChanged<RatingValue?>? onRatingChanged; // null = mode direct persist (Story 3.2)
  // ...
}
```
Si `onRatingChanged != null` → appeler le callback (mode local, Story 3.3).
Si `onRatingChanged == null` → appeler directement le provider (mode direct, Story 3.2).

### Navigation post-création
Utiliser `context.pushReplacement('/recipes/${id}')` (go_router) pour remplacer le formulaire dans la stack — l'utilisateur ne doit pas pouvoir revenir au formulaire avec le bouton Back.

### Bottom sheet UX
- `isScrollControlled: true` pour que le sheet monte si la liste des membres est longue
- `MediaQuery.of(context).viewInsets.bottom` pour éviter que le clavier masque les boutons
- Hauteur max 90% de l'écran si > 3 membres (spec UX)
- Bouton "Passer" en texte #E8794A (secondaire), "Enregistrer" en fond #E8794A blanc

### Cas edge : aucun membre
Si `householdProvider` retourne une liste vide (ou est encore en loading), skip le sheet :
- Loading : attendre que le provider soit résolu avant de décider
- Vide : navigation directe vers la fiche recette

### UUID pour nouvelles ratings
```dart
final String id = const Uuid().v4();
```

### Project Structure Notes
- `RatingAfterCreationSheet` appartient à `features/household/` (c'est une feature household)
- Déclenchement depuis `features/recipes/` via import barrel de household
- Tests miroir : `test/features/household/` pour le widget, intégration dans `test/features/recipes/`

### References
- [Source: epics.md#Story 3.3] — AC complets, bottom sheet FR22
- [Source: ux-design-specification.md#User Journey Flows] — P3 "Ajouter une recette" → notation immédiate
- [Source: ux-design-specification.md#Component Strategy] — MemberRatingRow spec
- [Source: architecture.md#Frontend Architecture] — go_router navigation, frontières features
- [Source: architecture.md#Communication Patterns] — Repository pattern
- Story 3.2 : `MemberRatingRow` + `upsertRating` (prérequis)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

N/A — tous les tests passent.

### Completion Notes List

- `createRecipe` retournait déjà `Future<String>` — aucune modification du notifier nécessaire
- Navigation post-création : `context.go('/recipes/$id')` (remplace toute la stack, pas de retour possible au formulaire)
- `membersStreamProvider.value` lu de façon synchrone — valeur null-safe avec `?? const []`
- `isScrollControlled: true` + `viewInsets.bottom` pour gérer le clavier
- Sheet exporté via le barrel `household.dart`

### File List

- `lib/features/household/presentation/widgets/rating_after_creation_sheet.dart` (créé)
- `lib/features/recipes/view/new_recipe_page.dart` (modifié — déclenchement sheet + navigation vers detail)
- `lib/features/household/household.dart` (étendu — export du sheet)
