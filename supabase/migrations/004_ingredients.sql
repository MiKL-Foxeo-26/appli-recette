-- Migration 004: Table ingredients
CREATE TABLE IF NOT EXISTS ingredients (
  id UUID PRIMARY KEY,
  recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  quantity REAL,
  unit TEXT,
  supermarket_section TEXT
);

ALTER TABLE ingredients ENABLE ROW LEVEL SECURITY;

CREATE POLICY "same_household_only" ON ingredients
  FOR ALL USING (
    recipe_id IN (
      SELECT id FROM recipes WHERE household_id IN (
        SELECT household_id FROM members WHERE id = auth.uid()::uuid
      )
    )
  );
