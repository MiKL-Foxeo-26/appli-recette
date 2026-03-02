-- Migration 012: households v2 — ajouter name + created_by; créer household_members
-- Story 8.2 — Gestion du Foyer (Authentification email/password, non anonyme)

-- ─── households : ajouter les nouvelles colonnes ────────────────────────────
ALTER TABLE households
  ADD COLUMN IF NOT EXISTS name TEXT NOT NULL DEFAULT 'Mon Foyer',
  ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL;

-- ─── household_members : nouvelle table (remplace household_auth_devices) ───
CREATE TABLE IF NOT EXISTS household_members (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id  UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role          TEXT NOT NULL CHECK (role IN ('owner', 'member')) DEFAULT 'member',
  joined_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(household_id, user_id)
);

ALTER TABLE household_members ENABLE ROW LEVEL SECURITY;

-- Policy temporaire : tout utilisateur authentifié peut lire/écrire ses propres lignes
-- (les RLS définitives seront dans Story 8.4 avec auth.uid())
CREATE POLICY "household_members_own" ON household_members
  FOR ALL USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Policy temporaire households : SELECT/INSERT pour utilisateurs authentifiés
DROP POLICY IF EXISTS "household_select" ON households;
DROP POLICY IF EXISTS "household_insert" ON households;

CREATE POLICY "household_select" ON households
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "household_insert" ON households
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
