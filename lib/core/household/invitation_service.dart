import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Service de partage des invitations foyer.
class InvitationService {
  const InvitationService();

  /// Partage un message d'invitation via la feuille de partage native.
  ///
  /// Le message indique où trouver l'app et la marche à suivre,
  /// puis affiche le code en clair — pas de lien automatique.
  Future<void> shareInvitation(String code) async {
    await Share.share(
      '🍽️ Je t\'invite sur MenuFacile !\n'
      '\n'
      'MenuFacile planifie nos repas de la semaine en un clic.\n'
      'Rejoins mon foyer pour qu\'on organise nos menus ensemble.\n'
      '\n'
      '📱 Rends-toi sur : menufacile.app\n'
      '➡️  Crée un compte, puis entre le code suivant :\n'
      '\n'
      '  $code\n'
      '\n'
      'À bientôt sur MenuFacile !',
      subject: 'Rejoins mon foyer sur MenuFacile !',
    );
  }
}

/// Provider du service d'invitation foyer.
final invitationServiceProvider = Provider<InvitationService>(
  (_) => const InvitationService(),
);
