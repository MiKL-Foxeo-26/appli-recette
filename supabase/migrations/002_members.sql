-- Migration 002: Table members (membres du foyer)
CREATE TABLE IF NOT EXISTS members (
  id UUID PRIMARY KEY,
  household_id UUID REFERENCES households(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  age INTEGER,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "same_household_only" ON members
  FOR ALL USING (
    household_id IN (
      SELECT household_id FROM members WHERE id = auth.uid()::uuid
    )
  );
