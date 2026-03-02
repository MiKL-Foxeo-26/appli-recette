-- Migration 018: RLS sur toutes les tables de données (Story 8.4 — AC 1, 3, 7)
-- Pattern uniforme : household_id IN (SELECT get_my_household_ids())
-- Prérequis : 013 (household_id colonnes), 015 (get_my_household_ids)

-- ─── recipes ──────────────────────────────────────────────────────────────────
ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "recipes_all" ON recipes;
CREATE POLICY "recipes_all" ON recipes
  FOR ALL
  USING (household_id IN (SELECT get_my_household_ids()))
  WITH CHECK (household_id IN (SELECT get_my_household_ids()));

-- ─── ingredients ──────────────────────────────────────────────────────────────
-- household_id ajouté dans migration 013
ALTER TABLE ingredients ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "ingredients_all" ON ingredients;
CREATE POLICY "ingredients_all" ON ingredients
  FOR ALL
  USING (household_id IN (SELECT get_my_household_ids()))
  WITH CHECK (household_id IN (SELECT get_my_household_ids()));

-- ─── members (membres drift — différent de household_members Supabase) ─────────
ALTER TABLE members ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "members_all" ON members;
CREATE POLICY "members_all" ON members
  FOR ALL
  USING (household_id IN (SELECT get_my_household_ids()))
  WITH CHECK (household_id IN (SELECT get_my_household_ids()));

-- ─── meal_ratings ─────────────────────────────────────────────────────────────
-- household_id ajouté dans migration 013
ALTER TABLE meal_ratings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "meal_ratings_all" ON meal_ratings;
CREATE POLICY "meal_ratings_all" ON meal_ratings
  FOR ALL
  USING (household_id IN (SELECT get_my_household_ids()))
  WITH CHECK (household_id IN (SELECT get_my_household_ids()));

-- ─── presence_schedules ──────────────────────────────────────────────────────
-- household_id ajouté dans migration 013
ALTER TABLE presence_schedules ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "presence_schedules_all" ON presence_schedules;
CREATE POLICY "presence_schedules_all" ON presence_schedules
  FOR ALL
  USING (household_id IN (SELECT get_my_household_ids()))
  WITH CHECK (household_id IN (SELECT get_my_household_ids()));

-- ─── weekly_menus ─────────────────────────────────────────────────────────────
ALTER TABLE weekly_menus ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "weekly_menus_all" ON weekly_menus;
CREATE POLICY "weekly_menus_all" ON weekly_menus
  FOR ALL
  USING (household_id IN (SELECT get_my_household_ids()))
  WITH CHECK (household_id IN (SELECT get_my_household_ids()));

-- ─── menu_slots ───────────────────────────────────────────────────────────────
-- household_id ajouté dans migration 013
ALTER TABLE menu_slots ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "menu_slots_all" ON menu_slots;
CREATE POLICY "menu_slots_all" ON menu_slots
  FOR ALL
  USING (household_id IN (SELECT get_my_household_ids()))
  WITH CHECK (household_id IN (SELECT get_my_household_ids()));
