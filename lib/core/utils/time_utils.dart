/// Formate une durée en minutes vers un format lisible (ex: "45 min", "1h30").
String formatTime(int minutes) {
  if (minutes <= 0) return '0 min';
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '${h}h' : '${h}h${m.toString().padLeft(2, '0')}';
}

/// Formate une quantité (supprime les .0 inutiles).
String formatQuantity(double qty) {
  return qty == qty.truncateToDouble()
      ? qty.toInt().toString()
      : qty.toString();
}
