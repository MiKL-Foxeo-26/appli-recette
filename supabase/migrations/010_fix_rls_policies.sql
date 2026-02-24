-- Migration 010: Correction des politiques RLS (Story 7.3)
-- PRÉREQUIS : Migration 009 (household_auth_devices + get_my_household_id()) doit être
-- appliquée en premier.
--
-- PROBLÈME dans les migrations 001-008 :
-- Les politiques comparaient auth.uid() (Supabase auth UUID d'un device anonyme)
-- avec members.id (UUID d'un membre du foyer comme "Papa", "Maman").
-- Ces deux UUID sont sémantiquement différents → aucune donnée n'était accessible.
--
-- SOLUTION : utiliser get_my_household_id() qui résout auth.uid() → household_id
-- via la table household_auth_devices (migration 009).

-- ─────────────────────────────────────────────────────────────────────────────
-- Table: households
-- ─────────────────────────────────────────────────────────────────────────────
-- Note : SELECT/INSERT ouverts aux users authentifiés.
-- Nécessaire pour le flow de création (INSERT avant household_auth_devices)
-- et pour le flow de rejoindre (SELECT WHERE code = ? avant d'être lié).
-- UPDATE restreint au foyer propre de l'utilisateur.

DROP POLICY IF EXISTS "household_members_only" ON households;

CREATE POLICY "household_select" ON households
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "household_insert" ON households
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "household_update" ON households
  FOR UPDATE USING (id = get_my_household_id())
  WITH CHECK (id = get_my_household_id());

-- ─────────────────────────────────────────────────────────────────────────────
-- Table: members (membres du foyer — pas des auth users)
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "same_household_only" ON members;

CREATE POLICY "same_household_only" ON members
  FOR ALL USING (household_id = get_my_household_id())
  WITH CHECK (household_id = get_my_household_id());

-- ─────────────────────────────────────────────────────────────────────────────
-- Table: recipes
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "same_household_only" ON recipes;

CREATE POLICY "same_household_only" ON recipes
  FOR ALL USING (household_id = get_my_household_id())
  WITH CHECK (household_id = get_my_household_id());

-- ─────────────────────────────────────────────────────────────────────────────
-- Table: ingredients (pas de household_id direct — hérite via recipe_id)
-- Nom de table : "ingredients" (pas "recipe_ingredients")
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "same_household_only" ON ingredients;

CREATE POLICY "same_household_only" ON ingredients
  FOR ALL USING (
    recipe_id IN (
      SELECT id FROM recipes WHERE household_id = get_my_household_id()
    )
  )
  WITH CHECK (
    recipe_id IN (
      SELECT id FROM recipes WHERE household_id = get_my_household_id()
    )
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- Table: meal_ratings (pas de household_id direct — via member_id → members)
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "same_household_only" ON meal_ratings;

CREATE POLICY "same_household_only" ON meal_ratings
  FOR ALL USING (
    member_id IN (
      SELECT id FROM members WHERE household_id = get_my_household_id()
    )
  )
  WITH CHECK (
    member_id IN (
      SELECT id FROM members WHERE household_id = get_my_household_id()
    )
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- Table: presence_schedules (pas de household_id direct — via member_id → members)
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "same_household_only" ON presence_schedules;

CREATE POLICY "same_household_only" ON presence_schedules
  FOR ALL USING (
    member_id IN (
      SELECT id FROM members WHERE household_id = get_my_household_id()
    )
  )
  WITH CHECK (
    member_id IN (
      SELECT id FROM members WHERE household_id = get_my_household_id()
    )
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- Table: weekly_menus
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "same_household_only" ON weekly_menus;

CREATE POLICY "same_household_only" ON weekly_menus
  FOR ALL USING (household_id = get_my_household_id())
  WITH CHECK (household_id = get_my_household_id());

-- ─────────────────────────────────────────────────────────────────────────────
-- Table: menu_slots (pas de household_id direct — via weekly_menu_id → weekly_menus)
-- Note : la colonne s'appelle "weekly_menu_id" (pas "menu_id")
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "same_household_only" ON menu_slots;

CREATE POLICY "same_household_only" ON menu_slots
  FOR ALL USING (
    weekly_menu_id IN (
      SELECT id FROM weekly_menus WHERE household_id = get_my_household_id()
    )
  )
  WITH CHECK (
    weekly_menu_id IN (
      SELECT id FROM weekly_menus WHERE household_id = get_my_household_id()
    )
  );
