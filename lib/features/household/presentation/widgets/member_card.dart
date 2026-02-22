import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/core/theme/app_colors.dart';
import 'package:appli_recette/core/utils/string_utils.dart' as str_utils;
import 'package:flutter/material.dart';

/// Carte d'affichage d'un membre du foyer.
/// Affiche l'avatar (initiales), le nom, l'âge, et les boutons Modifier/Supprimer.
class MemberCard extends StatelessWidget {
  const MemberCard({
    required this.member,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Member member;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Membre: ${member.name}',
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: AppColors.primary,
            radius: 24,
            child: Text(
              str_utils.initials(member.name),
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            member.name,
            style: theme.textTheme.titleMedium,
          ),
          subtitle: member.age != null
              ? Text(
                  '${member.age} ans',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bouton Modifier
              Semantics(
                label: 'Modifier ${member.name}',
                button: true,
                child: IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  color: AppColors.textSecondary,
                  tooltip: 'Modifier',
                  constraints:
                      const BoxConstraints(minWidth: 48, minHeight: 48),
                ),
              ),
              // Bouton Supprimer
              Semantics(
                label: 'Supprimer ${member.name}',
                button: true,
                child: IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.error,
                  tooltip: 'Supprimer',
                  constraints:
                      const BoxConstraints(minWidth: 48, minHeight: 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
