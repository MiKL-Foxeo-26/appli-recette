# CLAUDE.md - Contexte Projet

## Projet

**Nom:** Appli Recette
**Description:** Application mobile Flutter de gestion de recettes et génération intelligente de menus hebdomadaires pour un foyer
**Phase actuelle:** 🚀 Implémentation — Epic 1 à démarrer

---

## Stack Technique

- **Framework :** Flutter 3.41 / Dart 3.11
- **Starter :** Very Good CLI (VGC) — `very_good create flutter_app appli_recette --org com.mikl.recette --platforms android,ios`
- **State management :** Riverpod (AsyncValue pattern)
- **DB locale :** drift (SQLite ORM) — source de vérité locale
- **Cloud :** Supabase PostgreSQL — source de vérité cloud, RLS par foyer
- **Navigation :** go_router + ShellRoute (4 onglets)
- **Design :** Material Design 3 — palette "Chaleur & Appétit" (Primary #E8794A, Background #FDF6EF)
- **Auth :** Code Foyer 6 chiffres (pas d'email/mot de passe)
- **Sync :** Offline-first — SyncQueueProcessor + ConnectivityMonitor
- **Distribution :** TestFlight (iOS) / APK sideload (Android)

### Patterns obligatoires
- UUID v4 pour tous les IDs (jamais d'int autoincrement)
- Structure feature-first : `features/recipes`, `household`, `planning`, `generation`, `onboarding`
- Pattern Repository : interface dans `domain/`, implémentation dans `data/`
- Tests miroir de `lib/` dans `test/`

---

## Methode BMAD

Ce projet utilise la **BMAD Method** (Business-Minded Agile Development).

### Localisation du module BMAD

```
y/_bmad/bmm/
```

> Note : le module BMAD est installe dans le dossier `y/` a la racine du projet.

### Agents disponibles

| Agent | Nom | Role |
|-------|-----|------|
| `analyst` | Mary 📊 | Business Analyst + Requirements Expert |
| `pm` | John 📋 | Product Manager |
| `ux-designer` | Sally 🎨 | UX Designer |
| `architect` | Winston 🏗️ | System Architect |
| `dev` | Amelia 💻 | Senior Implementation Engineer |
| `sm` | Bob 🏃 | Scrum Master |
| `tech-writer` | Paige 📚 | Technical Writer |
| `tea` | Murat 🧪 | Master Test Architect |
| `quick-flow-solo-dev` | Barry 🚀 | Quick Flow Solo Dev |

Les agents sont definis dans : `y/_bmad/bmm/agents/`

### Workflows disponibles

Les workflows BMAD suivent ces phases :

1. **Analyse** (`y/_bmad/bmm/workflows/1-analysis/`)
   - `create-product-brief` - Brief produit
   - `research` - Recherche marche / domaine / technique

2. **Planification** (`y/_bmad/bmm/workflows/2-plan-workflows/`)
   - `prd` - Product Requirements Document
   - `create-ux-design` - Design UX

3. **Solutionnement** (`y/_bmad/bmm/workflows/3-solutioning/`)
   - `create-architecture` - Architecture technique
   - `create-epics-and-stories` - Epics & Stories
   - `check-implementation-readiness` - Verification readiness

4. **Implementation** (`y/_bmad/bmm/workflows/4-implementation/`)
   - `sprint-planning`, `dev-story`, `code-review`, `sprint-status`, etc.

---

## Structure du Projet

```
appli recette/
├── y/
│   └── _bmad/
│       └── bmm/                    # Module BMAD Method
│           ├── agents/             # Definitions des agents
│           ├── workflows/          # Workflows par phase
│           ├── teams/              # Configuration equipe
│           └── data/               # Standards et templates
├── _bmad-output/
│   ├── planning-artifacts/         # Artefacts de planification
│   │   ├── bmm-workflow-status.yaml
│   │   ├── product-brief-appli-recette-2026-02-17.md
│   │   ├── prd.md
│   │   ├── ux-design-specification.md
│   │   ├── architecture.md
│   │   ├── epics.md
│   │   └── implementation-readiness-report-2026-02-19.md
│   └── implementation-artifacts/   # Stories + sprint tracking
│       └── sprint-status.yaml
└── CLAUDE.md                       # Ce fichier
```

---

## Statut BMAD — Toutes les phases planification completes

| Phase | Workflow | Statut | Artefact |
|-------|----------|--------|----------|
| Analyse | product-brief | ✅ Terminé | `product-brief-appli-recette-2026-02-17.md` |
| Planification | prd | ✅ Terminé | `prd.md` |
| Planification | create-ux-design | ✅ Terminé | `ux-design-specification.md` |
| Solutionnement | create-architecture | ✅ Terminé | `architecture.md` |
| Solutionnement | create-epics-and-stories | ✅ Terminé | `epics.md` (7 epics, 22 stories) |
| Solutionnement | check-implementation-readiness | ✅ Terminé | `implementation-readiness-report-2026-02-19.md` |
| Implementation | sprint-planning | ✅ Terminé | `sprint-status.yaml` |

**Prochaine action :** Lancer `dev-story` pour démarrer Story 1.1

---

## Conventions

- **Langue :** Francais pour la documentation et les interfaces
- **Methode :** BMAD Method
- **Suivi sprint :** `_bmad-output/implementation-artifacts/sprint-status.yaml`
