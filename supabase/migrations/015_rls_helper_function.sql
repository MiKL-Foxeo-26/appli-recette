-- Migration 015: Fonction SECURITY DEFINER get_my_household_ids() (Story 8.4 — AC 2, 8)
-- Retourne tous les household_id de l'utilisateur courant.
-- SECURITY DEFINER : contourne la RLS sur household_members (évite récursion infinie).
-- STABLE : résultat stable dans la même transaction (optimisation Postgres).

CREATE OR REPLACE FUNCTION get_my_household_ids()
RETURNS SETOF UUID
LANGUAGE SQL
SECURITY DEFINER
STABLE
AS $$
  SELECT household_id
  FROM household_members
  WHERE user_id = auth.uid();
$$;
