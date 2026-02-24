# Story 6.2 : Débloquage de la Génération

Status: done

---

## Story

En tant qu'utilisateur,
Je veux que la génération se débloque automatiquement dès 3 recettes dans ma collection,
Afin de pouvoir générer mon premier menu dès que j'ai un minimum viable de recettes.

---

## Acceptance Criteria

1. **Given** j'ai moins de 3 recettes dans ma collection — **When** je suis sur l'écran Accueil — **Then** le bouton Générer est désactivé avec un message `"Ajoute encore X recette(s) pour générer"` où X = 3 - recetteCount (FR39).

2. **And** un compteur dynamique `"X/3 recettes"` indique la progression vers le débloquage (sous le bouton désactivé ou dans un banner informatif).

3. **Given** j'atteins 3 recettes dans ma collection — **When** la 3e recette est sauvegardée — **Then** le bouton Générer devient actif et le message de progression disparaît.

4. **And** le débloquage est réactif : pas besoin de recharger l'app (stream drift → reactive UI automatique).

5. **And** si l'utilisateur a ≥ 3 recettes depuis le début (ex: app existante), le bouton est actif dès le lancement.

---

## Tasks / Subtasks

- [x] **Task 1 — recipeCountProvider** (AC: #1, #2, #3, #4)
  - [x] Ajouter `recipeCountProvider` dans `lib/features/recipes/presentation/providers/recipes_provider.dart`
  - [x] `Provider<int>` dérivé de `recipesStreamProvider` : `recipes.length`
  - [x] Ajouter `canGenerateProvider` : `Provider<bool>` → `recipeCount >= 3`

- [x] **Task 2 — HomeScreen — bouton désactivé + compteur** (AC: #1, #2, #3)
  - [x] Dans `home_screen.dart` : regarder `canGenerateProvider` et `recipeCountProvider`
  - [x] Si `canGenerate == false` : bouton Générer `onPressed: null` (désactivé Material 3 auto)
  - [x] Afficher sous le bouton : banner `"Ajoute encore X recette(s) pour générer un menu"` avec icône info orange
  - [x] Si `canGenerate == true` : bouton actif, banner masqué

- [x] **Task 3 — Tests** (AC: #1, #2, #3, #5)
  - [x] Créer `test/features/generation/presentation/widgets/generation_unlock_test.dart`
  - [x] Test : canGenerateProvider = false quand < 3 recettes
  - [x] Test : canGenerateProvider = true quand >= 3 recettes
  - [x] Test widget : banner visible quand 0 recettes (message "3 recettes")
  - [x] Test widget : banner visible quand 2 recettes (message "1 recette")
  - [x] Test widget : banner masqué quand 3 recettes

---

## Dev Notes

### Providers dérivés

```dart
// Dans recipes_provider.dart
/// Nombre de recettes dans la collection.
final recipeCountProvider = Provider<int>((ref) {
  final recipesAsync = ref.watch(recipesStreamProvider);
  return recipesAsync.valueOrNull?.length ?? 0;
});
```

Le provider doit se mettre à jour automatiquement car il dérive de `recipesStreamProvider` (stream drift).

Dans `generation_provider.dart` ou directement dans `home_screen.dart`, ajouter :
```dart
/// True si l'utilisateur peut générer un menu (min 3 recettes).
final canGenerateProvider = Provider<bool>((ref) {
  return ref.watch(recipeCountProvider) >= 3;
});
```

### Banner informatif (ton humain)

```dart
// Exemples de messages (humains et guidants)
if (remaining == 1) "Plus qu'1 recette avant de pouvoir générer !"
if (remaining == 2) "Ajoute 2 recettes pour débloquer la génération"
if (remaining == 3) "Commence par ajouter 3 recettes — c'est rapide !"
// Générique : "Ajoute encore $remaining recette(s) pour générer"
```

### HomeScreen — Intégration

La logique de désactivation du bouton doit coexister avec la logique existante dans `HomeScreen` (génération loading, état du menu, etc.). Implémenter via condition composée :

```dart
final canGenerate = ref.watch(canGenerateProvider);
final isGenerating = ref.watch(generateMenuProvider).isLoading;

// Bouton Générer
FilledButton(
  onPressed: (canGenerate && !isGenerating) ? _generate : null,
  child: const Text('Générer'),
)
```

### References

- FR39 (débloquage génération) : [Source: `_bmad-output/planning-artifacts/epics.md` — Story 6.2]
- HomeScreen existant : `lib/features/generation/presentation/screens/home_screen.dart`

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6 (dev-story workflow)

### Debug Log References

### Completion Notes List

- recipeCountProvider et canGenerateProvider ajoutés dans recipes_provider.dart (dérivés de recipesStreamProvider)
- _GenerationUnlockBanner widget privé dans home_screen.dart — messages humains selon remaining
- Bouton Générer désactivé via onPressed: null (Material 3 gère le style automatiquement)
- Tests widget via HomeScreen réel avec override de recipeCountProvider

### Code Review Fixes (2026-02-23)

- [M3] Magic number 3 → kMinRecipesForGeneration dans canGenerateProvider et _GenerationUnlockBanner
- [H3] Ajout 3 tests widget vérifiant l'état du bouton Générer (désactivé/actif)

### File List

- lib/features/recipes/presentation/providers/recipes_provider.dart (modifié — ajout recipeCountProvider, canGenerateProvider)
- lib/features/generation/presentation/screens/home_screen.dart (modifié — banner + bouton conditionnel + constante)
- lib/core/constants/generation_constants.dart (nouveau — constante partagée)
- test/features/generation/presentation/widgets/generation_unlock_test.dart

