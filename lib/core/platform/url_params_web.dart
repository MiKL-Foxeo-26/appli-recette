// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Implémentation web — lit le query param `?code=` depuis `window.location`.
String? extractCodeFromUrl() {
  final uri = Uri.parse(html.window.location.href);
  return uri.queryParameters['code'];
}
