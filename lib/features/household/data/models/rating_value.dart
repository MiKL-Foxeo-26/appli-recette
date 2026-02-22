/// Valeur de notation d'un membre pour une recette.
enum RatingValue {
  liked,
  neutral,
  disliked;

  /// Valeur stockée en base (text) : 'liked', 'neutral', 'disliked'.
  String get dbValue => name;

  /// Reconstruit depuis la valeur texte en base.
  /// Retourne [neutral] si la valeur est inconnue (donnée corrompue).
  static RatingValue fromDb(String value) =>
      values.firstWhere((e) => e.name == value, orElse: () => neutral);

  /// Libellé affiché dans l'UI.
  String get label => switch (this) {
        RatingValue.liked => 'Aimé',
        RatingValue.neutral => 'Neutre',
        RatingValue.disliked => 'Pas aimé',
      };

  /// Emoji associé.
  String get emoji => switch (this) {
        RatingValue.liked => '❤️',
        RatingValue.neutral => '😐',
        RatingValue.disliked => '👎',
      };
}
