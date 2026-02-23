/// Utilitaires de conversion date ↔ weekKey (format ISO 8601 : "YYYY-Www").
///
/// Convention : lundi = premier jour de la semaine (ISO 8601).

/// Convertit un [DateTime] en weekKey ISO 8601 : "2026-W09".
String dateToWeekKey(DateTime date) {
  // Trouver le jeudi de la même semaine ISO (la semaine ISO est définie
  // par le jeudi qu'elle contient).
  final thursday = date.subtract(Duration(days: date.weekday - DateTime.thursday));
  // Le numéro d'année ISO est l'année du jeudi.
  final isoYear = thursday.year;
  // Premier jeudi de l'année.
  final jan4 = DateTime(isoYear, 1, 4);
  final firstThursday = jan4.subtract(Duration(days: jan4.weekday - DateTime.thursday));
  // Numéro de semaine.
  final weekNumber = ((thursday.difference(firstThursday).inDays) ~/ 7) + 1;
  return '$isoYear-W${weekNumber.toString().padLeft(2, '0')}';
}

/// Retourne le weekKey de la semaine courante.
String currentWeekKey() => dateToWeekKey(DateTime.now());

/// Retourne la plage de dates (lundi 00:00, dimanche 23:59) pour un weekKey.
///
/// Le [weekKey] doit être au format ISO 8601 "YYYY-Www" (ex: "2026-W09").
/// Lève [FormatException] si le format est invalide.
({DateTime monday, DateTime sunday}) weekKeyToDateRange(String weekKey) {
  final parts = weekKey.split('-W');
  if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
    throw FormatException('weekKey invalide : "$weekKey" (format attendu : "YYYY-Www")');
  }
  final year = int.tryParse(parts[0]);
  final week = int.tryParse(parts[1]);
  if (year == null || week == null || week < 1 || week > 53) {
    throw FormatException('weekKey invalide : "$weekKey" (année ou semaine non numérique)');
  }

  // Trouver le premier jeudi de l'année.
  final jan4 = DateTime(year, 1, 4);
  final firstThursday = jan4.subtract(Duration(days: jan4.weekday - DateTime.thursday));
  // Lundi de la première semaine ISO.
  final firstMonday = firstThursday.subtract(const Duration(days: 3));
  // Lundi de la semaine demandée.
  final monday = firstMonday.add(Duration(days: (week - 1) * 7));
  final sunday = monday.add(const Duration(days: 6));
  return (monday: monday, sunday: sunday);
}

/// Décale un weekKey de [offset] semaines (positif = futur, négatif = passé).
String weekKeyOffset(String weekKey, int offset) {
  final range = weekKeyToDateRange(weekKey);
  final shifted = range.monday.add(Duration(days: offset * 7));
  return dateToWeekKey(shifted);
}
