import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/features/planning/presentation/providers/planning_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Labels des jours de la semaine (1=Lun, 7=Dim).
const _dayLabels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

/// Labels des repas.
const _mealLabels = {'lunch': 'M', 'dinner': 'S'};

/// Couleur de fond pour les cellules override.
const _overrideBackground = Color(0xFFFFF8E1);

/// Grille de toggles de présence : membres en lignes, jours × repas en colonnes.
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

  /// Ensemble de clés "memberId|dayOfWeek|mealSlot" identifiant les créneaux override.
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 4,
        horizontalMargin: 8,
        headingRowHeight: 56,
        dataRowMinHeight: 48,
        dataRowMaxHeight: 56,
        columns: [
          const DataColumn(label: SizedBox(width: 72)),
          for (var day = 0; day < 7; day++) ...[
            DataColumn(
              label: _DayHeader(
                dayLabel: _dayLabels[day],
                mealLabel: _mealLabels['lunch']!,
              ),
            ),
            DataColumn(
              label: _DayHeader(
                dayLabel: day == 0 ? '' : '',
                mealLabel: _mealLabels['dinner']!,
                showDay: false,
              ),
            ),
          ],
        ],
        rows: members.map((member) {
          return DataRow(
            cells: [
              DataCell(
                SizedBox(
                  width: 72,
                  child: Text(
                    member.name,
                    style: theme.textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              for (var day = 1; day <= 7; day++) ...[
                for (final slot in ['lunch', 'dinner'])
                  DataCell(
                    Semantics(
                      label:
                          'Présence de ${member.name} — ${_dayLabels[day - 1]} ${slot == "lunch" ? "midi" : "soir"}',
                      child: _PresenceCell(
                        isPresent: _isPresent(member.id, day, slot),
                        isOverride: _isOverride(member.id, day, slot),
                        primaryColor: primaryColor,
                        onToggle: () {
                          if (weekKey != null) {
                            ref
                                .read(planningNotifierProvider.notifier)
                                .toggleWeeklyPresence(
                                  weekKey: weekKey!,
                                  memberId: member.id,
                                  dayOfWeek: day,
                                  mealSlot: slot,
                                );
                          } else {
                            ref
                                .read(planningNotifierProvider.notifier)
                                .togglePresence(
                                  memberId: member.id,
                                  dayOfWeek: day,
                                  mealSlot: slot,
                                );
                          }
                        },
                      ),
                    ),
                  ),
              ],
            ],
          );
        }).toList(),
      ),
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

/// En-tête de colonne avec jour abrégé + repas.
class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.dayLabel,
    required this.mealLabel,
    this.showDay = true,
  });

  final String dayLabel;
  final String mealLabel;
  final bool showDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 36,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDay && dayLabel.isNotEmpty)
            Text(
              dayLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          Text(
            mealLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
