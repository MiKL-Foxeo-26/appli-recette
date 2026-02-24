import 'dart:async';
import 'dart:developer';

import 'package:appli_recette/core/sync/connectivity_monitor.dart';
import 'package:appli_recette/core/sync/sync_queue_processor.dart';
import 'package:appli_recette/core/sync/sync_status.dart';

/// Orchestre [ConnectivityMonitor] et [SyncQueueProcessor].
/// Déclenche la synchronisation automatiquement quand le réseau revient.
class SyncService {
  SyncService(this._monitor, this._processor);

  final ConnectivityMonitor _monitor;
  final SyncQueueProcessor _processor;

  final _statusController = StreamController<SyncStatus>.broadcast();
  StreamSubscription<bool>? _connectivitySub;

  Stream<SyncStatus> get statusStream => _statusController.stream;

  /// Démarre la surveillance de connectivité.
  void start() {
    _connectivitySub?.cancel();
    _connectivitySub = _monitor.isOnline.listen(
      _onConnectivityChanged,
      onError: (Object e) => log('SyncService connectivity error: $e'),
    );
    // Vérification immédiate au démarrage (AC-6)
    _monitor.checkCurrentStatus().then(
      (isOnline) {
        if (isOnline) _processQueue();
      },
      onError: (Object e) => log('SyncService checkCurrentStatus error: $e'),
    );
  }

  Future<void> _onConnectivityChanged(bool isOnline) async {
    if (isOnline) {
      await _processQueue();
    } else {
      _statusController.add(SyncStatus.offline);
    }
  }

  Future<void> _processQueue() async {
    _statusController.add(SyncStatus.syncing);
    try {
      await _processor.processQueue();
      _statusController.add(SyncStatus.synced);
    } catch (e) {
      log('SyncService processQueue error: $e');
      _statusController.add(SyncStatus.error);
    }
  }

  void dispose() {
    _connectivitySub?.cancel();
    _statusController.close();
  }
}
