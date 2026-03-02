-- Migration 017: RLS sur household_members (Story 8.4 — AC 1, 3)
-- Prérequis : 015 (get_my_household_ids)

-- Supprimer la policy temporaire créée dans migration 012
DROP POLICY IF EXISTS "household_members_own" ON household_members;

ALTER TABLE household_members ENABLE ROW LEVEL SECURITY;

-- SELECT : voir tous les membres des foyers auxquels on appartient
CREATE POLICY "household_members_select" ON household_members
  FOR SELECT
  USING (household_id IN (SELECT get_my_household_ids()));

-- INSERT : se rejoindre soi-même à un foyer (user_id = auth.uid() uniquement)
CREATE POLICY "household_members_insert" ON household_members
  FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- DELETE : se retirer d'un foyer, OU le propriétaire peut retirer des membres
CREATE POLICY "household_members_delete" ON household_members
  FOR DELETE
  USING (
    user_id = auth.uid()
    OR household_id IN (SELECT id FROM households WHERE created_by = auth.uid())
  );
