/// Enum des saisons pour filtrer les recettes.
enum Season {
  spring('spring', 'Printemps'),
  summer('summer', 'Été'),
  autumn('autumn', 'Automne'),
  winter('winter', 'Hiver'),
  allSeasons('all', 'Toute saison');

  const Season(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static Season fromDb(String value) =>
      values.firstWhere((e) => e.dbValue == value, orElse: () => allSeasons);

  static Season? tryFromDb(String? value) {
    if (value == null) return null;
    try {
      return values.firstWhere((e) => e.dbValue == value);
    } catch (_) {
      return null;
    }
  }
}
