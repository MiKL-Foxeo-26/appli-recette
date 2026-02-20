-- Migration 005: Table meal_ratings (notations par membre)
CREATE TABLE IF NOT EXISTS meal_ratings (
  id UUID PRIMARY KEY,
  member_id UUID NOT NULL REFERENCES members(id) ON DELETE CASCADE,
  recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  rating TEXT NOT NULL CHECK (rating IN ('liked', 'neutral', 'disliked')),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(member_id, recipe_id)
);

ALTER TABLE meal_ratings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "same_household_only" ON meal_ratings
  FOR ALL USING (
    member_id IN (
      SELECT id FROM members WHERE household_id IN (
        SELECT household_id FROM members WHERE id = auth.uid()::uuid
      )
    )
  );
