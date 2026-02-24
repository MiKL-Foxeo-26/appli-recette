-- Migration 011: Fix get_my_household_id() — ajouter ORDER BY joined_at DESC
-- Sans ORDER BY, LIMIT 1 retourne un résultat non déterministe si un user
-- est membre de plusieurs foyers. On veut le foyer le plus récemment rejoint.

CREATE OR REPLACE FUNCTION get_my_household_id()
RETURNS UUID LANGUAGE SQL SECURITY DEFINER AS $$
  SELECT household_id
  FROM household_auth_devices
  WHERE auth_user_id = auth.uid()
  ORDER BY joined_at DESC
  LIMIT 1;
$$;
