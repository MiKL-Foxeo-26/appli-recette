-- Migration 007: Table weekly_menus (menus hebdomadaires)
CREATE TABLE IF NOT EXISTS weekly_menus (
  id UUID PRIMARY KEY,
  household_id UUID REFERENCES households(id) ON DELETE CASCADE,
  week_key TEXT NOT NULL,
  generated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  validated_at TIMESTAMPTZ,
  is_validated BOOLEAN NOT NULL DEFAULT false
);

ALTER TABLE weekly_menus ENABLE ROW LEVEL SECURITY;

CREATE POLICY "same_household_only" ON weekly_menus
  FOR ALL USING (
    household_id IN (
      SELECT household_id FROM members WHERE id = auth.uid()::uuid
    )
  );
