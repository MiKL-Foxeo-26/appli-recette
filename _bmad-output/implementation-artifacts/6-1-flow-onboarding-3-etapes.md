# Story 6.1 : Flow Onboarding 3 Étapes

Status: done

---

## Story

En tant que nouvel utilisateur,
Je veux être guidé à travers 3 étapes claires lors de la première ouverture,
Afin de configurer mon foyer, mon planning et mes premières recettes rapidement.

---

## Acceptance Criteria

1. **Given** c'est la première ouverture de l'app (aucun foyer configuré) — **When** l'app se lance — **Then** l'écran `OnboardingScreen` s'affiche avec indicateur de progression (3 étapes) (FR38).

2. **And** Étape 1/3 : créer les profils membres (nom + âge), au minimum 1 membre requis — bouton Suivant désactivé tant qu'aucun membre n'est créé.

3. **And** Étape 2/3 : configurer le planning type avec la `PresenceToggleGrid` — bouton Suivant actif dès l'étape ouverte (le planning est optionnel à modifier).

4. **And** Étape 3/3 : ajouter les premières recettes avec compteur `"X/3 recettes"` — bouton Terminer actif dès que le compteur atteint ≥ 1 recette.

5. **And** chaque étape peut être complétée et passée via le bouton Suivant / Terminer.

6. **And** après avoir tapé Terminer (étape 3), le flag `onboarding_complete` est sauvegardé (SharedPreferences) — l'app navigue vers l'écran principal (`/`).

7. **And** l'onboarding est ignoré aux ouvertures suivantes : `App` vérifie le flag et affiche directement `MaterialApp.router` si `onboarding_complete == true`.

---

## Tasks / Subtasks

- [x] **Task 1 — OnboardingService** (AC: #6, #7)
  - [x] Ajouter `shared_preferences: ^2.3.5` dans `pubspec.yaml`
  - [x] Créer `lib/features/onboarding/domain/onboarding_service.dart`
  - [x] `isComplete()` → `SharedPreferences.getBool('onboarding_complete') ?? false`
  - [x] `setComplete()` → `SharedPreferences.setBool('onboarding_complete', true)`

- [x] **Task 2 — OnboardingProvider** (AC: #6, #7)
  - [x] Créer `lib/features/onboarding/presentation/providers/onboarding_provider.dart`
  - [x] `onboardingServiceProvider` : Provider<OnboardingService>
  - [x] `OnboardingNotifier` : AsyncNotifier<bool> — build() lit isComplete(), complete() appelle setComplete() puis state=true

- [x] **Task 3 — Step screens** (AC: #2, #3, #4)
  - [x] Créer `lib/features/onboarding/presentation/screens/step1_household_screen.dart` — formulaire inline nom+âge, bouton Ajouter + liste des membres créés
  - [x] Créer `lib/features/onboarding/presentation/screens/step2_planning_screen.dart` — PresenceToggleGrid avec les membres existants
  - [x] Créer `lib/features/onboarding/presentation/screens/step3_recipes_screen.dart` — champ nom recette + bouton Ajouter + compteur "X/3 recettes"

- [x] **Task 4 — OnboardingScreen principal** (AC: #1, #5)
  - [x] Créer `lib/features/onboarding/presentation/screens/onboarding_screen.dart`
  - [x] PageView(physics: NeverScrollable) + PageController
  - [x] Indicateur progression : 3 dots (AnimatedContainer) ou LinearProgressIndicator
  - [x] Bouton Suivant/Terminer conditionnel selon l'étape
  - [x] Navigation vers '/' après complete()

- [x] **Task 5 — Guard dans App** (AC: #7)
  - [x] Transformer `App` en `StatelessWidget` avec `_AppContent` ConsumerWidget interne
  - [x] `_AppContent` regarde `onboardingNotifierProvider` (AsyncValue<bool>)
  - [x] loading → splash (CircularProgressIndicator centré)
  - [x] data(false) → OnboardingScreen
  - [x] data(true) → MaterialApp.router (routerConfig: appRouter)

- [x] **Task 6 — Tests** (AC: #6, #7)
  - [x] Créer `test/features/onboarding/presentation/screens/onboarding_screen_test.dart`
  - [x] Test : indicateur progression visible à l'étape 1
  - [x] Test : bouton Suivant désactivé si aucun membre (étape 1)
  - [x] Test : bouton Suivant activé après ajout membre (étape 1)

---

## Dev Notes

### Choix SharedPreferences vs drift

`shared_preferences` est utilisé à la place d'une table drift pour éviter une migration de schéma (schemaVersion: 1 → 2). Ce flag ne nécessite pas de synchronisation Supabase — c'est un flag device-local. SharedPreferences est standard pour ce cas d'usage.

### Guard dans App — Pattern ConsumerWidget imbriqué

```dart
// app/view/app.dart
class App extends StatelessWidget {
  const App({required this.database, required this.config, super.key});
  final AppDatabase database;
  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [databaseProvider.overrideWithValue(database)],
      child: _AppContent(config: config),
    );
  }
}

class _AppContent extends ConsumerWidget {
  const _AppContent({required this.config});
  final AppConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingAsync = ref.watch(onboardingNotifierProvider);
    final materialApp = MaterialApp.router(
      title: 'Appli Recette',
      theme: AppTheme.light,
      routerConfig: appRouter,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: config.isDevelopment,
    );

    return onboardingAsync.when(
      loading: () => const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (_, __) => materialApp,
      data: (isComplete) => isComplete
          ? materialApp
          : const MaterialApp(home: OnboardingScreen()),
    );
  }
}
```

### Step 1 — Création membre inline

Réutiliser les mêmes champs que `MemberFormPage` mais sans navigation go_router :
- `TextFormField` pour le prénom (obligatoire)
- `TextFormField` pour l'âge (optionnel)
- Bouton `Ajouter` → `ref.read(householdNotifierProvider.notifier).addMember(...)`
- Après ajout → initialiser planning type via `planningNotifier.initializeForNewMember(id)`
- Liste des membres créés affichée sous le formulaire (Chip ou ListTile)

### Step 2 — Planning type

```dart
// Utiliser les providers existants (pas de bridge cross-feature nécessaire ici)
final members = ref.watch(membersStreamProvider).valueOrNull ?? [];
final presences = ref.watch(defaultPresencesStreamProvider).valueOrNull ?? [];

PresenceToggleGrid(members: members, presences: presences) // weekKey == null = planning type
```

### Step 3 — Ajout rapide recettes

Un formulaire minimal : nom de recette + type repas (lunch/dinner) + bouton Ajouter.
Utiliser `RecipesNotifier.createRecipe(...)`.
Afficher un compteur "X/3 recettes" qui se met à jour automatiquement en regardant `recipesStreamProvider`.

### Indicateur de progression

```dart
// 3 dots animés
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: List.generate(3, (i) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    width: i == _currentPage ? 20 : 8,
    height: 8,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    decoration: BoxDecoration(
      color: i == _currentPage ? AppColors.primary : AppColors.disabled,
      borderRadius: BorderRadius.circular(4),
    ),
  )),
)
```

### References

- FR38 (onboarding 3 étapes) : [Source: `_bmad-output/planning-artifacts/epics.md` — Story 6.1]
- Architecture onboarding : [Source: `_bmad-output/planning-artifacts/architecture.md` — features/onboarding/]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6 (dev-story workflow)

### Debug Log References

### Completion Notes List

- OnboardingService utilise SharedPreferences (flag device-local, pas de sync Supabase)
- Guard dans App via pattern ConsumerWidget imbriqué (_AppContent)
- Tests couvrent : OnboardingService (3 tests unitaires) + OnboardingScreen widget (4 tests)

### Code Review Fixes (2026-02-23)

- [M1] OnboardingNotifier.build() : ref.read → ref.watch (Riverpod best practice)
- [M2] OnboardingNotifier.complete() : ajout AsyncValue.guard() pour error handling
- [M3] Magic number 3 → kMinRecipesForGeneration (constante partagée)
- [M4] Ajout navigation retour (bouton Retour) dans step2 et step3
- [H1] prepTimeMinutes: 0 → 15 (défaut raisonnable)
- [H2] Suppression meal types breakfast/snack/dessert de l'onboarding (non utilisés par la génération)

### File List

- lib/features/onboarding/domain/onboarding_service.dart
- lib/features/onboarding/presentation/providers/onboarding_provider.dart
- lib/features/onboarding/presentation/screens/onboarding_screen.dart
- lib/features/onboarding/presentation/screens/step1_household_screen.dart
- lib/features/onboarding/presentation/screens/step2_planning_screen.dart
- lib/features/onboarding/presentation/screens/step3_recipes_screen.dart
- lib/app/view/app.dart (modifié — guard onboarding)
- lib/core/constants/generation_constants.dart (nouveau — constante partagée)
- test/features/onboarding/presentation/screens/onboarding_screen_test.dart

