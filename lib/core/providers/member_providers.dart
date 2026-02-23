/// Point d'accès cross-feature pour les données membres.
///
/// Les features qui ont besoin des membres du foyer doivent importer
/// ce fichier (`core/providers/member_providers.dart`) au lieu d'importer
/// directement depuis `features/household/`. Cela respecte la frontière
/// architecturale : features/ → features/ est interdit, mais
/// features/ → core/ est autorisé.
///
/// Le provider réel reste défini dans `features/household/` et est
/// re-exporté ici.
export 'package:appli_recette/features/household/presentation/providers/household_provider.dart'
    show membersStreamProvider;
