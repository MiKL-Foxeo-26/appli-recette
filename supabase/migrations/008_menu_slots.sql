-- Migration 008: Table menu_slots (créneaux repas)
CREATE TABLE IF NOT EXISTS menu_slots (
  id UUID PRIMARY KEY,
  weekly_menu_id UUID NOT NULL REFERENCES weekly_menus(id) ON DELETE CASCADE,
  recipe_id UUID REFERENCES recipes(id) ON DELETE SET NULL,
  day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
  meal_slot TEXT NOT NULL CHECK (meal_slot IN ('lunch', 'dinner')),
  is_locked BOOLEAN NOT NULL DEFAULT false
);

ALTER TABLE menu_slots ENABLE ROW LEVEL SECURITY;

CREATE POLICY "same_household_only" ON menu_slots
  FOR ALL USING (
    weekly_menu_id IN (
      SELECT id FROM weekly_menus WHERE household_id IN (
        SELECT household_id FROM members WHERE id = auth.uid()::uuid
      )
    )
  );
