-- Migration 014: Suppression de l'ancien système d'auth anonyme (Story 8.4 — AC 5, 6)
-- Remplace household_auth_devices + get_my_household_id() par household_members + auth.uid() réel

-- Supprimer les anciennes policies qui dépendent de get_my_household_id()
-- (doivent être supprimées avant la fonction car les policies les référencent)

DROP POLICY IF EXISTS "household_update" ON households;
DROP POLICY IF EXISTS "household_select" ON households;
DROP POLICY IF EXISTS "household_insert" ON households;
DROP POLICY IF EXISTS "household_members_only" ON households;

DROP POLICY IF EXISTS "same_household_only" ON members;
DROP POLICY IF EXISTS "same_household_only" ON recipes;
DROP POLICY IF EXISTS "same_household_only" ON ingredients;
DROP POLICY IF EXISTS "same_household_only" ON meal_ratings;
DROP POLICY IF EXISTS "same_household_only" ON presence_schedules;
DROP POLICY IF EXISTS "same_household_only" ON weekly_menus;
DROP POLICY IF EXISTS "same_household_only" ON menu_slots;

-- Supprimer la table household_auth_devices et ses dépendances
DROP TABLE IF EXISTS household_auth_devices CASCADE;

-- Supprimer l'ancienne fonction helper (singulier)
DROP FUNCTION IF EXISTS get_my_household_id();
