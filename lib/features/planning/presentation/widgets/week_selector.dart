import 'package:appli_recette/features/planning/data/utils/week_utils.dart';
import 'package:appli_recette/features/planning/presentation/providers/planning_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Sélecteur de semaine avec navigation et affichage "Semaine du X au Y".
///
/// Limites : N-2 à N+8 semaines depuis la semaine courante.
class WeekSelector extends ConsumerWidget {
  const WeekSelector({super.key});

  static const _minOffset = -2;
  static const _maxOffset = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final String weekKey = ref.watch(selectedWeekKeyProvider);
    final current = currentWeekKey();

    final minWeekKey = weekKeyOffset(current, _minOffset);
    final maxWeekKey = weekKeyOffset(current, _maxOffset);

    final range = weekKeyToDateRange(weekKey);
    final dateFmt = DateFormat('d MMM', 'fr_FR');
    final label = 'Semaine du ${dateFmt.format(range.monday)}'
        ' au ${dateFmt.format(range.sunday)}';

    final canGoBack = weekKey != minWeekKey;
    final canGoForward = weekKey != maxWeekKey;
    final isCurrentWeek = weekKey == current;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: canGoBack
                  ? () => ref
                      .read(selectedWeekKeyProvider.notifier)
                      .select(weekKeyOffset(weekKey, -1))
                  : null,
              tooltip: 'Semaine précédente',
            ),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _showWeekPicker(context, ref, current),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                child: Text(label, style: theme.textTheme.titleSmall),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: canGoForward
                  ? () => ref
                      .read(selectedWeekKeyProvider.notifier)
                      .select(weekKeyOffset(weekKey, 1))
                  : null,
              tooltip: 'Semaine suivante',
            ),
          ],
        ),
        if (isCurrentWeek)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Cette semaine',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showWeekPicker(
    BuildContext context,
    WidgetRef ref,
    String currentWk,
  ) async {
    final now = DateTime.now();
    final minRange =
        weekKeyToDateRange(weekKeyOffset(currentWk, _minOffset));
    final maxRange =
        weekKeyToDateRange(weekKeyOffset(currentWk, _maxOffset));

    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: minRange.monday,
      lastDate: maxRange.sunday,
      locale: const Locale('fr', 'FR'),
    );

    if (picked != null) {
      ref
          .read(selectedWeekKeyProvider.notifier)
          .select(dateToWeekKey(picked));
    }
  }
}
