-- Migration 013: Ajouter household_id direct sur tables sans FK vers households
-- Story 8.2 — requis pour les RLS par foyer (Story 8.4)
-- Note: members, recipes, weekly_menus ont déjà household_id (migrations 002, 003, 007)

-- ─── ingredients ─────────────────────────────────────────────────────────────
ALTER TABLE ingredients
  ADD COLUMN IF NOT EXISTS household_id UUID REFERENCES households(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_ingredients_household ON ingredients(household_id);

-- ─── meal_ratings ─────────────────────────────────────────────────────────────
ALTER TABLE meal_ratings
  ADD COLUMN IF NOT EXISTS household_id UUID REFERENCES households(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_meal_ratings_household ON meal_ratings(household_id);

-- ─── presence_schedules ──────────────────────────────────────────────────────
ALTER TABLE presence_schedules
  ADD COLUMN IF NOT EXISTS household_id UUID REFERENCES households(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_presence_schedules_household ON presence_schedules(household_id);

-- ─── menu_slots ──────────────────────────────────────────────────────────────
ALTER TABLE menu_slots
  ADD COLUMN IF NOT EXISTS household_id UUID REFERENCES households(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_menu_slots_household ON menu_slots(household_id);

-- ─── Index pour les tables qui avaient déjà household_id ─────────────────────
CREATE INDEX IF NOT EXISTS idx_recipes_household ON recipes(household_id);
CREATE INDEX IF NOT EXISTS idx_members_household ON members(household_id);
CREATE INDEX IF NOT EXISTS idx_weekly_menus_household ON weekly_menus(household_id);
