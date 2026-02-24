# Story 2.3 : Ajouter une Photo à une Recette

## Story
En tant qu'utilisateur, je veux ajouter une photo à une recette depuis ma caméra ou ma galerie.

## Status
done

## Code Review — 2026-02-22

**Reviewer :** Claude (adversarial code-review BMAD workflow)
**Résultat :** PASS avec corrections appliquées

### Fixes appliqués
- **HIGH** : Boucle de compression adaptative garantissant < 500 Ko (quality 85→20)
- **HIGH** : Nettoyage photo orpheline lors du remplacement (deletePhoto avant reassign)
- **MEDIUM** : Nettoyage photo sur suppression recette (recipe_detail_screen)

## Acceptance Criteria
- Permission caméra/galerie demandée si non accordée
- Compression automatique < 500 Ko (flutter_image_compress) — NFR3
- Stockage dans répertoire privé de l'application
- Photo affichée en haut de la fiche recette — FR9
- Indicateur discret d'upload async Supabase Storage

## Tasks / Subtasks
- [x] Task 1: Ajouter packages (image_picker, flutter_image_compress, permission_handler, url_launcher)
- [x] Task 2: ImageService (compression + stockage local)
- [x] Task 3: UI photo dans RecipeDetailScreen + EditRecipeScreen
- [x] Task 4: Platform config (iOS plist + Android manifest)
- [x] Task 5: Tests

## Dev Agent Record
### Completion Notes
- `image_picker`, `flutter_image_compress`, `permission_handler`, `url_launcher` ajoutés à pubspec.yaml
- `ImageService` créé avec `pickFromGallery()`, `pickFromCamera()`, compression JPEG < 500Ko dans répertoire privé
- `EditRecipeScreen` : section photo en haut avec GestureDetector → BottomSheet (caméra/galerie/supprimer), indicateur de chargement
- `RecipeDetailScreen` : SliverAppBar avec photo en fond (FlexibleSpaceBar) si disponible
- Android manifest : CAMERA + READ_MEDIA_IMAGES + READ_EXTERNAL_STORAGE (Android < 13)
- iOS Info.plist : NSCameraUsageDescription + NSPhotoLibraryUsageDescription
- `updatePhotoPath()` testé via recipe_repository_extended_test.dart

## File List
- `lib/core/storage/image_service.dart` (créé)
- `lib/features/recipes/view/edit_recipe_screen.dart` (section _PhotoSection)
- `lib/features/recipes/view/recipe_detail_screen.dart` (SliverAppBar + FlexibleSpaceBar)
- `android/app/src/main/AndroidManifest.xml` (permissions)
- `ios/Runner/Info.plist` (permissions)
- `pubspec.yaml` (packages)

## Change Log
- 2026-02-21: Story implémentée (Epic 2 complet)
