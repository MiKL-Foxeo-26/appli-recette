/// Résultat d'un créneau de repas généré par [GenerationService].
///
/// [dayIndex] : 0 = lundi, 6 = dimanche
/// [mealType] : "lunch" ou "dinner"
class MealSlotResult {
  const MealSlotResult({
    required this.recipeId,
    required this.dayIndex,
    required this.mealType,
    this.isSpecialEvent = false,
  });

  /// ID (UUID v4) de la recette assignée à ce créneau.
  /// Vaut 'special_event' si [isSpecialEvent] est true.
  final String recipeId;

  /// Index du jour : 0 = lundi, 6 = dimanche.
  final int dayIndex;

  /// Type de repas : "lunch" ou "dinner".
  final String mealType;

  /// True si le créneau est marqué comme événement spécial (sans recette).
  final bool isSpecialEvent;

  MealSlotResult copyWith({
    String? recipeId,
    int? dayIndex,
    String? mealType,
    bool? isSpecialEvent,
  }) {
    return MealSlotResult(
      recipeId: recipeId ?? this.recipeId,
      dayIndex: dayIndex ?? this.dayIndex,
      mealType: mealType ?? this.mealType,
      isSpecialEvent: isSpecialEvent ?? this.isSpecialEvent,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealSlotResult &&
          runtimeType == other.runtimeType &&
          recipeId == other.recipeId &&
          dayIndex == other.dayIndex &&
          mealType == other.mealType &&
          isSpecialEvent == other.isSpecialEvent;

  @override
  int get hashCode =>
      recipeId.hashCode ^
      dayIndex.hashCode ^
      mealType.hashCode ^
      isSpecialEvent.hashCode;
}
