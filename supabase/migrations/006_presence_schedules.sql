-- Migration 006: Table presence_schedules (planning de présence)
CREATE TABLE IF NOT EXISTS presence_schedules (
  id UUID PRIMARY KEY,
  member_id UUID NOT NULL REFERENCES members(id) ON DELETE CASCADE,
  day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
  meal_slot TEXT NOT NULL CHECK (meal_slot IN ('lunch', 'dinner')),
  is_present BOOLEAN NOT NULL DEFAULT true,
  week_key TEXT -- NULL = planning type, "2026-W08" = override ponctuel
);

ALTER TABLE presence_schedules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "same_household_only" ON presence_schedules
  FOR ALL USING (
    member_id IN (
      SELECT id FROM members WHERE household_id IN (
        SELECT household_id FROM members WHERE id = auth.uid()::uuid
      )
    )
  );
