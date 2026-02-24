---
stepsCompleted: [step-01-init, step-02-discovery, step-03-success, step-04-journeys, step-05-domain-skipped, step-06-innovation-skipped, step-07-project-type, step-08-scoping, step-09-functional, step-10-nonfunctional, step-11-polish, step-12-complete]
inputDocuments:
  - _bmad-output/planning-artifacts/product-brief-appli-recette-2026-02-17.md
workflowType: 'prd'
classification:
  projectType: mobile_app
  domain: personal_productivity
  complexity: low
  projectContext: greenfield
  offline: false
  pushNotifications: false
  distribution: none
---

# Product Requirements Document - Appli Recette

**Auteur :** MiKL
**Date :** 2026-02-17

---

## Executive Summary

Appli Recette est une application mobile personnelle de planification de menus familiaux. Elle élimine la surcharge mentale hebdomadaire du "qu'est-ce qu'on mange ?" en combinant une collection de recettes personnelles enrichissable et une génération intelligente de menus, adaptée au planning de présence réel du foyer et aux préférences individuelles de chaque membre.

**Différentiateurs clés :**
- **Mémoire familiale** : les préférences (aimé / pas aimé / neutre) de chaque membre informent chaque génération
- **Planning intelligent** : génère exactement les repas nécessaires selon qui est présent, quel repas
- **Zéro tracking calorique** : diversité alimentaire réelle, pas de comptage contraignant
- **Usage 100% personnel** : données locales, aucune authentification, aucun compte requis

**Utilisateur :** MiKL — parent organisateur, foyer de 4 personnes (adultes + Leonard 11 ans, Alizée 9 ans).

**Phases de développement :**
- **V1 (MVP)** : Blocs A (recettes) + B (foyer) + C (planning & génération)
- **V2** : Bloc D (liste de courses) + Bloc E (bibliothèque publique)

---

## Success Criteria

### Succès Utilisateur

- Le menu de la semaine est généré en moins de 2 minutes
- Chaque repas tient compte des présences réelles (qui est là, quel repas)
- Les recettes favorites et préférences de chaque membre sont prises en compte à chaque génération
- La collection s'enrichit facilement (création de fiche rapide et intuitive sur mobile)
- Après quelques semaines, les générations reflètent fidèlement les goûts du foyer

### Succès Produit

Usage personnel — succès = l'app est utilisée chaque dimanche et remplace la planification mentale des repas.

### Succès Technique

- Persistance fiable des données (recettes, profils, planning) entre sessions
- Génération de menu en moins de 2 secondes
- Interface utilisable d'une main, depuis le canapé

### Jalons Mesurables

| Période | Jalon |
|---|---|
| Semaine 1 | Onboarding complet (profils + 5 recettes min + planning type) |
| Semaines 2–4 | Premier menu généré et validé |
| Mois 2+ | Utilisation hebdomadaire régulière, collection croissante, qualité des suggestions en hausse |

---

## Product Scope

### V1 — MVP (Blocs A + B + C)

- **Bloc A** : Fiches recettes personnelles structurées + favoris
- **Bloc B** : Profils du foyer + notation par membre (aimé / pas aimé / neutre)
- **Bloc C** : Planning de présence + génération de menu + ajustement manuel + filtres

**Couvre les parcours :** P1 (onboarding), P2 (usage hebdomadaire), P3 (enrichissement), P4 (génération partielle)

### V2 — Growth (Blocs D + E)

- **Bloc D** : Liste de courses depuis menu validé ou recette individuelle, triée par rayon
- **Bloc E** : Bibliothèque publique gratuite, filtrable, importable, modifiable, découverte à la demande

### Vision

V2 = horizon final. Aucune V3 planifiée.

### Stratégie MVP

App personnelle, sans deadline commerciale. Priorité : fonctionnel et fiable. L'app est réussie dès que MiKL l'utilise chaque dimanche sans planifier dans sa tête.

### Risques

| Risque | Mitigation |
|---|---|
| Algorithme de génération (cœur de l'app) | Commencer simple (priorité favoris + filtre basique), affiner itérativement |
| Dérive des délais | App personnelle — V2 peut attendre sans impact |

---

## User Journeys

### P1 — Onboarding : Premier dimanche avec l'app

**Contexte :** MiKL installe l'app. Rien n'est configuré. Sa semaine commence demain.

**Actions :**
1. Crée les profils : lui, son partenaire, Leonard (11 ans), Alizée (9 ans)
2. Configure le planning type : lundi soir ✓, mercredi midi ✓, week-end complet ✓
3. Crée 5 fiches recettes (spaghetti bolognaise, gratin dauphinois, poulet rôti...)
4. Marque 3 recettes en favori
5. Lance la première génération → menu complet proposé
6. Ajuste mardi soir manuellement, valide

**Résultat :** En 15 minutes, sa semaine est planifiée. Première fois depuis des années qu'il n'y pense plus.

**Exigences révélées :** Onboarding guidé 3 étapes · Création rapide de recette · Génération dès 3 recettes · Ajustement manuel post-génération

---

### P2 — Usage hebdomadaire : Le dimanche en 2 minutes

**Contexte :** 3 mois plus tard. 30 recettes dans la collection, toutes notées par membre.

**Actions :**
1. Ouvre l'app — proposition de générer le menu de la semaine suivante
2. Décoche les présences (mercredi : enfants chez la grand-mère)
3. Lance la génération
4. Résultat : favoris priorisés, aucune recette détestée par les présents, recette préférée de Leonard jeudi soir
5. Valide sans modification — 2 minutes, cerveau libre

**Exigences révélées :** Override ponctuel du planning · Algorithme : favoris + exclusion détestés + inclusion aimés + anti-répétition · Validation en 1 tap

---

### P3 — Enrichissement : Ajouter une recette après un bon repas

**Contexte :** Vendredi soir, curry de pois chiches improvisé — tout le monde a adoré sauf Alizée (trop épicé).

**Actions :**
1. Ouvre l'app → nouvelle recette
2. Saisit : nom, 15 min prépa / 20 min cuisson, végétarien, saison automne-hiver
3. Ajoute ingrédients, prend une photo du plat
4. Note dans variantes : "moins de piment pour Alizée"
5. Enregistre et note : lui ✓ / partenaire ✓ / Leonard ✓ / Alizée ✗
6. Met en favori

**Résultat :** Recette dans la collection, préférences mémorisées. Prochaine génération exclura cette recette pour les repas où Alizée est présente.

**Exigences révélées :** Accès global à la création de recette · Notation immédiate après création · Photo caméra ou galerie · Champ variantes libre

---

### P4 — Cas limite : Pas assez de recettes

**Contexte :** Première semaine. 2 recettes. Filtres stricts : végétarien + prépa ≤ 20 min + saison été.

**Actions :**
1. Lance la génération → l'app indique le nombre de créneaux non remplissables
2. Propose : élargir les filtres / compléter manuellement / laisser créneaux vides
3. MiKL retire le filtre "été" → génération partielle : 4 créneaux sur 7 remplis
4. Complète les 3 restants manuellement

**Résultat :** L'app ne plante pas. Elle guide vers une solution.

**Exigences révélées :** Message explicite avec nb créneaux non remplis · Options de résolution · Génération partielle acceptable · Seuil minimum détecté automatiquement

---

### Tableau de Traçabilité Parcours → Exigences

| Capacité | Parcours | FRs associés |
|---|---|---|
| Onboarding guidé 3 étapes | P1 | FR38 |
| Génération dès 3 recettes | P1 | FR39 |
| Override ponctuel du planning | P2 | FR24 |
| Algorithme : favoris + préférences + anti-répétition | P2 | FR28, FR29, FR30, FR31 |
| Historique des menus | P2 | FR35 |
| Accès global création recette | P3 | FR16 |
| Notation immédiate après création | P3 | FR22 |
| Génération partielle + messages guidants | P4 | FR36, FR37 |
| Options de résolution en cas d'échec | P4 | FR37 |

---

## Mobile App Requirements

### Plateforme

- **iOS** : iPhone (iOS ≥ 16), pas de support iPad requis
- **Android** : smartphones (Android ≥ 10)
- **Framework** : cross-platform React Native ou Flutter (décision architecte)
- **Distribution** : hors stores — TestFlight (iOS) / APK sideload (Android)

### Permissions Requises

| Permission | Usage |
|---|---|
| Caméra | Photo du plat depuis la fiche recette |
| Galerie / Photos | Import de photos existantes |
| Stockage local | Persistance des données entre sessions |

### Contraintes Architecturales

- Données stockées **localement sur l'appareil** (pas de backend cloud pour la V1)
- **Aucune authentification** requise (app mono-utilisateur)
- **Aucune synchronisation** entre appareils (V1)
- **Offline-first de fait** : toutes les fonctionnalités opèrent sans connexion internet
- **Aucune notification push** requise
- Images compressées avant stockage (< 500 Ko par photo)
- Base de données locale légère (SQLite ou équivalent)

---

## Functional Requirements

### Gestion des Recettes

- FR1  : L'utilisateur peut créer une fiche recette avec un nom
- FR2  : L'utilisateur peut définir les temps d'une recette (préparation, cuisson, repos)
- FR3  : Le système calcule automatiquement le temps total d'une recette
- FR4  : L'utilisateur peut catégoriser une recette par type de repas (petit-déjeuner, déjeuner, dîner, goûter, dessert)
- FR5  : L'utilisateur peut associer une saison à une recette (printemps, été, automne, hiver, toute saison)
- FR6  : L'utilisateur peut marquer une recette comme végétarienne
- FR7  : L'utilisateur peut définir le nombre de portions d'une recette
- FR8  : L'utilisateur peut ajouter des ingrédients structurés à une recette (nom, quantité, unité, rayon supermarché)
- FR9  : L'utilisateur peut ajouter des photos à une recette (depuis la caméra ou la galerie)
- FR10 : L'utilisateur peut ajouter des notes libres à une recette
- FR11 : L'utilisateur peut ajouter des variantes et astuces à une recette
- FR12 : L'utilisateur peut renseigner une URL source pour une recette
- FR13 : L'utilisateur peut modifier une recette existante
- FR14 : L'utilisateur peut supprimer une recette (action confirmée explicitement)
- FR15 : L'utilisateur peut marquer une recette en favori ou retirer ce statut
- FR16 : L'utilisateur peut accéder à la création de recette depuis n'importe quel écran

### Gestion du Foyer

- FR17 : L'utilisateur peut créer un profil pour chaque membre du foyer (nom, âge)
- FR18 : L'utilisateur peut modifier un profil de membre du foyer
- FR19 : L'utilisateur peut supprimer un profil de membre du foyer
- FR20 : L'utilisateur peut attribuer une notation par recette et par membre (aimé / pas aimé / neutre)
- FR21 : L'utilisateur peut modifier la notation d'un membre pour une recette
- FR22 : L'utilisateur peut noter les membres immédiatement après la création d'une recette

### Planning de Présence

- FR23 : L'utilisateur peut configurer un planning de présence type par membre (jour, repas : midi / soir)
- FR24 : L'utilisateur peut modifier ponctuellement les présences d'une semaine donnée sans altérer le planning type
- FR25 : L'utilisateur peut sélectionner la semaine à planifier

### Génération de Menus

- FR26 : L'utilisateur peut lancer la génération automatique d'un menu pour une semaine en 1 action
- FR27 : Le système génère uniquement les repas correspondant aux présences de la semaine
- FR28 : Le système priorise les recettes marquées en favori lors de la génération
- FR29 : Le système exclut les recettes notées "pas aimé" par un membre présent au repas concerné
- FR30 : Le système privilégie les recettes notées "aimé" par les membres présents au repas concerné
- FR31 : Le système évite de répéter des recettes figurant dans les menus des semaines précédentes (anti-répétition)
- FR32 : L'utilisateur peut appliquer des filtres à la génération (temps de préparation maximum, végétarien, saison)
- FR33 : L'utilisateur peut remplacer manuellement un repas généré par une recette de son choix
- FR34 : L'utilisateur peut valider le menu généré
- FR35 : Le système conserve l'historique des menus générés et validés
- FR36 : Le système affiche un message indiquant le nombre de créneaux non remplis quand la génération est incomplète
- FR37 : Le système propose des options de résolution en cas de génération incomplète (élargir les filtres, compléter manuellement, laisser créneaux vides)

### Onboarding

- FR38 : L'application guide l'utilisateur à travers 3 étapes à la première ouverture (foyer → planning → premières recettes)
- FR39 : La génération de menu est accessible dès 3 recettes dans la collection

---

## Non-Functional Requirements

### Performance

- NFR1 : La génération de menu s'exécute en moins de 2 secondes sur un smartphone standard (testé sur iOS ≥ 16 et Android ≥ 10)
- NFR2 : Chaque écran se charge en moins de 1 seconde en navigation normale
- NFR3 : Les images de recettes sont compressées à moins de 500 Ko avant stockage (mesurable à l'inspection du fichier stocké)

### Fiabilité des Données

- NFR4 : Toutes les données (recettes, profils, planning, notations, historique menus) sont persistées localement sans perte après fermeture normale ou forcée de l'application
- NFR5 : La suppression d'une recette ou d'un profil requiert une confirmation explicite de l'utilisateur avant exécution
- NFR6 : Aucune donnée utilisateur n'est transmise à un serveur externe (vérifiable par analyse du trafic réseau)

### Utilisabilité Mobile

- NFR7 : Les 3 actions principales (générer un menu, créer une recette, valider un menu) sont accessibles en 3 taps maximum depuis l'écran d'accueil
- NFR8 : Tous les éléments interactifs principaux sont positionnés dans la zone de confort du pouce (bas de l'écran, accessibles à une main)
- NFR9 : La création d'une recette minimale (nom + type de repas + temps de préparation) est réalisable en moins de 60 secondes
- NFR10 : L'application fonctionne sans connexion internet (toutes fonctionnalités opérationnelles en mode offline)
- NFR11 : L'application est compatible iOS ≥ 16 (iPhone) et Android ≥ 10 (smartphones)
