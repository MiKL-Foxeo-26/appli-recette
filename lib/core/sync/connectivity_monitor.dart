import 'package:connectivity_plus/connectivity_plus.dart';

/// Surveille l'état de la connexion réseau.
/// Émet [true] quand le réseau est disponible, [false] sinon.
class ConnectivityMonitor {
  final _connectivity = Connectivity();

  Stream<bool> get isOnline => _connectivity.onConnectivityChanged
      .map((results) => results.any((r) => r != ConnectivityResult.none));

  Future<bool> checkCurrentStatus() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }
}
