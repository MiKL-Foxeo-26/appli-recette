/// Retourne les initiales d'un nom (max 2 caractères).
///
/// - "Marie" → "M"
/// - "Jean Dupont" → "JD"
/// - "" → "?"
String initials(String name) {
  final parts = name.trim().split(' ');
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}
