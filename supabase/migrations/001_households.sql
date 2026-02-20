-- Migration 001: Table households (foyers)
CREATE TABLE IF NOT EXISTS households (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code CHAR(6) UNIQUE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- RLS
ALTER TABLE households ENABLE ROW LEVEL SECURITY;

CREATE POLICY "household_members_only" ON households
  FOR ALL USING (
    id IN (
      SELECT household_id FROM members WHERE auth.uid()::text = id
    )
  );
