---
project_name: 'appli-recette'
user_name: 'MiKL'
date: '2026-02-18'
status: 'complete'
optimized_for_llm: true
rule_count: 35
sections_completed: ['technology_stack', 'language_rules', 'framework_rules', 'architecture_rules', 'drift_rules', 'supabase_rules', 'image_rules', 'testing_rules', 'anti_patterns']
---

# Project Context for AI Agents — Appli Recette

_Ce fichier contient les règles critiques et les patterns que les agents IA DOIVENT suivre lors de l'implémentation du code de ce projet. Focus sur les détails non évidents que les agents pourraient manquer._

---

## Technology Stack & Versions

| Composant | Technologie | Version |
|-----------|-------------|---------|
| Framework | Flutter | 3.41 |
| Langage | Dart | 3.11 |
| Starter | Very Good CLI | 0.28.0 |
| State Management | Riverpod | AsyncNotifierProvider |
| BDD locale | drift (SQLite ORM) | latest |
| Cloud backend | supabase_flutter | 2.12.0 |
| Navigation | go_router | latest |
| Design System | Material Design 3 | natif Flutter |
| Compression images | flutter_image_compress | latest |
| IDs | uuid | v4 |

---

## Critical Implementation Rules

### Langage Dart — Règles non évidentes

- **Fichiers** : toujours `snake_case.dart` — ex: `recipe_repository.dart`
- **Classes** : PascalCase — ex: `RecipeRepository`, `GenerationService`
- **Variables / fonctions** : camelCase — ex: `currentRecipe`, `generateMenu()`
- **Providers Riverpod** : camelCase + suffixe `Provider` — ex: `recipesProvider`
- **IDs** : TOUJOURS `String` UUID v4 — JAMAIS `int` autoincrement
- **Dates vers Supabase** : `DateTime.now().toUtc().toIso8601String()`
- **Dates depuis drift** : utiliser `DateTimeConverter` intégré — jamais stocker en String brut
- **Null safety** : strict — jamais de `!` forcé sans justification explicite

### Flutter / Riverpod — Règles non évidentes

- **Tout état async** → `AsyncNotifierProvider<Notifier, T>` — jamais `StateNotifierProvider` (déprécié)
- **Affichage état async** → TOUJOURS `asyncValue.when(loading, error, data)` — jamais `asyncValue.value!`
- **Providers** : un provider par concept métier, isolation par feature
- **Pas de logique métier dans les widgets** — les widgets observent, les Notifiers agissent
- **Riverpod `ref.watch`** dans le build, `ref.read` dans les callbacks — jamais l'inverse
- **Material Design 3** : utiliser les composants natifs (Card, FAB, BottomSheet, Chip, Dialog) — pas de custom widgets pour ce qui existe déjà

### Architecture — Règles de frontières strictes

- **Sens de dépendance** : `presentation` → `domain` → `data` — JAMAIS dans l'autre sens
- **Cross-imports entre features** : INTERDIT — si deux features partagent quelque chose → le mettre dans `core/`
- **Accès BDD dans les widgets** : INTERDIT — passer toujours par le Repository via un Provider
- **Accès Supabase dans les widgets** : INTERDIT — idem
- **Algorithme de génération** : code pur Dart dans `features/generation/domain/services/generation_service.dart` — 0 dépendance Flutter/UI

### drift (SQLite) — Règles non évidentes

- **Colonnes** : camelCase dans Dart (`isFavorite`, `createdAt`), snake_case en base (`is_favorite`, `created_at`)
- **Classes de table** : PascalCase + suffixe `Table` — ex: `RecipesTable`
- **Noms de tables** : snake_case pluriel — ex: `recipes`, `meal_ratings`
- **Dates** : utiliser `DateTimeWithTimeZoneConverter` ou équivalent drift — jamais stocker en `int` timestamp nu
- **Migrations** : toujours incrémenter `schemaVersion` et définir `MigrationStrategy`
- **Requêtes complexes** : utiliser les DAOs, pas de requêtes inline dans les repositories

### Supabase — Règles non évidentes

- **Tables** : snake_case pluriel — ex: `recipes`, `household_members`
- **Colonnes** : snake_case — ex: `recipe_id`, `is_favorite`, `created_at`
- **RLS** : TOUJOURS activer Row Level Security sur chaque table — politique par `household_id`
- **IDs Supabase** : UUID v4 (`gen_random_uuid()` en SQL) — aligner avec drift
- **Offline-first** : écrire dans drift EN PREMIER — enqueue dans `sync_queue` — Supabase reçoit en async
- **Jamais bloquer l'UI** sur une réponse Supabase — toutes les opérations réseau sont fire-and-forget ou background

### Images — Pipeline obligatoire

```
Source (caméra ou galerie)
  → flutter_image_compress (cible < 500 Ko, qualité 85)
  → Sauvegarde répertoire privé app (path_provider)
  → Enqueue upload Supabase Storage (background, non bloquant)
```

- **JAMAIS** stocker une image non compressée
- **JAMAIS** sauvegarder dans la galerie du téléphone (répertoire privé uniquement)
- **JAMAIS** bloquer l'UI sur l'upload Supabase — afficher indicateur discret uniquement

### Tests — Règles non évidentes

- **Emplacement** : `test/` en miroir exact de `lib/` — ex: `lib/features/generation/domain/services/generation_service.dart` → `test/features/generation/domain/services/generation_service_test.dart`
- **GenerationService** : tests unitaires complets obligatoires (cœur métier de l'app)
- **Repositories** : tester avec mocks des datasources (mocktail recommandé)
- **Widgets** : Widget tests pour `WeekGrid`, `MealSlotCard`, `MemberRatingRow`
- **Données de test** : seed reproductible pour l'algorithme (même seed → même résultat)

### Anti-Patterns INTERDITS

| ❌ Interdit | ✅ Correct |
|-------------|-----------|
| `int id = autoIncrement` | `String id = const Uuid().v4()` |
| Import cross-features | Passer par `core/` |
| `drift.select()` dans un Widget | Provider → Repository → DAO |
| `asyncValue.value!` | `asyncValue.when(...)` |
| Stocker image > 500 Ko | Compresser avant stockage |
| Écriture Supabase directe (sans drift) | drift d'abord → sync queue |
| `StateNotifierProvider` | `AsyncNotifierProvider` |
| Logique métier dans un Widget | Dans le Notifier ou le Service |

---

## Usage Guidelines

**Pour les agents IA :**
- Lire ce fichier AVANT d'implémenter tout code
- Suivre TOUTES les règles exactement telles que documentées
- En cas de doute, préférer l'option la plus restrictive
- Se référer à `_bmad-output/planning-artifacts/architecture.md` pour les décisions complètes

**Pour MiKL :**
- Garder ce fichier lean — uniquement ce que les agents pourraient rater
- Mettre à jour si le stack technique évolue
- Ajouter de nouvelles règles si un agent fait une erreur répétée

_Dernière mise à jour : 2026-02-18_
