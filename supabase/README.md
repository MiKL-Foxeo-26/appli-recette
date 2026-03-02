# Supabase — Schéma & Politiques RLS

## Ordre des migrations

| Migration | Fichier | Description |
|-----------|---------|-------------|
| 001 | `001_households.sql` | Table `households` |
| 002 | `002_members.sql` | Table `members` (membres du foyer drift) |
| 003 | `003_recipes.sql` | Table `recipes` |
| 004 | `004_ingredients.sql` | Table `ingredients` |
| 005 | `005_meal_ratings.sql` | Table `meal_ratings` |
| 006 | `006_presence_schedules.sql` | Table `presence_schedules` |
| 007 | `007_weekly_menus.sql` | Table `weekly_menus` |
| 008 | `008_menu_slots.sql` | Table `menu_slots` |
| 009 | `009_household_auth_devices.sql` | ~~Auth anonyme~~ (remplacé en 014) |
| 010 | `010_fix_rls_policies.sql` | ~~Anciennes RLS~~ (remplacées en 014-018) |
| 011 | `011_fix_get_my_household_id.sql` | ~~Fix get_my_household_id()~~ (supprimée en 014) |
| 012 | `012_households_v2_household_members.sql` | Table `household_members` + colonnes households |
| 013 | `013_add_household_id_direct_columns.sql` | `household_id` sur ingredients, meal_ratings, presence_schedules, menu_slots |
| **014** | `014_remove_old_auth_devices.sql` | **Nettoyage** : supprime `household_auth_devices` et `get_my_household_id()` |
| **015** | `015_rls_helper_function.sql` | **Fonction** `get_my_household_ids()` SECURITY DEFINER |
| **016** | `016_rls_households.sql` | **RLS** sur `households` |
| **017** | `017_rls_household_members.sql` | **RLS** sur `household_members` |
| **018** | `018_rls_data_tables.sql` | **RLS** sur toutes les tables de données |

---

## Politiques RLS par table (Story 8.4)

### Table : `households`

| Policy | Operation | Règle |
|--------|-----------|-------|
| `households_select` | SELECT | `id IN (SELECT get_my_household_ids())` |
| `households_insert` | INSERT | `created_by = auth.uid()` |
| `households_update` | UPDATE | `created_by = auth.uid()` |
| `households_delete` | DELETE | `created_by = auth.uid()` |

### Table : `household_members`

| Policy | Operation | Règle |
|--------|-----------|-------|
| `household_members_select` | SELECT | `household_id IN (SELECT get_my_household_ids())` |
| `household_members_insert` | INSERT | `user_id = auth.uid()` |
| `household_members_delete` | DELETE | `user_id = auth.uid()` OR propriétaire du foyer |

### Tables de données (pattern uniforme)

Tables : `recipes`, `ingredients`, `members`, `meal_ratings`, `presence_schedules`, `weekly_menus`, `menu_slots`

| Policy | Operation | Règle |
|--------|-----------|-------|
| `{table}_all` | ALL | `household_id IN (SELECT get_my_household_ids())` |

---

## Fonction helper : `get_my_household_ids()`

```sql
CREATE OR REPLACE FUNCTION get_my_household_ids()
RETURNS SETOF UUID
LANGUAGE SQL
SECURITY DEFINER  -- contourne la RLS sur household_members (évite récursion)
STABLE
AS $$
  SELECT household_id
  FROM household_members
  WHERE user_id = auth.uid();
$$;
```

**Pourquoi `SECURITY DEFINER` ?** Sans ce flag, la fonction hériterait des droits de l'appelant. Comme `household_members` a sa propre RLS, une requête directe dans une policy d'une autre table provoquerait une récursion infinie.

---

## Vérification dans le Dashboard Supabase

```sql
-- Vérifier que RLS est actif sur toutes les tables
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- Vérifier les policies existantes
SELECT tablename, policyname, cmd, qual
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

**Tables attendues avec RLS = true :**
- `households` ✓
- `household_members` ✓
- `recipes` ✓
- `ingredients` ✓
- `members` ✓
- `meal_ratings` ✓
- `presence_schedules` ✓
- `weekly_menus` ✓
- `menu_slots` ✓
