import 'package:appli_recette/core/sync/sync_provider.dart';
import 'package:appli_recette/core/sync/sync_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Badge discret dans l'AppBar indiquant l'état de synchronisation cloud.
/// ☁️ synced (vert), ⚠️ offline (gris), ↑ syncing (orange), erreur (rouge).
/// Jamais de dialog bloquant — discret uniquement (AC-7 Story 7.1).
class SyncStatusBadge extends ConsumerWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(syncStatusProvider);
    final status = statusAsync.maybeWhen(
      data: (s) => s,
      orElse: () => SyncStatus.synced,
    );

    return Tooltip(
      message: _tooltipMessage(status),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: _buildIcon(status),
      ),
    );
  }

  Widget _buildIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return const Icon(Icons.cloud_done, color: Colors.green, size: 20);
      case SyncStatus.offline:
        return const Icon(Icons.cloud_off, color: Colors.grey, size: 20);
      case SyncStatus.syncing:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.orange,
          ),
        );
      case SyncStatus.error:
        return Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.cloud_upload, color: Colors.red, size: 20),
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        );
    }
  }

  String _tooltipMessage(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return 'Synchronisé';
      case SyncStatus.offline:
        return 'Hors ligne';
      case SyncStatus.syncing:
        return 'Synchronisation en cours...';
      case SyncStatus.error:
        return 'Erreur de synchronisation';
    }
  }
}
