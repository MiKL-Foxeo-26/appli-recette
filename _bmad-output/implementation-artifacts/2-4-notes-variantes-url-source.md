# Story 2.4 : Notes, Variantes et URL Source

## Story
En tant qu'utilisateur, je veux ajouter des notes libres, des variantes/astuces et une URL source à une recette.

## Status
done

## Code Review — 2026-02-22

**Reviewer :** Claude (adversarial code-review BMAD workflow)
**Résultat :** PASS avec corrections appliquées

### Fixes appliqués
- **HIGH** : Accessibilité URL source — Semantics(link: true) + InkWell au lieu de GestureDetector
- **HIGH** : Ajout https:// auto si pas de scheme dans l'URL source
- **MEDIUM** : Validation URL dans le champ sourceUrl du formulaire d'édition

## Acceptance Criteria
- Notes libres (texte multiligne) — FR10
- Variantes/astuces (texte multiligne) — FR11
- URL source — FR12
- Sauvegardées et affichées sur la fiche recette
- Champs labellisés et accessibles (WCAG AA)

## Tasks / Subtasks
- [x] Task 1: Section 3 dans EditRecipeScreen (notes, variantes, url)
- [x] Task 2: Affichage dans RecipeDetailScreen
- [x] Task 3: Tests

## Dev Agent Record
### Completion Notes
- `EditRecipeScreen` Section 3 "Notes & Sources" : champs multilignes (notes + variantes) + URL source
- `RecipeDetailScreen` : affichage conditionnel notes/variantes/sourceUrl avec GestureDetector → launchUrl
- Champs accessibles via InputDecoration labelText + alignLabelWithHint
- Tests via recipe_repository_extended_test.dart (Story 2-4 group)

## File List
- `lib/features/recipes/view/edit_recipe_screen.dart` (Section 3)
- `lib/features/recipes/view/recipe_detail_screen.dart` (affichage notes/variantes/URL)
- `test/features/recipes/data/repositories/recipe_repository_extended_test.dart` (group Story 2-4)

## Change Log
- 2026-02-21: Story implémentée (Epic 2 complet)
