---
stepsCompleted: [step-01-init, step-02-context, step-03-starter, step-04-decisions, step-05-patterns, step-06-structure, step-07-validation, step-08-complete]
status: 'complete'
completedAt: '2026-02-18'
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/planning-artifacts/product-brief-appli-recette-2026-02-17.md
  - _bmad-output/planning-artifacts/ux-design-specification.md
workflowType: 'architecture'
project_name: 'appli-recette'
user_name: 'MiKL'
date: '2026-02-18'
---

# Architecture Decision Document — Appli Recette

_Ce document se construit de manière collaborative à travers une découverte étape par étape. Les sections sont ajoutées au fil des décisions architecturales prises ensemble._

---

## Project Context Analysis

### Requirements Overview

**Functional Requirements — 39 FRs en 5 domaines :**
- Recettes (FR1–16) : CRUD complet, favoris, photos, tags structurés
- Foyer (FR17–22) : profils membres, notation aimé/neutre/pas aimé par recette
- Planning de présence (FR23–25) : planning type + overrides ponctuels par semaine
- Génération de menus (FR26–37) : algorithme multi-critères, génération partielle, historique anti-répétition
- Onboarding (FR38–39) : guidé en 3 étapes, débloqué dès 3 recettes

**Non-Functional Requirements :**
- Performance : génération < 2s, navigation < 1s, images < 500 Ko
- Fiabilité : persistance totale, suppression confirmée
- Utilisabilité : 3 taps max, zone pouce, WCAG AA, offline-first total

**Scale & Complexity :**
- Domaine technique primaire : Mobile cross-platform (iOS/Android)
- Niveau de complexité : Faible-Moyenne
- Composants architecturaux estimés : 5–7

### Tension Architecturale Fondatrice

Le PRD stipule un stockage 100% local (pas de backend), aucune authentification, aucune synchronisation. La spec UX propose une révision majeure vers un modèle cloud (Supabase) avec authentification par Code Foyer et synchronisation multi-appareils. Cette décision conditionne l'intégralité de l'architecture technique et doit être tranchée en premier.

### Technical Constraints & Dependencies

- Framework mobile : cross-platform (React Native ou Flutter — non tranché)
- Distribution : hors stores (TestFlight + APK sideload)
- Offline-first : obligatoire quelle que soit la décision de persistance
- Permissions device : caméra, galerie, stockage local
- Design System : Material Design 3

### Cross-Cutting Concerns Identifiés

1. **Gestion d'état globale** — état complexe multi-domaines (recettes, membres, planning, menus) à partager entre écrans
2. **Persistance des données** — locale (SQLite) ou hybride (cache local + Supabase)
3. **Algorithme de génération** — logique métier centrale, performances critiques, testabilité requise
4. **Gestion des images** — capture, compression, stockage local ou upload cloud
5. **Navigation multi-niveaux** — 4 onglets bottom + sous-écrans + modals + bottom sheets
6. **Synchronisation offline/online** — si cloud adopté : conflict resolution, queue locale

---

## Starter Template Evaluation

### Primary Technology Domain

Application mobile cross-platform (iOS ≥ 16 / Android ≥ 10)

### Décision Framework : Flutter

Flutter retenu pour les raisons suivantes :
- Material Design 3 natif (aucune dépendance tierce)
- Performance compilée native pour UI complexe (WeekGridComponent)
- Dart typé — idéal pour l'algorithme de génération multi-critères
- SDK Supabase officiel Flutter v2.12.0 disponible si cloud adopté
- Alignement total avec la spec UX (snippets Dart déjà écrits par Sally)
- Toolchain unifié — DX optimisée pour développeur solo

### Stack de Base

| Composant | Technologie | Version |
|-----------|-------------|---------|
| Framework | Flutter | 3.41 |
| Langage | Dart | 3.11 |
| State Management | Riverpod | via VGC |
| Design System | Material Design 3 | natif |
| Stockage local | drift (SQLite ORM) | à ajouter |
| Backend (conditionnel) | Supabase Flutter SDK | 2.12.0 |

### Starter Sélectionné : Very Good CLI

**Rationale :** Architecture propre (feature-first), build flavors (dev/staging/prod), tests infrastructure, linting — production-ready dès le départ sans configuration manuelle.

### Commande d'Initialisation

```bash
dart pub global activate very_good_cli
very_good create flutter_app appli_recette \
  --org com.mikl.recette \
  --platforms android,ios
```

**Note :** L'initialisation du projet est la première story d'implémentation.

---

## Core Architectural Decisions

### Decision Priority Analysis

**Décisions Critiques (bloquantes pour l'implémentation) :**
- Persistance cloud Supabase + cache local drift
- Authentification Code Foyer 6 chiffres
- Stratégie offline-first avec queue de sync

**Décisions Importantes (structurent l'architecture) :**
- Navigation go_router
- Structure feature-first (VGC)
- Algorithme de génération isolé en service Dart

**Décisions Différées (post-MVP) :**
- Monitoring et analytics
- Stratégie de mise à jour OTA

---

### Data Architecture

**Persistance : Hybride drift (local) + Supabase (cloud)**
- drift (SQLite ORM) comme source de vérité locale — toutes les lectures/écritures passent par drift d'abord
- Supabase PostgreSQL comme source de vérité cloud — synchronisation en arrière-plan
- Queue de sync locale : toute opération offline est enfilée et rejouée au retour du réseau
- Conflict resolution : Last write wins (timestamp serveur Supabase)

**Stockage des images**
- Compression immédiate < 500 Ko avant tout stockage (package flutter_image_compress)
- Stockage dans le répertoire privé de l'application (jamais dans la galerie)
- Upload asynchrone vers Supabase Storage en arrière-plan
- Cache local permanent de toutes les images (pas de lazy-loading)

---

### Authentication & Security

**Code Foyer 6 chiffres**
- Appareil 1 crée le foyer → génère un code numérique unique à 6 chiffres
- Appareil 2 rejoint via ce code → synchronisation immédiate
- Aucun email, aucun mot de passe, aucun compte tiers
- Tous les membres adultes : droits lecture + écriture complets
- Aucune hiérarchie de rôles en V1

**Données privées**
- Aucune donnée transmise à des tiers (hors Supabase)
- Supabase Row Level Security (RLS) : chaque foyer accède uniquement à ses propres données

---

### API & Communication

**Architecture interne uniquement (pas d'API publique)**
- Communication via Supabase SDK Flutter (Realtime + REST auto-généré)
- Supabase Realtime pour la synchronisation temps réel entre appareils du foyer
- Toutes les opérations passent par la couche Repository (drift en local, Supabase en remote)
- Pattern Repository avec abstraction de la source de données

---

### Frontend Architecture

**Navigation : go_router**
- Routing déclaratif, deep links, shell routes pour les 4 onglets bottom nav
- Structure : ShellRoute (bottom nav) → onglets Accueil / Recettes / Foyer / Planning

**Structure : Feature-first (Very Good CLI)**
```
lib/
├── features/
│   ├── recipes/        # Bloc A — CRUD recettes, favoris, photos
│   ├── household/      # Bloc B — profils membres, notations
│   ├── planning/       # Bloc C — planning présence, overrides
│   ├── generation/     # Algorithme + génération menu
│   └── onboarding/     # 3 étapes première ouverture
├── core/
│   ├── database/       # drift models + DAOs
│   ├── sync/           # Queue offline + Supabase sync
│   ├── storage/        # Image compression + Supabase Storage
│   └── theme/          # Material Design 3 tokens
```

**State Management : Riverpod**
- Providers par feature, isolation complète
- AsyncNotifier pour les opérations async (sync, génération)
- Pas de state global partagé entre features sauf via Repository

**Algorithme de génération : Service Dart isolé**
Logique en couches séquentielles :
1. Filtrer recettes selon présences du repas
2. Exclure "pas aimé" des membres présents
3. Prioriser favoris
4. Prioriser "aimé" des membres présents
5. Anti-répétition (historique menus validés)
6. Appliquer filtres utilisateur (saison / végé / temps max)
7. Compléter aléatoirement (seed reproductible) si besoin
8. Génération partielle + messages guidants si stock insuffisant

Classe pure Dart, 0 dépendance UI, 100% testable unitairement. Cible : exécution < 2 secondes sur device standard.

---

### Infrastructure & Deployment

**Distribution hors stores**
- iOS : TestFlight (distribution bêta Apple)
- Android : APK sideload (installation manuelle)

**CI/CD : GitHub Actions (fourni par VGC)**
- Build flavors : development / production
- Tests automatiques sur chaque PR
- Build artifacts (.ipa / .apk) générés automatiquement

**Environnements**
- Development : Supabase project dédié dev
- Production : Supabase project dédié prod

---

### Decision Impact Analysis

**Séquence d'implémentation recommandée :**
1. Init projet VGC + configuration drift + Supabase
2. Schéma BDD (drift models + migrations Supabase)
3. Feature Recipes (Bloc A) — CRUD + photos
4. Feature Household (Bloc B) — profils + notations
5. Feature Planning (Bloc C) — planning présence
6. Feature Generation — algorithme + UI grille semaine
7. Onboarding 3 étapes
8. Sync offline + queue Supabase
9. Code Foyer — auth + multi-appareils

**Dépendances inter-composants :**
- L'algorithme de génération dépend de Recipes + Household + Planning
- La sync Supabase dépend du schéma drift finalisé
- L'onboarding dépend de Household + Planning + Recipes (au moins 3)

---

## Implementation Patterns & Consistency Rules

### Naming Patterns

**Dart / Flutter (code)**
- Classes : PascalCase → `RecipeRepository`, `GenerationService`
- Fichiers : snake_case → `recipe_repository.dart`, `generation_service.dart`
- Variables / fonctions : camelCase → `currentRecipe`, `generateMenu()`
- Constantes : camelCase → `maxPhotoSizeKb`
- Providers Riverpod : camelCase + suffixe `Provider` → `recipesProvider`, `householdProvider`

**drift (SQLite local)**
- Classes de table : PascalCase + suffixe `Table` → `RecipesTable`, `MembersTable`
- Colonnes : camelCase dans Dart → `createdAt`, `isFavorite`
- Noms de tables en base : snake_case → `recipes`, `members`, `meal_ratings`

**Supabase (PostgreSQL cloud)**
- Tables : snake_case pluriel → `recipes`, `household_members`, `meal_ratings`, `weekly_menus`
- Colonnes : snake_case → `recipe_id`, `created_at`, `is_favorite`
- Clés primaires : UUID v4 — jamais int autoincrement
- Clés étrangères : `{table_singulier}_id` → `recipe_id`, `member_id`

---

### Structure Patterns

**Organisation par feature (VGC) — règle absolue**

```
features/{nom_feature}/
├── data/
│   ├── models/          # Classes drift + Supabase DTOs
│   ├── repositories/    # Implémentation concrète
│   └── datasources/     # drift DAO + Supabase calls
├── domain/
│   └── repositories/    # Interfaces abstraites
├── presentation/
│   ├── screens/         # Écrans complets
│   ├── widgets/         # Composants locaux à la feature
│   └── providers/       # Riverpod providers
```

**Règle de dépendance stricte**
- `presentation` → `domain` → `data` (jamais dans l'autre sens)
- Features ne s'importent pas entre elles (passer par `core/`)
- Algorithme de génération : `features/generation/domain/services/generation_service.dart`

**Tests : miroir de lib/**
```
test/
└── features/
    └── generation/
        └── domain/
            └── services/
                └── generation_service_test.dart
```

---

### Format Patterns

**IDs : UUID partout**
```dart
// ✅ Correct
final String id = const Uuid().v4();
// ❌ Interdit
final int id = autoIncrement;
```

**Dates : DateTime en Dart, ISO 8601 en Supabase**
```dart
// ✅ Stockage Supabase
'created_at': DateTime.now().toUtc().toIso8601String()
// ✅ drift — utiliser DateTimeConverter intégré
```

**Résultat d'opération : AsyncValue (Riverpod)**
```dart
// ✅ Pattern loading/error/data
final recipesAsync = ref.watch(recipesProvider);
return recipesAsync.when(
  loading: () => const CircularProgressIndicator(),
  error: (e, st) => ErrorWidget(e),
  data: (recipes) => RecipesList(recipes),
);
```

---

### Communication Patterns

**Repository Pattern — interface obligatoire**
```dart
// ✅ Interface dans domain/
abstract class RecipeRepository {
  Future<List<Recipe>> getAll();
  Future<void> save(Recipe recipe);
  Future<void> delete(String id);
}
// ✅ Implémentation dans data/
class RecipeRepositoryImpl implements RecipeRepository { ... }
```

**Sync Queue — pattern uniforme**
```
Toute opération offline s'enregistre dans sync_queue
Structure : { id, operation, entity, payload, createdAt }
Retry automatique au retour réseau
```

**Nommage des Providers Riverpod**
```dart
// ✅ AsyncNotifierProvider pour les opérations async
final recipesProvider = AsyncNotifierProvider<RecipesNotifier, List<Recipe>>(
  RecipesNotifier.new,
);
// ✅ Provider simple pour les valeurs dérivées
final favoriteRecipesProvider = Provider<List<Recipe>>((ref) {
  return ref.watch(recipesProvider).value?.where((r) => r.isFavorite).toList() ?? [];
});
```

---

### Process Patterns

**Gestion d'erreurs**
- Erreurs utilisateur → Snackbar Material 3 (message humain, jamais de stacktrace)
- Erreurs de sync → SyncStatusBadge ☁️⚠️ (silencieux, pas de dialog)
- Suppressions → Dialog de confirmation obligatoire (jamais au swipe seul)
- Cas limite génération → Card warning avec options de résolution (jamais erreur froide)

**Loading states**
- Local (drift) : pas de spinner (instantané)
- Remote (Supabase sync) : SyncStatusBadge discret en top bar
- Génération de menu : Progress indicator centré avec animation
- Upload photo : indicateur discret sur la fiche recette

**Pipeline images — obligatoire**
```
Camera/Galerie → flutter_image_compress (max 500 Ko)
→ stockage local privé → upload Supabase Storage async
```

---

### Enforcement Guidelines

**Tous les agents IA DOIVENT :**
- Utiliser UUID v4 pour tous les IDs (jamais d'int autoincrement)
- Nommer les fichiers Dart en snake_case
- Respecter la structure feature-first sans cross-imports entre features
- Passer par le Repository pour tout accès aux données (jamais drift/Supabase directement dans les widgets)
- Compresser les images avant tout stockage (max 500 Ko)
- Utiliser AsyncValue pour tout état async dans Riverpod
- Écrire les tests dans test/ en miroir de lib/

---

## Project Structure & Boundaries

### Complete Project Directory Structure

```
appli_recette/
├── pubspec.yaml                    # Dépendances Flutter
├── pubspec.lock
├── analysis_options.yaml           # Linting VGC
├── .env.development                # Config Supabase dev
├── .env.production                 # Config Supabase prod
├── .gitignore
├── README.md
│
├── .github/
│   └── workflows/
│       ├── main.yaml               # CI/CD VGC — tests + build
│       └── release.yaml            # Build .ipa + .apk
│
├── supabase/
│   ├── config.toml
│   └── migrations/
│       ├── 001_households.sql
│       ├── 002_recipes.sql
│       ├── 003_recipe_ingredients.sql
│       ├── 004_household_members.sql
│       ├── 005_meal_ratings.sql
│       ├── 006_presence_schedules.sql
│       ├── 007_weekly_menus.sql
│       └── 008_menu_slots.sql
│
├── lib/
│   ├── main.dart
│   ├── main_development.dart
│   ├── main_production.dart
│   ├── app.dart                    # MaterialApp + theme + router
│   │
│   ├── core/
│   │   ├── database/
│   │   │   ├── app_database.dart   # drift database class
│   │   │   ├── app_database.g.dart # généré drift
│   │   │   └── tables/
│   │   │       ├── recipes_table.dart
│   │   │       ├── ingredients_table.dart
│   │   │       ├── members_table.dart
│   │   │       ├── ratings_table.dart
│   │   │       ├── presence_table.dart
│   │   │       ├── menus_table.dart
│   │   │       └── sync_queue_table.dart
│   │   ├── sync/
│   │   │   ├── sync_service.dart
│   │   │   ├── sync_queue_processor.dart
│   │   │   └── connectivity_monitor.dart
│   │   ├── storage/
│   │   │   ├── image_service.dart
│   │   │   └── supabase_storage_service.dart
│   │   ├── auth/
│   │   │   ├── household_code_service.dart
│   │   │   └── auth_repository.dart
│   │   ├── router/
│   │   │   ├── app_router.dart
│   │   │   └── routes.dart
│   │   └── theme/
│   │       ├── app_theme.dart
│   │       ├── app_colors.dart     # Palette "Chaleur & Appétit"
│   │       └── app_typography.dart # Nunito + tailles
│   │
│   └── features/
│       ├── onboarding/             # FR38–39
│       │   ├── domain/
│       │   │   └── onboarding_service.dart
│       │   └── presentation/
│       │       ├── screens/
│       │       │   ├── onboarding_screen.dart
│       │       │   ├── step1_household_screen.dart
│       │       │   ├── step2_planning_screen.dart
│       │       │   └── step3_recipes_screen.dart
│       │       └── providers/
│       │           └── onboarding_provider.dart
│       │
│       ├── recipes/                # FR1–16
│       │   ├── data/
│       │   │   ├── models/
│       │   │   │   ├── recipe.dart
│       │   │   │   └── ingredient.dart
│       │   │   ├── datasources/
│       │   │   │   ├── recipe_local_datasource.dart
│       │   │   │   └── recipe_remote_datasource.dart
│       │   │   └── repositories/
│       │   │       └── recipe_repository_impl.dart
│       │   ├── domain/
│       │   │   └── repositories/
│       │   │       └── recipe_repository.dart
│       │   └── presentation/
│       │       ├── screens/
│       │       │   ├── recipes_screen.dart
│       │       │   ├── recipe_detail_screen.dart
│       │       │   └── recipe_form_screen.dart
│       │       ├── widgets/
│       │       │   ├── recipe_card.dart
│       │       │   ├── recipe_quick_form.dart
│       │       │   ├── ingredient_row.dart
│       │       │   └── favorite_button.dart
│       │       └── providers/
│       │           └── recipes_provider.dart
│       │
│       ├── household/              # FR17–22
│       │   ├── data/
│       │   │   ├── models/
│       │   │   │   ├── member.dart
│       │   │   │   └── meal_rating.dart
│       │   │   ├── datasources/
│       │   │   │   ├── member_local_datasource.dart
│       │   │   │   └── member_remote_datasource.dart
│       │   │   └── repositories/
│       │   │       └── household_repository_impl.dart
│       │   ├── domain/
│       │   │   └── repositories/
│       │   │       └── household_repository.dart
│       │   └── presentation/
│       │       ├── screens/
│       │       │   ├── household_screen.dart
│       │       │   └── member_form_screen.dart
│       │       ├── widgets/
│       │       │   ├── member_card.dart
│       │       │   └── member_rating_row.dart
│       │       └── providers/
│       │           └── household_provider.dart
│       │
│       ├── planning/               # FR23–25
│       │   ├── data/
│       │   │   ├── models/
│       │   │   │   ├── presence_schedule.dart
│       │   │   │   └── presence_override.dart
│       │   │   ├── datasources/
│       │   │   │   ├── planning_local_datasource.dart
│       │   │   │   └── planning_remote_datasource.dart
│       │   │   └── repositories/
│       │   │       └── planning_repository_impl.dart
│       │   ├── domain/
│       │   │   └── repositories/
│       │   │       └── planning_repository.dart
│       │   └── presentation/
│       │       ├── screens/
│       │       │   └── planning_screen.dart
│       │       ├── widgets/
│       │       │   └── presence_toggle_grid.dart
│       │       └── providers/
│       │           └── planning_provider.dart
│       │
│       └── generation/             # FR26–37
│           ├── data/
│           │   ├── models/
│           │   │   ├── weekly_menu.dart
│           │   │   └── menu_slot.dart
│           │   ├── datasources/
│           │   │   ├── menu_local_datasource.dart
│           │   │   └── menu_remote_datasource.dart
│           │   └── repositories/
│           │       └── menu_repository_impl.dart
│           ├── domain/
│           │   ├── repositories/
│           │   │   └── menu_repository.dart
│           │   └── services/
│           │       └── generation_service.dart  # Algorithme pur Dart
│           └── presentation/
│               ├── screens/
│               │   └── home_screen.dart
│               ├── widgets/
│               │   ├── week_grid.dart
│               │   ├── meal_slot_card.dart
│               │   ├── meal_slot_bottom_sheet.dart
│               │   └── generation_filters_sheet.dart
│               └── providers/
│                   ├── generation_provider.dart
│                   └── menu_provider.dart
│
└── test/
    ├── helpers/
    │   ├── test_helpers.dart
    │   └── mock_repositories.dart
    └── features/
        ├── recipes/
        │   └── data/repositories/
        │       └── recipe_repository_test.dart
        ├── household/
        │   └── data/repositories/
        │       └── household_repository_test.dart
        ├── planning/
        │   └── data/repositories/
        │       └── planning_repository_test.dart
        └── generation/
            └── domain/services/
                └── generation_service_test.dart
```

### Architectural Boundaries

| Frontière | Règle |
|-----------|-------|
| `core/` → `features/` | Autorisé (core est partagé) |
| `features/` → `features/` | **Interdit** (isolation stricte) |
| `presentation/` → `data/` | **Interdit** (passer par `domain/`) |
| Widget → drift/Supabase direct | **Interdit** (passer par Repository) |

### Requirements to Structure Mapping

| FR | Feature | Fichier principal |
|----|---------|-------------------|
| FR1–16 | recipes | `recipe_form_screen.dart`, `recipe_repository.dart` |
| FR17–22 | household | `member_form_screen.dart`, `member_rating_row.dart` |
| FR23–25 | planning | `planning_screen.dart`, `presence_toggle_grid.dart` |
| FR26–37 | generation | `generation_service.dart`, `week_grid.dart` |
| FR38–39 | onboarding | `onboarding_screen.dart`, `step1–3_*.dart` |

### Data Flow

```
UI Widget
  → Provider (Riverpod / AsyncNotifier)
    → Repository Interface (domain/)
      → [Local] drift DAO → SQLite (instantané)
      → [Remote] Supabase SDK → PostgreSQL
        → SyncQueue si offline → Replay au retour réseau

Images :
  Camera/Galerie
    → flutter_image_compress (max 500 Ko)
      → Stockage local privé (instantané)
        → Supabase Storage upload async (background)
```

### External Integrations

| Service | Usage | SDK |
|---------|-------|-----|
| Supabase PostgreSQL | BDD cloud + RLS | supabase_flutter 2.12 |
| Supabase Storage | Images recettes | supabase_flutter 2.12 |
| Supabase Auth | Code Foyer (custom) | supabase_flutter 2.12 |

---

## Architecture Validation Results

### Coherence Validation ✅

Toutes les technologies choisies sont compatibles et sans conflit de versions. Les patterns (AsyncValue, Repository, Feature-first) sont alignés avec les best practices Flutter/Riverpod. La structure projet supporte l'ensemble des décisions architecturales.

### Requirements Coverage ✅

**39 FRs couverts — 5 features isolées, mapping complet.**

| Bloc | FRs | Feature | Statut |
|------|-----|---------|--------|
| Recettes | FR1–16 | `features/recipes/` | ✅ |
| Foyer | FR17–22 | `features/household/` | ✅ |
| Planning | FR23–25 | `features/planning/` | ✅ |
| Génération | FR26–37 | `features/generation/` | ✅ |
| Onboarding | FR38–39 | `features/onboarding/` | ✅ |

**11 NFRs couverts architecturalement :**

| NFR | Couverture |
|-----|------------|
| NFR1 — génération < 2s | GenerationService Dart pur, 0 overhead UI |
| NFR2 — navigation < 1s | drift local = lecture instantanée |
| NFR3 — images < 500 Ko | flutter_image_compress dans image_service.dart |
| NFR4 — persistance totale | drift (local) + Supabase (cloud) |
| NFR5 — confirmation suppression | Dialog pattern défini |
| NFR6 — données privées | Supabase RLS par household |
| NFR7 — 3 taps max | Home → Générer en 1 tap |
| NFR8 — zone pouce | Material Design 3, zones 48px natif |
| NFR9 — recette en 60s | RecipeQuickForm saisie progressive |
| NFR10 — offline total | Offline-first + sync queue |
| NFR11 — iOS ≥ 16 / Android ≥ 10 | Flutter 3.41 confirmé |

### Gap Analysis

**Importants (traités lors de l'implémentation) :**
- Supabase RLS policies — à écrire dans les migrations SQL
- pubspec.yaml packages — à finaliser lors de l'init VGC
- drift schema versioning — stratégie de migration locale

**Mineurs :**
- Table `households` Supabase — modèle Code Foyer à préciser lors du sprint auth
- Session token Code Foyer — custom auth à détailler lors du sprint auth

Aucun écart critique ne bloque l'implémentation.

### Architecture Completeness Checklist

**✅ Requirements Analysis**
- [x] Contexte projet analysé (39 FRs, 11 NFRs)
- [x] Complexité évaluée (Faible-Moyenne)
- [x] Contraintes techniques identifiées
- [x] Tensions PRD/UX résolues (cloud adopté)

**✅ Architectural Decisions**
- [x] Framework : Flutter 3.41 / Dart 3.11
- [x] Starter : Very Good CLI 0.28.0
- [x] State Management : Riverpod
- [x] BDD locale : drift (SQLite)
- [x] Cloud : Supabase 2.12 (PostgreSQL + Storage + Auth)
- [x] Auth : Code Foyer 6 chiffres
- [x] Sync : Offline-first + queue locale
- [x] Images : Local permanent + upload async
- [x] Navigation : go_router
- [x] Déploiement : TestFlight + APK + GitHub Actions

**✅ Implementation Patterns**
- [x] Conventions de nommage (Dart / drift / Supabase)
- [x] Structure feature-first + règles de dépendances
- [x] Repository pattern avec interfaces
- [x] AsyncValue pour tout état async
- [x] UUID v4 pour tous les IDs
- [x] Pipeline compression images
- [x] Patterns error handling + loading states

**✅ Project Structure**
- [x] Arborescence complète définie
- [x] 5 features mappées aux 39 FRs
- [x] Frontières architecturales documentées
- [x] Flux de données défini

### Architecture Readiness Assessment

**Statut global : PRÊT POUR L'IMPLÉMENTATION ✅**

**Niveau de confiance : Élevé**

**Points forts :**
- Stack Flutter mature et cohérent
- Offline-first robuste (drift local + sync Supabase)
- Algorithme de génération isolé et testable
- Feature-first = chaque agent IA travaille dans sa feature sans conflit
- Patterns stricts = code consistant entre stories

**Améliorations futures (post-V1) :**
- Monitoring / analytics
- Tests d'intégration Supabase (staging env)
- Stratégie de mise à jour OTA

### Implementation Handoff

**Première commande d'implémentation :**

```bash
dart pub global activate very_good_cli
very_good create flutter_app appli_recette \
  --org com.mikl.recette \
  --platforms android,ios
```

**Ordre d'implémentation recommandé :**
1. Init VGC + drift + Supabase + go_router
2. Schéma BDD (migrations drift + Supabase SQL + RLS)
3. Feature recipes (Bloc A)
4. Feature household (Bloc B)
5. Feature planning (Bloc C)
6. Feature generation — algorithme + UI grille
7. Onboarding 3 étapes
8. Sync offline queue
9. Code Foyer — auth multi-appareils

---

## Architecture Completion Summary

### Workflow Completion

**Architecture Decision Workflow :** TERMINÉ ✅
**Étapes complétées :** 8 / 8
**Date :** 2026-02-18
**Document :** `_bmad-output/planning-artifacts/architecture.md`

### Final Architecture Deliverables

**📋 Document d'Architecture Complet**
- 14 décisions architecturales documentées avec versions spécifiques
- Patterns d'implémentation garantissant la cohérence entre agents IA
- Arborescence projet complète (50+ fichiers définis)
- Mapping 39 FRs → 5 features → fichiers spécifiques
- Validation confirmant cohérence et complétude

**🏗️ Fondation Prête pour l'Implémentation**
- 14 décisions architecturales
- 7 patterns d'implémentation définis
- 5 composants architecturaux (features)
- 39 FRs + 11 NFRs couverts

**📚 Guide pour Agents IA**
- Stack technique avec versions vérifiées
- Règles de cohérence empêchant les conflits d'implémentation
- Structure projet avec frontières claires
- Patterns d'intégration et standards de communication

### Quality Assurance Checklist

**✅ Cohérence Architecturale**
- [x] Toutes les décisions fonctionnent ensemble sans conflit
- [x] Choix technologiques compatibles
- [x] Patterns supportant les décisions architecturales
- [x] Structure alignée avec tous les choix

**✅ Couverture des Exigences**
- [x] Toutes les FRs sont supportées
- [x] Tous les NFRs sont adressés
- [x] Préoccupations transversales gérées
- [x] Points d'intégration définis

**✅ Prêt pour l'Implémentation**
- [x] Décisions spécifiques et actionnables
- [x] Patterns empêchant les conflits entre agents
- [x] Structure complète et non ambiguë
- [x] Exemples fournis pour les patterns clés

---

**Statut Architecture : PRÊT POUR L'IMPLÉMENTATION ✅**

**Phase Suivante :** Créer les Epics & Stories puis implémenter en suivant les décisions et patterns documentés ici.

**Maintenance :** Mettre à jour ce document lors de décisions techniques majeures prises pendant l'implémentation.
