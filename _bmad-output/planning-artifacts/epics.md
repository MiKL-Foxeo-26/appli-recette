---
stepsCompleted: [step-01-validate-prerequisites, step-02-design-epics, step-03-create-stories]
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/planning-artifacts/architecture.md
  - _bmad-output/planning-artifacts/ux-design-specification.md
---

# appli-recette - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for appli-recette, decomposing the requirements from the PRD, UX Design, and Architecture into implementable stories.

## Requirements Inventory

### Functional Requirements

FR1  : L'utilisateur peut créer une fiche recette avec un nom
FR2  : L'utilisateur peut définir les temps d'une recette (préparation, cuisson, repos)
FR3  : Le système calcule automatiquement le temps total d'une recette
FR4  : L'utilisateur peut catégoriser une recette par type de repas (petit-déjeuner, déjeuner, dîner, goûter, dessert)
FR5  : L'utilisateur peut associer une saison à une recette (printemps, été, automne, hiver, toute saison)
FR6  : L'utilisateur peut marquer une recette comme végétarienne
FR7  : L'utilisateur peut définir le nombre de portions d'une recette
FR8  : L'utilisateur peut ajouter des ingrédients structurés à une recette (nom, quantité, unité, rayon supermarché)
FR9  : L'utilisateur peut ajouter des photos à une recette (depuis la caméra ou la galerie)
FR10 : L'utilisateur peut ajouter des notes libres à une recette
FR11 : L'utilisateur peut ajouter des variantes et astuces à une recette
FR12 : L'utilisateur peut renseigner une URL source pour une recette
FR13 : L'utilisateur peut modifier une recette existante
FR14 : L'utilisateur peut supprimer une recette (action confirmée explicitement)
FR15 : L'utilisateur peut marquer une recette en favori ou retirer ce statut
FR16 : L'utilisateur peut accéder à la création de recette depuis n'importe quel écran
FR17 : L'utilisateur peut créer un profil pour chaque membre du foyer (nom, âge)
FR18 : L'utilisateur peut modifier un profil de membre du foyer
FR19 : L'utilisateur peut supprimer un profil de membre du foyer
FR20 : L'utilisateur peut attribuer une notation par recette et par membre (aimé / pas aimé / neutre)
FR21 : L'utilisateur peut modifier la notation d'un membre pour une recette
FR22 : L'utilisateur peut noter les membres immédiatement après la création d'une recette
FR23 : L'utilisateur peut configurer un planning de présence type par membre (jour, repas : midi / soir)
FR24 : L'utilisateur peut modifier ponctuellement les présences d'une semaine donnée sans altérer le planning type
FR25 : L'utilisateur peut sélectionner la semaine à planifier
FR26 : L'utilisateur peut lancer la génération automatique d'un menu pour une semaine en 1 action
FR27 : Le système génère uniquement les repas correspondant aux présences de la semaine
FR28 : Le système priorise les recettes marquées en favori lors de la génération
FR29 : Le système exclut les recettes notées "pas aimé" par un membre présent au repas concerné
FR30 : Le système privilégie les recettes notées "aimé" par les membres présents au repas concerné
FR31 : Le système évite de répéter des recettes figurant dans les menus des semaines précédentes (anti-répétition)
FR32 : L'utilisateur peut appliquer des filtres à la génération (temps de préparation maximum, végétarien, saison)
FR33 : L'utilisateur peut remplacer manuellement un repas généré par une recette de son choix
FR34 : L'utilisateur peut valider le menu généré
FR35 : Le système conserve l'historique des menus générés et validés
FR36 : Le système affiche un message indiquant le nombre de créneaux non remplis quand la génération est incomplète
FR37 : Le système propose des options de résolution en cas de génération incomplète (élargir les filtres, compléter manuellement, laisser créneaux vides)
FR38 : L'application guide l'utilisateur à travers 3 étapes à la première ouverture (foyer → planning → premières recettes)
FR39 : La génération de menu est accessible dès 3 recettes dans la collection

### NonFunctional Requirements

NFR1  : La génération de menu s'exécute en moins de 2 secondes sur un smartphone standard (iOS >= 16 et Android >= 10)
NFR2  : Chaque écran se charge en moins de 1 seconde en navigation normale
NFR3  : Les images de recettes sont compressées à moins de 500 Ko avant stockage
NFR4  : Toutes les données (recettes, profils, planning, notations, historique menus) sont persistées localement sans perte après fermeture
NFR5  : La suppression d'une recette ou d'un profil requiert une confirmation explicite de l'utilisateur avant exécution
NFR6  : Aucune donnée utilisateur n'est transmise à un serveur externe autre que Supabase (du foyer uniquement, avec RLS)
NFR7  : Les 3 actions principales (générer un menu, créer une recette, valider un menu) sont accessibles en 3 taps maximum depuis l'écran d'accueil
NFR8  : Tous les éléments interactifs principaux sont positionnés dans la zone de confort du pouce (bas de l'écran, accessibles à une main)
NFR9  : La création d'une recette minimale (nom + type de repas + temps de préparation) est réalisable en moins de 60 secondes
NFR10 : L'application fonctionne sans connexion internet (toutes fonctionnalités opérationnelles en mode offline)
NFR11 : L'application est compatible iOS >= 16 (iPhone) et Android >= 10 (smartphones)

### Additional Requirements

**Architecture — Starter Template (impact Epic 1 Story 1) :**
- Initialiser le projet via Very Good CLI : `very_good create flutter_app appli_recette --org com.mikl.recette --platforms android,ios`
- Flutter 3.41 / Dart 3.11 / Riverpod / Material Design 3

**Architecture — Infrastructure & Déploiement :**
- drift (SQLite ORM) comme source de vérité locale
- Supabase PostgreSQL comme source de vérité cloud avec RLS par foyer
- Queue de sync locale : opérations offline enfilées et rejouées au retour réseau
- Conflict resolution : Last write wins (timestamp serveur Supabase)
- Distribution : iOS via TestFlight, Android via APK sideload
- CI/CD GitHub Actions (fourni par VGC)
- Build flavors : development / production

**Architecture — Sécurité & Auth :**
- Authentification Code Foyer 6 chiffres (pas d'email, pas de mot de passe)
- Supabase Row Level Security (RLS) : chaque foyer accède uniquement à ses données
- Images : compression < 500 Ko, stockage local privé, upload Supabase Storage async

**Architecture — Patterns obligatoires pour tous les agents :**
- UUID v4 pour tous les IDs (jamais d'int autoincrement)
- Nommage Dart snake_case (fichiers), PascalCase (classes), camelCase (variables/fonctions)
- Structure feature-first (VGC) : features/recipes, household, planning, generation, onboarding
- Pattern Repository avec interface dans domain/ et implementation dans data/
- AsyncValue Riverpod pour tout état async
- Tests miroir de lib/ dans test/

**UX — Composants Custom :**
- WeekGridComponent : grille 7 jours x 2 repas (midi/soir)
- MealSlotCard : case individuelle avec icones verrou/refresh/supprimer en mode post-génération
- MemberRatingRow : ligne notation par membre avec chips aime/neutre/pas-aime
- PresenceToggleGrid : grille présences membres x jours
- SyncStatusBadge : indicateur discret sync cloud
- RecipeQuickForm : formulaire de création progressif (3 sections)

**UX — Design System :**
- Palette "Chaleur & Appétit" : Primary #E8794A, Secondary #F5C26B, Background #FDF6EF
- Typographie : Nunito, tailles 12sp-22sp
- WCAG AA : contraste >= 4.5:1 corps, touch targets >= 48x48px
- Bottom Navigation 4 onglets : Accueil / Recettes / Foyer / Planning
- FAB omniprésent bas-droite pour création recette
- go_router : ShellRoute + 4 tabs

### FR Coverage Map

FR1-FR16 : Epic 2 — Gestion complète des recettes (CRUD, favoris, photos, ingrédients, notes)
FR17-FR22 : Epic 3 — Profils foyer & notations (membres, notation aime/neutre/pas-aime)
FR23-FR25 : Epic 4 — Planning de présence (planning type + overrides ponctuels)
FR26-FR37 : Epic 5 — Génération intelligente de menus (algorithme multi-critères, WeekGrid, historique)
FR38-FR39 : Epic 6 — Onboarding & première expérience (3 étapes, débloquage à 3 recettes)
NFR1-NFR11 : Distribués sur Epics 1-5 via patterns architecture (performance, persistance, accessibilité)

## Epic List

### Epic 1 : Foundation Technique & Shell de Navigation
L'app est installée via Very Good CLI, se lance sur iOS et Android, la navigation de base (4 onglets) est fonctionnelle, le schéma de base de données drift est en place, Supabase est configuré, et le design system Material Design 3 "Chaleur & Appétit" est initialisé.
**FRs couverts :** Aucun FR fonctionnel direct — prérequis technique pour tous les epics suivants
**NFRs adressés :** NFR2 (navigation < 1s), NFR10 (offline-first), NFR11 (iOS/Android)

### Epic 2 : Collection de Recettes
MiKL peut créer, consulter, modifier et gérer sa collection de recettes personnelles avec photos, ingrédients structurés, tags (saison, végétarien, type de repas), favoris, notes et variantes. Le FAB est accessible depuis tous les écrans.
**FRs couverts :** FR1-FR16
**NFRs adressés :** NFR3 (images < 500Ko), NFR4 (persistance), NFR5 (confirmation suppression), NFR9 (recette en 60s)

### Epic 3 : Profils du Foyer & Préférences
MiKL peut créer les profils de chaque membre du foyer et enregistrer leurs préférences par recette (aimé / neutre / pas aimé). La notation est accessible immédiatement après la création d'une recette.
**FRs couverts :** FR17-FR22
**Dépend de :** Epic 2 (les notations sont liées aux recettes)

### Epic 4 : Planning de Présence
MiKL peut configurer un planning de présence type pour chaque membre, puis modifier ponctuellement les présences d'une semaine donnée sans altérer le planning type.
**FRs couverts :** FR23-FR25
**Dépend de :** Epic 3 (le planning est lié aux membres du foyer)

### Epic 5 : Génération Intelligente de Menus
MiKL peut générer un menu hebdomadaire complet en un tap, respectant présences et goûts. L'algorithme priorise favoris, exclut plats détestés, évite la répétition, et guide en cas de génération incomplète.
**FRs couverts :** FR26-FR37
**NFRs adressés :** NFR1 (génération < 2s), NFR7 (3 taps max)
**Dépend de :** Epics 2, 3, 4

### Epic 6 : Onboarding & Première Expérience
MiKL est guidé lors de la première ouverture à travers 3 étapes (foyer -> planning -> recettes). La génération se débloque dès 3 recettes. Option de rejoindre un foyer existant via Code Foyer.
**FRs couverts :** FR38-FR39
**Dépend de :** Epics 2, 3, 4, 5

### Epic 7 : Synchronisation Cloud & Code Foyer
MiKL peut synchroniser ses données entre appareils et partager l'accès avec son partenaire via un Code Foyer à 6 chiffres. Offline-first avec queue de sync automatique au retour du réseau.
**FRs couverts :** NFR6 (RLS Supabase), NFR10 (offline + sync queue)
**Dépend de :** Epic 1 (infrastructure Supabase)

---

## Epic 1 : Foundation Technique & Shell de Navigation

L'app est installée via Very Good CLI, se lance sur iOS et Android, la navigation de base (4 onglets) est fonctionnelle, le schéma drift est en place, Supabase est configuré, et le design system Material Design 3 "Chaleur & Appétit" est initialisé.

### Story 1.1 : Initialisation du Projet Flutter via Very Good CLI

En tant que développeur,
Je veux initialiser le projet Flutter avec Very Good CLI,
Afin d'avoir une fondation de code propre, testée et prête pour les build flavors iOS et Android.

**Acceptance Criteria :**

**Given** un environnement de développement avec Flutter 3.41, Dart 3.11 et VGC installés
**When** j'exécute `very_good create flutter_app appli_recette --org com.mikl.recette --platforms android,ios`
**Then** le projet est créé avec la structure feature-first, les build flavors (development/production), linting VGC, et les pipelines GitHub Actions
**And** `flutter run` lance l'app sur simulateur iOS et émulateur Android sans erreur
**And** la structure de dossiers `lib/features/`, `lib/core/`, `test/` est en place

---

### Story 1.2 : Configuration du Design System Material Design 3

En tant qu'utilisateur,
Je veux que l'app ait un design visuel cohérent "Chaleur & Appétit",
Afin que chaque écran respecte la charte graphique dès le départ.

**Acceptance Criteria :**

**Given** le projet VGC initialisé
**When** l'app se lance
**Then** la palette de couleurs (Primary #E8794A, Secondary #F5C26B, Background #FDF6EF, Success #6BAE75, Error #C0392B) est appliquée via MaterialTheme dans `app_theme.dart`
**And** la police Nunito est chargée et utilisée pour tous les textes (Title Large 22sp, Body Large 16sp, Label 12sp)
**And** les tokens Material Design 3 (espacement 8px, zones de tap >= 48x48px) sont configurés
**And** `app_colors.dart` et `app_typography.dart` sont créés dans `lib/core/theme/`

---

### Story 1.3 : Navigation Shell avec 4 Onglets

En tant qu'utilisateur,
Je veux naviguer entre les 4 sections principales de l'app via une barre de navigation basse,
Afin d'accéder rapidement à Accueil, Recettes, Foyer et Planning depuis n'importe quel écran.

**Acceptance Criteria :**

**Given** l'app est lancée
**When** je tape sur un des 4 onglets (Accueil / Recettes / Foyer / Planning)
**Then** l'écran correspondant s'affiche en moins de 1 seconde (NFR2)
**And** la bottom navigation reste visible sur tous les écrans principaux via ShellRoute go_router
**And** le FAB "+" est visible bas-droite (couleur #E8794A) depuis tous les écrans avec un écran placeholder "Nouvelle recette"
**And** le chevron back apparaît en haut à gauche sur tous les sous-écrans

---

### Story 1.4 : Schéma de Base de Données drift (SQLite local)

En tant que développeur,
Je veux que le schéma de base de données local soit défini et migré,
Afin que toutes les features suivantes puissent persister leurs données dès leur implémentation.

**Acceptance Criteria :**

**Given** drift est ajouté aux dépendances pubspec.yaml
**When** l'app se lance
**Then** les 8 tables drift sont créées : recipes, ingredients, members, meal_ratings, presence_schedules, weekly_menus, menu_slots, sync_queue
**And** toutes les clés primaires sont de type String (UUID v4, jamais d'int autoincrement)
**And** `app_database.dart` est dans `lib/core/database/` avec les DAOs de base pour chaque table
**And** les migrations s'exécutent sans erreur sur iOS et Android au premier lancement

---

### Story 1.5 : Configuration Supabase & Variables d'Environnement

En tant que développeur,
Je veux que Supabase soit configuré pour les environnements dev et prod,
Afin que la synchronisation cloud soit prête à être activée par les features suivantes.

**Acceptance Criteria :**

**Given** les projets Supabase dev et prod créés sur supabase.com
**When** l'app se lance en flavor development
**Then** Supabase.initialize() est appelé dans main_development.dart avec les clés du projet dev (supabase_flutter 2.12)
**And** les fichiers .env.development et .env.production contiennent les clés et sont dans .gitignore
**And** les 8 migrations SQL Supabase (001_households.sql à 008_menu_slots.sql) sont appliquées avec RLS activé
**And** un test de connexion basique s'exécute sans erreur en flavor development

---

## Epic 2 : Collection de Recettes

MiKL peut créer, consulter, modifier et gérer sa collection de recettes personnelles avec photos, ingrédients structurés, tags (saison, végétarien, type de repas), favoris, notes et variantes. Le FAB est accessible depuis tous les écrans.

### Story 2.1 : Créer une Fiche Recette Basique

En tant qu'utilisateur,
Je veux créer une fiche recette avec les informations essentielles (nom, type de repas, temps),
Afin d'ajouter rapidement une recette à ma collection en moins de 60 secondes.

**Acceptance Criteria :**

**Given** je tape sur le FAB "+" depuis n'importe quel écran
**When** je remplis le nom de la recette, le type de repas et le temps de préparation
**Then** la recette est créée et persistée localement via drift avec un UUID v4 comme identifiant (FR1)
**And** le temps total est calculé automatiquement (préparation + cuisson + repos) (FR3)
**And** la recette apparaît dans la liste des recettes
**And** la création minimale (nom + type + temps) est réalisable en moins de 60 secondes (NFR9)
**And** le formulaire RecipeQuickForm progressif affiche la section 1 obligatoire (nom + type) en premier (FR4)

---

### Story 2.2 : Enrichir une Recette (Saison, Végé, Portions, Ingrédients)

En tant qu'utilisateur,
Je veux enrichir une recette existante avec la saison, le tag végétarien, les portions et les ingrédients structurés,
Afin que l'algorithme de génération puisse filtrer et utiliser ces informations.

**Acceptance Criteria :**

**Given** une recette existante dans ma collection
**When** j'ouvre sa fiche et j'ajoute des informations complémentaires
**Then** je peux associer une saison (printemps, été, automne, hiver, toute saison) (FR5)
**And** je peux cocher "végétarien" via un Switch/Toggle (FR6)
**And** je peux définir le nombre de portions avec un champ numérique (FR7)
**And** je peux ajouter des ingrédients structurés (nom, quantité, unité, rayon supermarché) (FR8)
**And** chaque modification est persistée immédiatement dans drift sans perte (NFR4)

---

### Story 2.3 : Ajouter une Photo à une Recette

En tant qu'utilisateur,
Je veux ajouter une photo à une recette depuis ma caméra ou ma galerie,
Afin de reconnaître visuellement mes recettes dans la liste.

**Acceptance Criteria :**

**Given** je suis sur la fiche d'une recette
**When** je tape sur l'icône photo et choisis Caméra ou Galerie
**Then** la permission caméra ou galerie est demandée si non accordée
**And** la photo est compressée automatiquement à moins de 500 Ko avant stockage (NFR3) via flutter_image_compress
**And** l'image est stockée dans le répertoire privé de l'application (jamais dans la galerie système)
**And** la photo est affichée en haut de la fiche recette (FR9)
**And** un indicateur discret signale l'upload asynchrone vers Supabase Storage en arrière-plan

---

### Story 2.4 : Ajouter Notes, Variantes et URL Source

En tant qu'utilisateur,
Je veux ajouter des notes libres, des variantes/astuces et une URL source à une recette,
Afin de conserver le contexte et les adaptations personnelles.

**Acceptance Criteria :**

**Given** je suis sur la fiche d'une recette en mode édition
**When** je remplis les champs optionnels
**Then** je peux saisir des notes libres en texte multiligne (FR10)
**And** je peux saisir des variantes et astuces en texte multiligne (FR11)
**And** je peux renseigner une URL source (FR12)
**And** toutes ces informations sont sauvegardées et affichées sur la fiche recette
**And** les champs sont labellisés et accessibles (WCAG AA)

---

### Story 2.5 : Modifier et Supprimer une Recette

En tant qu'utilisateur,
Je veux modifier une recette existante et la supprimer si nécessaire,
Afin de garder ma collection à jour et épurée.

**Acceptance Criteria :**

**Given** une recette existante dans ma collection
**When** je tape sur Modifier depuis la fiche recette
**Then** tous les champs sont éditables et sauvegardés à la validation (FR13)
**And** les modifications sont persistées dans drift sans perte (NFR4)

**Given** je veux supprimer une recette
**When** je tape sur Supprimer
**Then** un Dialog de confirmation Material 3 s'affiche avec les boutons Annuler / Supprimer (rouge) (NFR5, FR14)
**And** la recette n'est supprimée qu'après confirmation explicite
**And** les notations des membres liées à cette recette sont également supprimées

---

### Story 2.6 : Gérer les Favoris & Consulter la Liste des Recettes

En tant qu'utilisateur,
Je veux marquer mes recettes en favori et consulter ma collection facilement,
Afin que l'algorithme priorise mes favoris lors de la génération.

**Acceptance Criteria :**

**Given** je suis sur la fiche d'une recette ou dans la liste
**When** je tape sur l'icône favori
**Then** la recette est marquée en favori et le statut est persisté dans drift (FR15)
**And** un second tap retire le statut favori
**And** les recettes favorites sont visuellement distinguées dans la liste

**Given** je suis sur l'écran Recettes
**When** l'écran se charge
**Then** toutes mes recettes sont affichées sous forme de RecipeCard (image + nom + type + temps total)
**And** un champ de recherche permet de filtrer par nom
**And** le FAB "+" reste visible et fonctionnel (FR16)
**And** l'état vide affiche "Commence par ajouter une recette" avec un bouton Ajouter

---

## Epic 3 : Profils du Foyer & Préférences

MiKL peut créer les profils de chaque membre du foyer et enregistrer leurs préférences par recette (aimé / neutre / pas aimé). La notation est accessible immédiatement après la création d'une recette.

### Story 3.1 : Créer et Gérer les Profils Membres du Foyer

En tant qu'utilisateur,
Je veux créer un profil pour chaque membre de mon foyer,
Afin que l'algorithme puisse tenir compte de chaque personne lors de la génération.

**Acceptance Criteria :**

**Given** je suis sur l'écran Foyer
**When** je tape sur Ajouter un membre
**Then** je peux saisir le nom et l'âge du membre et l'enregistrer (FR17)
**And** le membre apparaît dans la liste du foyer

**Given** un membre existant dans le foyer
**When** je tape sur Modifier
**Then** je peux changer le nom et l'âge et sauvegarder (FR18)

**Given** je veux supprimer un membre
**When** je tape sur Supprimer
**Then** un Dialog de confirmation s'affiche avant suppression définitive (NFR5, FR19)
**And** toutes les notations et présences liées à ce membre sont également supprimées
**And** l'état vide affiche "Ajoute les membres de ton foyer"

---

### Story 3.2 : Noter les Préférences d'un Membre par Recette

En tant qu'utilisateur,
Je veux enregistrer les préférences de chaque membre pour chaque recette,
Afin que l'algorithme de génération respecte les goûts de chacun.

**Acceptance Criteria :**

**Given** je suis sur la fiche d'une recette avec des membres dans mon foyer
**When** je consulte la section Préférences du foyer
**Then** chaque membre est affiché avec des chips de notation via MemberRatingRow : Aimé / Neutre / Pas aimé (FR20)
**And** taper sur un chip sélectionne cette notation de façon exclusive pour ce membre
**And** la notation est persistée dans drift (meal_ratings) (NFR4)

**Given** une notation existante pour un membre
**When** je tape sur un chip différent
**Then** la notation est mise à jour immédiatement (FR21)
**And** les couleurs des chips respectent la palette : Aimé #FFE0CC, Neutre #F0F0F0, Pas aimé #E8EAF6

---

### Story 3.3 : Notation Immédiate Après Création d'une Recette

En tant qu'utilisateur,
Je veux pouvoir noter les membres immédiatement après avoir créé une recette,
Afin de capturer les préférences pendant que le souvenir est frais.

**Acceptance Criteria :**

**Given** je viens de créer et sauvegarder une nouvelle recette
**When** la sauvegarde est confirmée
**Then** un écran ou bottom sheet de notation s'affiche automatiquement avec tous les membres du foyer (FR22)
**And** je peux noter chaque membre (Aimé / Neutre / Pas aimé) via les chips MemberRatingRow
**And** un bouton Passer permet de sauter cette étape sans noter
**And** les notations saisies sont persistées dans drift

---

## Epic 4 : Planning de Présence

MiKL peut configurer un planning de présence type pour chaque membre, puis modifier ponctuellement les présences semaine par semaine sans altérer le planning type.

### Story 4.1 : Configurer le Planning de Présence Type

En tant qu'utilisateur,
Je veux définir un planning de présence type pour chaque membre de mon foyer,
Afin que l'app sache automatiquement qui est présent à chaque repas par défaut.

**Acceptance Criteria :**

**Given** je suis sur l'écran Planning
**When** je configure le planning type
**Then** une grille PresenceToggleGrid affiche les membres en lignes et les jours/repas en colonnes (7 jours x midi/soir)
**And** je peux activer/désactiver la présence de chaque membre pour chaque créneau via un toggle (FR23)
**And** le planning type est persisté dans drift (presence_schedules) (NFR4)
**And** l'état vide affiche une invitation à configurer les présences

---

### Story 4.2 : Modifier les Présences d'une Semaine Spécifique

En tant qu'utilisateur,
Je veux modifier ponctuellement les présences d'une semaine donnée,
Afin de refléter les exceptions sans changer le planning type.

**Acceptance Criteria :**

**Given** je suis sur l'écran Accueil ou Planning avec une semaine sélectionnée
**When** je modifie les présences pour cette semaine
**Then** les overrides ponctuels sont enregistrés séparément du planning type (FR24)
**And** le planning type n'est pas modifié par ces overrides
**And** je peux sélectionner la semaine à planifier via un sélecteur de semaine (FR25)
**And** les overrides sont persistés dans drift associés à la semaine spécifique (NFR4)
**And** une indication visuelle distingue les overrides du planning type

---

## Epic 5 : Génération Intelligente de Menus

MiKL peut générer un menu hebdomadaire complet en un tap, respectant présences et goûts. L'algorithme priorise favoris, exclut les plats détestés, évite la répétition, et guide en cas de génération incomplète.

### Story 5.1 : Service de Génération — Algorithme Multi-Critères

En tant qu'utilisateur,
Je veux que l'algorithme de génération produise un menu pertinent respectant les présences et préférences,
Afin de pouvoir valider le menu sans le modifier manuellement à chaque fois.

**Acceptance Criteria :**

**Given** des recettes dans ma collection, des membres avec notations, et un planning de présence configuré
**When** la génération est lancée pour une semaine
**Then** le GenerationService (classe pure Dart dans features/generation/domain/services/) applique ces couches séquentielles :
  1. Filtrer les recettes selon le type de repas et les présences du créneau (FR27)
  2. Exclure les recettes notées pas-aimé par au moins un membre présent (FR29)
  3. Prioriser les recettes favorites (FR28)
  4. Prioriser les recettes aimées par les membres présents (FR30)
  5. Anti-répétition : écarter les recettes des menus validés précédents (FR31)
  6. Compléter aléatoirement si besoin (seed reproductible)
**And** l'exécution complète prend moins de 2 secondes sur device standard (NFR1)
**And** des tests unitaires couvrent chaque couche dans test/features/generation/domain/services/generation_service_test.dart

---

### Story 5.2 : Grille Semaine & Affichage du Menu Généré

En tant qu'utilisateur,
Je veux voir le menu généré sous forme de grille semaine sur l'écran d'accueil,
Afin de visualiser d'un coup d'oeil toute la semaine planifiée.

**Acceptance Criteria :**

**Given** l'écran Accueil est ouvert sans menu généré pour la semaine courante
**When** l'écran se charge
**Then** la WeekGridComponent affiche 7 colonnes (lundi-dimanche) x 2 lignes (midi/soir) avec des créneaux vides
**And** le bouton Générer est visible dans la top bar
**And** l'état vide affiche "Tape Générer pour planifier ta semaine"

**Given** le menu vient d'être généré
**When** la génération est terminée
**Then** chaque MealSlotCard affiche le nom de la recette et les badges contextuels (Favori, Végé, Saison)
**And** les icônes verrou/refresh/supprimer apparaissent sur chaque case en mode post-génération
**And** l'animation Progress indicator centré est visible pendant le calcul (FR26)

---

### Story 5.3 : Filtres de Génération

En tant qu'utilisateur,
Je veux appliquer des filtres avant de lancer la génération,
Afin d'adapter le menu à des contraintes ponctuelles.

**Acceptance Criteria :**

**Given** je suis sur l'écran Accueil avant de lancer la génération
**When** je tape sur l'icône filtres
**Then** une GenerationFiltersSheet (bottom sheet) s'affiche avec : temps de préparation maximum (slider), filtre végétarien (toggle), filtre saison (chips) (FR32)
**And** les filtres sélectionnés sont appliqués à la prochaine génération
**And** une indication visuelle montre que des filtres actifs sont en place
**And** un bouton Réinitialiser efface tous les filtres actifs

---

### Story 5.4 : Remplacement Manuel & Verrouillage de Créneaux

En tant qu'utilisateur,
Je veux remplacer manuellement un repas généré et verrouiller les créneaux qui me conviennent,
Afin d'ajuster le menu sans tout régénérer.

**Acceptance Criteria :**

**Given** un menu généré affiché dans la WeekGridComponent
**When** je tape sur un créneau rempli
**Then** une bottom sheet s'affiche avec : Voir la recette, Remplacer, Passer en événement spécial, Supprimer (FR33)
**And** Remplacer ouvre un picker de recettes filtrable par nom

**Given** je veux garder un repas lors d'une regénération
**When** je tape sur l'icône verrou sur une case
**Then** la case est verrouillée (visuellement distincte) et ignorée lors d'une regénération partielle
**And** tap long sur une case remplie = verrouillage rapide
**And** le bouton Regénérer la sélection apparaît dès qu'au moins une case est déverrouillée

---

### Story 5.5 : Validation du Menu & Historique

En tant qu'utilisateur,
Je veux valider le menu de la semaine d'un tap et conserver l'historique,
Afin que l'algorithme évite les répétitions les semaines suivantes.

**Acceptance Criteria :**

**Given** un menu généré et ajusté sur la grille
**When** je tape sur Valider le menu
**Then** le menu est sauvegardé dans drift (weekly_menus + menu_slots) avec la date de la semaine (FR34)
**And** un Snackbar vert (#6BAE75) confirme "Menu sauvegardé" (3 sec auto-dismiss)
**And** le menu validé est ajouté à l'historique (FR35)
**And** l'historique est utilisé par le GenerationService pour l'anti-répétition (FR31)
**And** les données sont persistées dans drift sans perte (NFR4)

---

### Story 5.6 : Gestion de la Génération Incomplète

En tant qu'utilisateur,
Je veux être guidé lorsque l'algorithme ne peut pas remplir tous les créneaux,
Afin de trouver une solution sans bloquer ma planification.

**Acceptance Criteria :**

**Given** la génération est lancée avec trop peu de recettes compatibles
**When** l'algorithme ne peut pas remplir tous les créneaux
**Then** une Card warning (#FFF3E0) s'affiche indiquant le nombre exact de créneaux non remplis (FR36)
**And** trois options sont proposées : Élargir les filtres, Compléter manuellement, Laisser les créneaux vides (FR37)
**And** la génération partielle est acceptable : les créneaux remplis sont affichés normalement
**And** le message est humain et guidant, jamais une erreur froide
**And** choisir Élargir les filtres rouvre la GenerationFiltersSheet

---

## Epic 6 : Onboarding & Première Expérience

MiKL est guidé lors de la première ouverture à travers 3 étapes (foyer -> planning -> recettes). La génération se débloque dès 3 recettes. Option de rejoindre un foyer existant via Code Foyer.

### Story 6.1 : Flow Onboarding 3 Étapes

En tant que nouvel utilisateur,
Je veux être guidé à travers 3 étapes claires lors de la première ouverture,
Afin de configurer mon foyer, mon planning et mes premières recettes rapidement.

**Acceptance Criteria :**

**Given** c'est la première ouverture de l'app (aucun foyer configuré)
**When** l'app se lance
**Then** l'écran OnboardingScreen s'affiche avec indicateur de progression (3 étapes) (FR38)
**And** Étape 1/3 : créer les profils membres (nom + âge), au minimum 1 membre requis
**And** Étape 2/3 : configurer le planning type avec la PresenceToggleGrid
**And** Étape 3/3 : ajouter les premières recettes avec compteur "X/3 recettes"
**And** chaque étape peut être complétée et passée via Suivant
**And** l'onboarding est ignoré aux ouvertures suivantes (flag onboarding_complete dans drift)

---

### Story 6.2 : Débloquage de la Génération & Option Rejoindre un Foyer

En tant qu'utilisateur,
Je veux que la génération se débloque automatiquement dès 3 recettes dans ma collection,
Afin de pouvoir générer mon premier menu dès que j'ai un minimum viable de recettes.

**Acceptance Criteria :**

**Given** j'ai moins de 3 recettes dans ma collection
**When** je suis sur l'écran Accueil
**Then** le bouton Générer est désactivé avec un message "Ajoute encore X recette(s) pour générer" (FR39)
**And** un compteur dynamique indique la progression vers 3 recettes

**Given** j'atteins 3 recettes dans ma collection
**When** la 3e recette est sauvegardée
**Then** le bouton Générer devient actif avec une invitation à générer le premier menu (FR39)

---

## Epic 7 : Synchronisation Cloud & Code Foyer

MiKL peut synchroniser ses données entre appareils et partager l'accès avec son partenaire via un Code Foyer à 6 chiffres. Offline-first avec queue de sync automatique au retour du réseau.

### Story 7.1 : Queue de Synchronisation Offline-First

En tant qu'utilisateur,
Je veux que toutes mes actions soient sauvegardées localement même sans connexion,
Afin que l'app soit 100% fonctionnelle offline et se synchronise automatiquement quand le réseau revient.

**Acceptance Criteria :**

**Given** l'app est utilisée sans connexion internet
**When** je crée, modifie ou supprime une recette, un membre, une notation ou un planning
**Then** l'opération est écrite dans drift ET dans la sync_queue ({id, operation, entity, payload, createdAt})
**And** l'interface répond instantanément sans attendre le réseau (NFR10)
**And** le SyncStatusBadge affiche l'état hors-ligne dans la top bar

**Given** le réseau revient
**When** la connectivité est détectée par ConnectivityMonitor
**Then** le SyncQueueProcessor rejoue automatiquement les opérations en attente vers Supabase
**And** le SyncStatusBadge affiche l'état sync en cours puis synchronisé une fois terminé
**And** les conflits sont résolus par Last write wins (timestamp serveur Supabase)

---

### Story 7.2 : Authentification Code Foyer & Création du Foyer

En tant qu'utilisateur,
Je veux créer un foyer avec un Code à 6 chiffres ou rejoindre un foyer existant,
Afin de partager l'accès à mes recettes et menus avec mon partenaire depuis son appareil.

**Acceptance Criteria :**

**Given** je suis à l'étape d'onboarding ou dans les paramètres
**When** je crée un nouveau foyer
**Then** un Code Foyer unique à 6 chiffres est généré et affiché (aucun email, aucun mot de passe)
**And** ce code est stocké dans Supabase et associé aux données du foyer via RLS

**Given** mon partenaire ouvre l'app sur son appareil
**When** il saisit le Code Foyer à 6 chiffres
**Then** une connexion Supabase est établie avec les droits lecture + écriture complets sur les données du foyer
**And** les données existantes sont synchronisées immédiatement
**And** les droits sont identiques pour tous les adultes (pas de hiérarchie de rôles en V1)

**Given** c'est la première ouverture de l'app sur un nouvel appareil et un foyer existe déjà
**When** l'utilisateur choisit "Rejoindre un foyer existant" (accessible depuis l'onboarding ou les paramètres)
**Then** un champ de saisie du Code Foyer à 6 chiffres s'affiche
**And** après validation du code, la connexion Supabase est établie et les données du foyer sont synchronisées
**And** l'onboarding est marqué complet et l'app affiche l'écran d'accueil avec les données du foyer

---

### Story 7.3 : Isolation des Données par Foyer (RLS Supabase)

En tant qu'utilisateur,
Je veux que les données de mon foyer soient strictement privées et isolées des autres foyers,
Afin de garantir que personne d'autre ne puisse accéder à mes recettes ou menus.

**Acceptance Criteria :**

**Given** plusieurs foyers existent dans Supabase
**When** un appareil authentifié fait une requête Supabase
**Then** la Row Level Security (RLS) garantit que seules les données du foyer authentifié sont retournées (NFR6)
**And** toute tentative d'accès aux données d'un autre foyer retourne 0 résultats
**And** les politiques RLS sont définies sur toutes les tables : recipes, ingredients, members, meal_ratings, presence_schedules, weekly_menus, menu_slots
**And** aucune donnée n'est transmise à des tiers autres que Supabase du foyer concerné
