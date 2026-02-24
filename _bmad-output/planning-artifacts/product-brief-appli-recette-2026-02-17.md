---
stepsCompleted: [1, 2, 3, 4, 5, 6]
inputDocuments: []
date: 2026-02-17
author: MiKL
---

# Product Brief: Appli Recette

## Executive Summary

Appli Recette est une application mobile personnelle de planification de menus familiaux. Elle élimine la surcharge mentale du "qu'est-ce qu'on mange ?" en combinant une collection de recettes personnelle enrichissable et une génération intelligente de menus adaptée au planning réel du foyer et aux préférences de chaque membre de la famille.

---

## Core Vision

### Problem Statement

Planifier les repas d'une famille chaque semaine est un effort mental constant et épuisant : se souvenir de ce que chacun aime, trouver des idées équilibrées et variées, ne pas répéter les mêmes plats, adapter au planning de présence — tout cela s'accumule dans la tête, sans système, sans aide, sans répit.

### Problem Impact

- Fatigue décisionnelle chronique liée au "qu'est-ce qu'on mange ?"
- Menus déséquilibrés ou répétitifs par manque d'inspiration
- Repas qui ne plaisent pas à tous faute de mémoire des préférences
- Énergie gaspillée sur une tâche logistique ingrate

### Why Existing Solutions Fall Short

Aucune application n'est utilisée aujourd'hui — les solutions existantes sont soit des trackers caloriques (hors sujet), soit des planificateurs génériques sans profil familial réel, soit des apps de recettes sans intelligence de planning. Aucune ne réunit : cuisine personnelle + goûts par membre + planning de présence + liste de courses.

### Proposed Solution

Une application mobile personnelle qui :

- Centralise les **recettes personnelles** sous forme de fiches structurées (temps, saison, végétarien, ingrédients par rayon, portions, photos, notes, variantes)
- Gère des **profils par membre du foyer** avec notation par recette (Leonard 11 ans ✓ / Alizée 9 ans ✗ / parents ✓)
- Intègre un **planning de présence** (qui est là, quand) pour générer exactement les repas nécessaires
- **Génère les menus de la semaine** en priorisant les favoris, respectant les goûts de chacun selon les présents, assurant une diversité alimentaire saine (légumes, protéines, féculents)

### Key Differentiators

- **Mémoire familiale** : les goûts de chaque personne informent chaque génération
- **Planning intelligent** : génère exactement ce dont vous avez besoin selon qui est présent
- **Zéro tracking calorique** : diversité alimentaire réelle, pas de comptage contraignant
- **Usage 100% personnel** : aucune dimension sociale, juste votre famille

---

## Target Users

### Primary User

**MiKL — Le Parent Organisateur**

Parent de famille avec deux enfants (Leonard, 11 ans et Alizée, 9 ans), MiKL gère le planning des repas seul dans sa tête depuis trop longtemps. Chaque semaine revient la même question épuisante : "Qu'est-ce qu'on mange ?" Le dimanche ou le lundi, entre deux obligations, il faut trouver des idées, se souvenir de ce que chacun aime, s'assurer que c'est varié et équilibré — tout ça sans aucun outil, juste la mémoire et la volonté.

**Motivations :**
- Libérer son énergie mentale pour ce qui compte vraiment
- Satisfaire les goûts de chaque membre du foyer sans effort de mémoire
- Assurer une alimentation variée et saine sans devenir nutritionniste

**Contexte d'utilisation :**
- Dimanche ou lundi, posé dans le canapé ou en errance devant le frigo
- Smartphone en main, quelques minutes disponibles
- Veut que ça aille vite et que le résultat soit fiable

**Douleurs actuelles :**
- Panne d'inspiration chronique ("encore des pâtes ?")
- Impossibilité de tout garder en tête : qui aime quoi, ce qu'on a fait la semaine dernière, ce qui est de saison
- Créativité et énergie mentale gaspillées sur une tâche logistique

**Définition du succès :**
"Je génère mon menu de la semaine en 2 minutes le dimanche matin. Chaque repas correspond à qui est là ce jour-là. Tout le monde mange quelque chose qu'il aime. Mon cerveau est libre pour autre chose."

### Secondary Users

Aucun — application à usage strictement personnel.

### User Journey

**1. Onboarding**
MiKL crée les profils du foyer (lui, son partenaire, Leonard, Alizée), configure son planning de présence type (lundi soir à la maison, mercredi midi, week-end complet) et commence à alimenter sa collection avec quelques recettes favorites.

**2. Usage hebdomadaire (cœur du produit)**
Le dimanche ou lundi, il ouvre l'app depuis le canapé. Il sélectionne la semaine à planifier, ajuste si besoin les présences, lance la génération. L'app propose un menu complet en tenant compte des favoris, des goûts de chacun et de la variété. Il valide, ajuste un repas si l'envie lui prend.

**3. Moment "ça a marché"**
Fin de semaine : tous les repas ont plu. Leonard a adoré le gratin, Alizée a mangé les légumes sans broncher, aucune panne d'inspiration. MiKL réalise qu'il n'a pas pensé aux repas de la semaine une seule fois en dehors du dimanche matin.

**4. Boucle d'amélioration continue**
Après chaque repas, il note en 5 secondes qui a aimé ou non. La collection grandit. Les générations futures deviennent de plus en plus précises. L'app apprend la mémoire du foyer.

---

## Success Metrics

_Section volontairement simplifiée — usage personnel, pas de métriques formelles._

Le succès se mesure simplement : moins de temps passé à planifier les repas, plus de repas appréciés par tous, collection de recettes qui grandit et s'affine semaine après semaine.

---

## MVP Scope

### Core Features (V1)

**Bloc A — Recettes personnelles**
- Créer / modifier / supprimer une fiche recette structurée :
  temps de préparation, temps de cuisson, temps de repos,
  temps total (calculé), type de repas, saison, végétarien (oui/non),
  nombre de portions, ingrédients (nom · quantité · unité · rayon),
  photos, notes libres, variantes, source URL
- Marquer une recette en favori

**Bloc B — Foyer & Mémoire**
- Créer les profils des membres du foyer (nom, âge)
- Noter une recette par membre (aimé / pas aimé / neutre)
- La génération priorise les favoris et tient compte des notes
  de chaque membre selon qui est présent ce repas-là

**Bloc C — Planning & Génération**
- Configurer un planning de présence type
  (qui est là, quel jour, quel repas : midi / soir)
- Générer le menu de la semaine en un clic
- Ajuster manuellement n'importe quel repas généré
- Filtres de génération : temps de préparation, végétarien, saison

### Out of Scope for V1

- Liste de courses (V2)
- Bibliothèque de recettes publique (V2)
- Import et modification de recettes externes (V2)
- Suggestion de recettes publiques à la demande (V2)

### Future Vision (V2)

**Bloc D — Liste de courses**
- Générer la liste de courses depuis le menu de la semaine validé
- Générer la liste depuis une recette individuelle
- Liste triée par rayon supermarché

**Bloc E — Bibliothèque publique**
- Accéder à une base de recettes publique gratuite
- Filtrer (temps, végétarien, saison...)
- Importer une recette et la modifier librement dans sa collection
- Découverte à la demande ("suggère-moi quelque chose pour ce soir")
