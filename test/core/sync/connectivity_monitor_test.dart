import 'package:appli_recette/core/sync/connectivity_monitor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Binding requis pour les platform channels
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConnectivityMonitor', () {
    test('peut être instancié sans erreur', () {
      expect(() => ConnectivityMonitor(), returnsNormally);
    });

    test('isOnline est un Stream<bool>', () {
      final monitor = ConnectivityMonitor();
      expect(monitor.isOnline, isA<Stream<bool>>());
    });

    // Note: checkCurrentStatus() accède aux canaux natifs et ne peut être
    // testé unitairement qu'avec un device/émulateur réel.
    // La logique est vérifiée par intégration (Story 7.3).
  });
}
