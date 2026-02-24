# Story 3.1 : Créer et Gérer les Profils Membres du Foyer

Status: review

## Story

En tant qu'utilisateur,
Je veux créer un profil pour chaque membre de mon foyer,
Afin que l'algorithme puisse tenir compte de chaque personne lors de la génération de menus.

## Acceptance Criteria

1. **Given** je suis sur l'écran Foyer **When** je tape sur "Ajouter un membre" **Then** un formulaire s'affiche avec les champs nom et âge (FR17)
2. **Given** j'ai rempli le nom et l'âge **When** je valide **Then** le membre est persisté dans drift (table `members`) avec un UUID v4 et apparaît dans la liste du foyer (NFR4)
3. **Given** un membre existant **When** je tape sur Modifier **Then** je peux changer le nom et l'âge et sauvegarder (FR18)
4. **Given** je veux supprimer un membre **When** je tape sur Supprimer **Then** un Dialog de confirmation Material 3 s'affiche (NFR5, FR19)
5. **Given** je confirme la suppression **Then** le membre est supprimé ainsi que toutes ses `meal_ratings` et `presence_schedules` associées (cascade)
6. **Given** le foyer est vide **Then** l'état vide affiche "Ajoute les membres de ton foyer" avec bouton "Ajouter un membre"

## Tasks / Subtasks

- [x] Task 1 : Modèle domain + repository (AC: 2, 3, 5)
  - [x] 1.1 Créer `lib/features/household/data/models/member.dart` (classe drift + champs : id UUID, name, age, createdAt) — utilisé directement `Member` généré par drift depuis `MembersTable`
  - [x] 1.2 Créer l'interface `lib/features/household/domain/repositories/household_repository.dart` avec méthodes : `watchAll()`, `addMember()`, `updateMember()`, `deleteMember()`
  - [x] 1.3 Créer `lib/features/household/data/repositories/household_repository_impl.dart` implémentant l'interface via datasource
  - [x] 1.4 Créer `lib/features/household/data/datasources/member_local_datasource.dart` (drift DAO pour `MembersTable`)
  - [x] 1.5 Vérifié : `MembersTable` contient id TEXT PK, name TEXT, age INTEGER nullable, createdAt, updatedAt, isSynced

- [x] Task 2 : Provider Riverpod (AC: 2, 3, 5)
  - [x] 2.1 Créer `lib/features/household/presentation/providers/household_provider.dart` avec `AsyncNotifierProvider<HouseholdNotifier, void>` + `StreamProvider<List<Member>>`
  - [x] 2.2 Implémenter `addMember()`, `updateMember()`, `deleteMember()` dans le notifier
  - [x] 2.3 La suppression cascade est gérée automatiquement par `PRAGMA foreign_keys = ON` + `onDelete: KeyAction.cascade` sur les FK de `meal_ratings` et `presence_schedules`

- [x] Task 3 : Écran Foyer + liste membres (AC: 1, 6)
  - [x] 3.1 Mis à jour `lib/features/household/view/household_page.dart` (placeholder → écran complet)
  - [x] 3.2 Liste les membres via `ref.watch(membersStreamProvider)` avec pattern `AsyncValue.when`
  - [x] 3.3 État vide "Ajoute les membres de ton foyer 👨‍👩‍👧‍👦" avec FilledButton "Ajouter un membre" (#E8794A)
  - [x] 3.4 Créé `lib/features/household/presentation/widgets/member_card.dart` : avatar initiales + nom + âge + boutons Modifier/Supprimer (48×48px, Semantics)

- [x] Task 4 : Formulaire création/édition membre (AC: 1, 2, 3)
  - [x] 4.1 Créé `lib/features/household/view/member_form_page.dart`
  - [x] 4.2 Champs : nom (TextFormField, obligatoire) + âge (TextFormField numérique, optionnel)
  - [x] 4.3 Validation : nom non vide requis, âge entier positif si renseigné
  - [x] 4.4 Mode création (member == null) vs mode édition (member != null, champs pré-remplis)
  - [x] 4.5 FilledButton "Enregistrer" (#E8794A), TextButton "Annuler"

- [x] Task 5 : Dialog de confirmation suppression (AC: 4, 5)
  - [x] 5.1 AlertDialog Material 3 avec titre "Supprimer [Nom] ?" + conséquence cascade
  - [x] 5.2 Boutons : TextButton "Annuler" + FilledButton "Supprimer" (rouge #C0392B)
  - [x] 5.3 Appelle `householdNotifierProvider.notifier.deleteMember(id)` après confirmation

- [x] Task 6 : Routing go_router (AC: 1)
  - [x] 6.1 Ajouté `AppRoutes.memberAdd` (`/household/member/add`) et `AppRoutes.memberEdit` (`/household/member/:id/edit`) + helper `memberEditPath(id)` dans `lib/core/router/app_router.dart`

- [x] Task 7 : Tests (AC: 1–6)
  - [x] 7.1 Créé `test/features/household/data/repositories/household_repository_test.dart`
  - [x] 7.2 10/10 tests passent : UUID v4, persistance, age null, watchAll vide, liste multiple, updateMember, deleteMember, cascade presence_schedules, IDs distincts

## Dev Notes

### Feature location
- Feature : `lib/features/household/` (FR17–22)
- Écran principal : `lib/features/household/presentation/screens/household_screen.dart`
- Onglet "Foyer" dans la bottom navigation (ShellRoute via go_router)

### Modèle Member (drift)
```dart
// lib/features/household/data/models/member.dart
class Member {
  final String id;    // UUID v4 — JAMAIS int autoincrement
  final String name;
  final int? age;
  final DateTime createdAt;
}
```

### Table drift existante
La table `MembersTable` est déjà définie dans `lib/core/database/tables/members_table.dart` (Epic 1 Story 1.4). Vérifier avant de créer une nouvelle table.

### Repository Pattern — OBLIGATOIRE
```dart
// ✅ Interface dans domain/
abstract class HouseholdRepository {
  Future<List<Member>> getMembers();
  Future<void> saveMember(Member member);
  Future<void> deleteMember(String id);
}
// ✅ Implémentation dans data/
class HouseholdRepositoryImpl implements HouseholdRepository { ... }
```
**INTERDIT** : accéder à drift ou Supabase directement depuis les widgets ou providers.

### UUID v4 — OBLIGATOIRE
```dart
import 'package:uuid/uuid.dart';
final String id = const Uuid().v4();
```

### Suppression cascade
Lors du `deleteMember(String id)`, supprimer dans cet ordre :
1. `meal_ratings` WHERE `member_id = id`
2. `presence_schedules` WHERE `member_id = id`
3. `members` WHERE `id = id`
Tout dans une transaction drift.

### Provider Riverpod pattern
```dart
final householdProvider = AsyncNotifierProvider<HouseholdNotifier, List<Member>>(
  HouseholdNotifier.new,
);
```
Utiliser `AsyncValue.when(loading, error, data)` dans les widgets — jamais `ref.read()` pour lire l'état UI.

### Dialog confirmation suppression
Pattern requis (NFR5) :
```dart
showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
    title: Text('Supprimer ${member.name} ?'),
    content: Text('Ses notations et présences seront également supprimées.'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler')),
      TextButton(
        style: TextButton.styleFrom(foregroundColor: Color(0xFFC0392B)),
        onPressed: () { Navigator.pop(ctx); ref.read(householdProvider.notifier).deleteMember(member.id); },
        child: Text('Supprimer'),
      ),
    ],
  ),
);
```

### État vide
```dart
// Quand members.isEmpty
Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Text('Ajoute les membres de ton foyer 👨‍👩‍👧‍👦'),
    ElevatedButton(
      onPressed: () => context.push('/household/member/add'),
      child: Text('Ajouter un membre'),
    ),
  ],
)
```

### UX — Design System
- Police : Nunito, tailles 12sp–22sp
- Fond général : #FDF6EF (crème ivoire)
- Surface cards : #FFFFFF
- Bouton primaire : fond #E8794A, texte blanc
- Bouton destructif : texte #C0392B
- Touch targets : ≥ 48×48px
- Semantics Flutter sur chaque composant custom (`Semantics(label: "Membre: ${member.name}")`)

### Dépendances Epic 2
Cette story suppose qu'Epic 2 est terminée : les recettes existent. Les `meal_ratings` créées ici seront associées aux recettes via `recipe_id`.

### Project Structure Notes
- Respecter structure feature-first : **INTERDIT** d'importer `features/recipes/` depuis `features/household/`
- Cross-feature communication via `core/` uniquement
- Tests miroir : `test/features/household/` reflète `lib/features/household/`

### References
- [Source: architecture.md#Structure Patterns] — feature-first, dépendances strictes
- [Source: architecture.md#Communication Patterns] — Repository pattern obligatoire
- [Source: architecture.md#Format Patterns] — UUID v4, AsyncValue
- [Source: epics.md#Story 3.1] — AC complets
- [Source: ux-design-specification.md#Additional Patterns] — états vides, confirmations destructives
- [Source: ux-design-specification.md#Visual Design Foundation] — palette couleurs

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

N/A — tous les tests passent du premier coup.

### Completion Notes List

- Utilisé `Member` drift-généré directement (pas de fichier modèle séparé) — le type est exporté via `app_database.dart`
- Cascade delete gérée par `PRAGMA foreign_keys = ON` (déjà activé dans `app_database.dart`) + FK `onDelete: KeyAction.cascade` sur `meal_ratings.member_id` et `presence_schedules.member_id` — pas besoin de transaction manuelle
- `HouseholdNotifier extends AsyncNotifier<void>` (void car l'état est lu via `membersStreamProvider`)
- 2 erreurs d'analyse pré-existantes Epic 2 (`recipe_local_datasource.dart`, `recipe_detail_screen.dart`) — non causées par cette story
- Warnings `info` sur nos fichiers : `avoid_catches_without_on_clauses`, quelques `lines_longer_than_80_chars` — non bloquants

### File List

- `lib/features/household/domain/repositories/household_repository.dart` (créé)
- `lib/features/household/data/datasources/member_local_datasource.dart` (créé)
- `lib/features/household/data/repositories/household_repository_impl.dart` (créé)
- `lib/features/household/presentation/providers/household_provider.dart` (créé)
- `lib/features/household/presentation/widgets/member_card.dart` (créé)
- `lib/features/household/view/member_form_page.dart` (créé)
- `lib/features/household/view/household_page.dart` (mis à jour — placeholder → écran complet)
- `lib/core/router/app_router.dart` (mis à jour — routes member add/edit)
- `test/features/household/data/repositories/household_repository_test.dart` (créé — 10 tests)
