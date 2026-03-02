-- Migration 016: RLS sur households (Story 8.4 — AC 1, 3, 4)
-- Prérequis : 012 (household_members), 014 (cleanup), 015 (get_my_household_ids)

-- Supprimer les policies temporaires créées dans migration 012
DROP POLICY IF EXISTS "household_select" ON households;
DROP POLICY IF EXISTS "household_insert" ON households;

ALTER TABLE households ENABLE ROW LEVEL SECURITY;

-- SELECT : voir uniquement les foyers dont on est membre
CREATE POLICY "households_select" ON households
  FOR SELECT
  USING (id IN (SELECT get_my_household_ids()));

-- INSERT : tout utilisateur authentifié peut créer un foyer
CREATE POLICY "households_insert" ON households
  FOR INSERT
  WITH CHECK (created_by = auth.uid());

-- UPDATE : seul le propriétaire peut modifier son foyer
CREATE POLICY "households_update" ON households
  FOR UPDATE
  USING (created_by = auth.uid());

-- DELETE : seul le propriétaire peut supprimer son foyer (AC 4)
CREATE POLICY "households_delete" ON households
  FOR DELETE
  USING (created_by = auth.uid());
