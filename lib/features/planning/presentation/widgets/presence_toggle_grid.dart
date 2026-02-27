import 'dart:async';

import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/core/theme/app_colors.dart';
import 'package:appli_recette/features/planning/presentation/providers/planning_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Labels complets des jours de la semaine (1=Lun, 7=Dim).
const _dayLabelsFull = [
  'LUNDI',
  'MARDI',
  'MERCREDI',
  'JEUDI',
  'VENDREDI',
  'SAMEDI',
  'DIMANCHE',
];

/// Couleur de fond pour les cellules override.
const _overrideBackground = Color(0xFFFFF8E1);

/// Hauteurs fixes pour aligner les deux côtés.
const _headerHeight = 36.0;
const _dayBannerHeight = 28.0;
const _mealRowHeight = 40.0;
const _dividerHeight = 1.0;

/// Grille de toggles de présence : jours en lignes, membres en colonnes.
///
/// Supporte deux modes :
/// - Planning type ([weekKey] == null) : modifie le planning type
/// - Semaine spécifique ([weekKey] non null) : crée/modifie des overrides
class PresenceToggleGrid extends ConsumerWidget {
  const PresenceToggleGrid({
    required this.members,
    required this.presences,
    this.weekKey,
    this.overrideSlots = const {},
    super.key,
  });

  final List<Member> members;
  final List<PresenceSchedule> presences;

  /// Si non null, la grille opère en mode semaine (overrides).
  final String? weekKey;

  /// Ensemble de clés "memberId|dayOfWeek|mealSlot" identifiant
  /// les créneaux override.
  final Set<String> overrideSlots;

  /// Retrouve si un membre est présent pour un créneau donné.
  bool _isPresent(String memberId, int dayOfWeek, String mealSlot) {
    return presences.any(
      (p) =>
          p.memberId == memberId &&
          p.dayOfWeek == dayOfWeek &&
          p.mealSlot == mealSlot &&
          p.isPresent,
    );
  }

  /// Vérifie si un créneau est un override.
  bool _isOverride(String memberId, int dayOfWeek, String mealSlot) {
    return overrideSlots.contains('$memberId|$dayOfWeek|$mealSlot');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    // Colonne fixe (labels) + colonnes scrollables (membres)
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Colonne fixe : labels jours/repas
        _buildFixedLabelColumn(theme),

        // Colonnes membres : scroll horizontal avec scrollbar
        Expanded(
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildMembersTable(
                ref: ref,
                theme: theme,
                primaryColor: primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Colonne fixe avec les labels jours et repas.
  Widget _buildFixedLabelColumn(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header vide (aligné avec les prénoms)
        const SizedBox(height: _headerHeight),

        for (var dayIndex = 0; dayIndex < 7; dayIndex++) ...[
          // Bande header jour
          Container(
            width: 88,
            height: _dayBannerHeight,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: AppColors.primaryLight
                .withValues(alpha: 0.35),
            child: Text(
              _dayLabelsFull[dayIndex],
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // Label Midi
          Container(
            width: 88,
            height: _mealRowHeight,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: AppColors.midiBackground,
            child: Text(
              '☀️ Midi',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),

          // Label Soir
          Container(
            width: 88,
            height: _mealRowHeight,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: AppColors.soirBackground,
            child: Text(
              '🌙 Soir',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),

          // Séparateur
          if (dayIndex < 6)
            const SizedBox(
              width: 88,
              height: _dividerHeight,
              child: ColoredBox(color: AppColors.divider),
            ),
        ],
      ],
    );
  }

  /// Table scrollable avec les colonnes des membres.
  Widget _buildMembersTable({
    required WidgetRef ref,
    required ThemeData theme,
    required Color primaryColor,
  }) {
    final memberColWidths = <int, TableColumnWidth>{
      for (var i = 0; i < members.length; i++)
        i: const FixedColumnWidth(56),
    };

    return Table(
      columnWidths: memberColWidths,
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        // Header : prénoms
        TableRow(
          children: [
            for (final member in members)
              SizedBox(
                height: _headerHeight,
                child: Center(
                  child: Text(
                    member.name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),

        for (var dayIndex = 0; dayIndex < 7; dayIndex++) ...[
          // Bande jour (cellules vides colorées)
          TableRow(
            decoration: BoxDecoration(
              color: AppColors.primaryLight
                  .withValues(alpha: 0.35),
            ),
            children: [
              for (var i = 0; i < members.length; i++)
                const SizedBox(height: _dayBannerHeight),
            ],
          ),

          // Ligne Midi
          _buildMealRow(
            ref: ref,
            theme: theme,
            primaryColor: primaryColor,
            dayOfWeek: dayIndex + 1,
            mealSlot: 'lunch',
            backgroundColor: AppColors.midiBackground,
          ),

          // Ligne Soir
          _buildMealRow(
            ref: ref,
            theme: theme,
            primaryColor: primaryColor,
            dayOfWeek: dayIndex + 1,
            mealSlot: 'dinner',
            backgroundColor: AppColors.soirBackground,
          ),

          // Séparateur
          if (dayIndex < 6)
            TableRow(
              children: [
                for (var i = 0; i < members.length; i++)
                  const SizedBox(
                    height: _dividerHeight,
                    child: ColoredBox(color: AppColors.divider),
                  ),
              ],
            ),
        ],
      ],
    );
  }

  /// Construit une ligne de repas (midi ou soir) pour un jour donné.
  TableRow _buildMealRow({
    required WidgetRef ref,
    required ThemeData theme,
    required Color primaryColor,
    required int dayOfWeek,
    required String mealSlot,
    required Color backgroundColor,
  }) {
    return TableRow(
      decoration: BoxDecoration(color: backgroundColor),
      children: [
        for (final member in members)
          SizedBox(
            height: _mealRowHeight,
            child: Semantics(
              label: 'Présence de ${member.name}'
                  ' — ${_dayLabelsFull[dayOfWeek - 1]}'
                  ' ${mealSlot == "lunch" ? "midi" : "soir"}',
              child: _PresenceCell(
              isPresent: _isPresent(
                member.id,
                dayOfWeek,
                mealSlot,
              ),
              isOverride: _isOverride(
                member.id,
                dayOfWeek,
                mealSlot,
              ),
              primaryColor: primaryColor,
              onToggle: () {
                if (weekKey != null) {
                  unawaited(
                    ref
                        .read(planningNotifierProvider.notifier)
                        .toggleWeeklyPresence(
                          weekKey: weekKey!,
                          memberId: member.id,
                          dayOfWeek: dayOfWeek,
                          mealSlot: mealSlot,
                        ),
                  );
                } else {
                  unawaited(
                    ref
                        .read(planningNotifierProvider.notifier)
                        .togglePresence(
                          memberId: member.id,
                          dayOfWeek: dayOfWeek,
                          mealSlot: mealSlot,
                        ),
                  );
                }
              },
            ),
          ),
          ),
      ],
    );
  }
}

/// Cellule de présence avec distinction visuelle pour les overrides.
class _PresenceCell extends StatelessWidget {
  const _PresenceCell({
    required this.isPresent,
    required this.isOverride,
    required this.primaryColor,
    required this.onToggle,
  });

  final bool isPresent;
  final bool isOverride;
  final Color primaryColor;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: isOverride
          ? BoxDecoration(
              color: _overrideBackground,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.4),
              ),
            )
          : null,
      child: Checkbox(
        value: isPresent,
        activeColor: primaryColor,
        onChanged: (_) => onToggle(),
      ),
    );
  }
}
