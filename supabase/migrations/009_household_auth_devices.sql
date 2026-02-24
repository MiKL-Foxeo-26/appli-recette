-- Migration 009: Table household_auth_devices
-- Lie les auth.uid() Supabase anonymes aux household_id du foyer.
-- Chaque appareil qui crée ou rejoint un foyer y insère une ligne.

CREATE TABLE IF NOT EXISTS household_auth_devices (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID       NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  auth_user_id UUID       NOT NULL,
  joined_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(household_id, auth_user_id)
);

ALTER TABLE household_auth_devices ENABLE ROW LEVEL SECURITY;

-- Chaque device peut voir uniquement ses propres entrées
CREATE POLICY "own_device_only" ON household_auth_devices
  FOR SELECT USING (auth_user_id = auth.uid());

-- Tout auth user peut s'ajouter à un foyer (rejoindre ou créer)
CREATE POLICY "allow_join" ON household_auth_devices
  FOR INSERT WITH CHECK (auth_user_id = auth.uid());

-- Fonction helper : retourne le household_id de l'utilisateur courant.
-- Utilisée dans les politiques RLS des autres tables (Story 7.3).
CREATE OR REPLACE FUNCTION get_my_household_id()
RETURNS UUID LANGUAGE SQL SECURITY DEFINER AS $$
  SELECT household_id
  FROM household_auth_devices
  WHERE auth_user_id = auth.uid()
  LIMIT 1;
$$;
