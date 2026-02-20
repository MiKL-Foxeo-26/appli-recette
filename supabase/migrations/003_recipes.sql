-- Migration 003: Table recipes (recettes)
CREATE TABLE IF NOT EXISTS recipes (
  id UUID PRIMARY KEY,
  household_id UUID REFERENCES households(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  meal_type TEXT NOT NULL,
  prep_time_minutes INTEGER NOT NULL DEFAULT 0,
  cook_time_minutes INTEGER NOT NULL DEFAULT 0,
  rest_time_minutes INTEGER NOT NULL DEFAULT 0,
  season TEXT NOT NULL DEFAULT 'all',
  is_vegetarian BOOLEAN NOT NULL DEFAULT false,
  servings INTEGER NOT NULL DEFAULT 4,
  notes TEXT,
  variants TEXT,
  source_url TEXT,
  photo_path TEXT,
  is_favorite BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "same_household_only" ON recipes
  FOR ALL USING (
    household_id IN (
      SELECT household_id FROM members WHERE id = auth.uid()::uuid
    )
  );
