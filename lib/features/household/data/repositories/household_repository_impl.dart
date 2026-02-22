import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/features/household/data/datasources/meal_rating_datasource.dart';
import 'package:appli_recette/features/household/data/datasources/member_local_datasource.dart';
import 'package:appli_recette/features/household/data/models/rating_value.dart';
import 'package:appli_recette/features/household/domain/repositories/household_repository.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Implémentation concrète du HouseholdRepository.
/// Délègue aux datasources locaux (drift).
class HouseholdRepositoryImpl implements HouseholdRepository {
  HouseholdRepositoryImpl(this._memberDatasource, this._ratingDatasource);

  final MemberLocalDatasource _memberDatasource;
  final MealRatingDatasource _ratingDatasource;

  // ── Membres ──────────────────────────────────────────────────────────────

  @override
  Stream<List<Member>> watchAll() => _memberDatasource.watchAll();

  @override
  Future<String> addMember({required String name, int? age}) {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final companion = MembersCompanion.insert(
      id: id,
      name: name,
      age: age != null ? Value(age) : const Value.absent(),
      createdAt: now,
      updatedAt: now,
    );
    return _memberDatasource.insert(companion);
  }

  @override
  Future<void> updateMember({
    required String id,
    required String name,
    int? age,
  }) {
    final companion = MembersCompanion(
      id: Value(id),
      name: Value(name),
      age: Value(age),
      updatedAt: Value(DateTime.now()),
    );
    return _memberDatasource.update(companion);
  }

  @override
  Future<void> deleteMember(String id) => _memberDatasource.delete(id);

  // ── Notations ─────────────────────────────────────────────────────────────

  @override
  Stream<List<MealRating>> watchRatingsForRecipe(String recipeId) =>
      _ratingDatasource.watchForRecipe(recipeId);

  @override
  Future<void> upsertRating({
    required String memberId,
    required String recipeId,
    required RatingValue rating,
  }) {
    return _ratingDatasource.upsert(
      id: const Uuid().v4(),
      memberId: memberId,
      recipeId: recipeId,
      ratingValue: rating.dbValue,
    );
  }

  @override
  Future<void> deleteRating({
    required String memberId,
    required String recipeId,
  }) =>
      _ratingDatasource.deleteForMemberAndRecipe(
        memberId: memberId,
        recipeId: recipeId,
      );

  @override
  Future<void> deleteRatingsForRecipe(String recipeId) =>
      _ratingDatasource.deleteForRecipe(recipeId);
}
