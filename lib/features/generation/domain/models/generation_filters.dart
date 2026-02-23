import 'package:appli_recette/features/recipes/domain/models/season.dart';

/// Filtres optionnels appliqués lors de la génération de menu.
///
/// Ces filtres sont appliqués comme sous-couche de la Couche 1
/// (pré-filtrage avant les couches 2–6).
class GenerationFilters {
  const GenerationFilters({
    this.maxPrepTimeMinutes,
    this.vegetarianOnly = false,
    this.season,
  });

  /// Temps de préparation maximum en minutes. Null = pas de limite.
  final int? maxPrepTimeMinutes;

  /// Si true, seules les recettes végétariennes sont incluses.
  final bool vegetarianOnly;

  /// Saison filtrée. Null = aucun filtre saison.
  final Season? season;

  GenerationFilters copyWith({
    Object? maxPrepTimeMinutes = _sentinel,
    bool? vegetarianOnly,
    Object? season = _sentinel,
  }) {
    return GenerationFilters(
      maxPrepTimeMinutes: maxPrepTimeMinutes == _sentinel
          ? this.maxPrepTimeMinutes
          : maxPrepTimeMinutes as int?,
      vegetarianOnly: vegetarianOnly ?? this.vegetarianOnly,
      season: season == _sentinel ? this.season : season as Season?,
    );
  }

  bool get hasActiveFilters =>
      maxPrepTimeMinutes != null || vegetarianOnly || season != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GenerationFilters &&
          runtimeType == other.runtimeType &&
          maxPrepTimeMinutes == other.maxPrepTimeMinutes &&
          vegetarianOnly == other.vegetarianOnly &&
          season == other.season;

  @override
  int get hashCode =>
      maxPrepTimeMinutes.hashCode ^ vegetarianOnly.hashCode ^ season.hashCode;
}

// Sentinel pour distinguer null explicite de "non fourni"
const _sentinel = Object();
