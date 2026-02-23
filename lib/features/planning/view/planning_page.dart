import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/core/providers/member_providers.dart';
import 'package:appli_recette/features/planning/presentation/providers/planning_provider.dart';
import 'package:appli_recette/features/planning/presentation/widgets/presence_toggle_grid.dart';
import 'package:appli_recette/features/planning/presentation/widgets/week_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Écran principal du planning de présence.
///
/// Deux modes via SegmentedButton :
/// - **Planning type** : présences par défaut (Story 4.1)
/// - **Semaine** : overrides hebdomadaires (Story 4.2)
class PlanningPage extends ConsumerStatefulWidget {
  const PlanningPage({super.key});

  @override
  ConsumerState<PlanningPage> createState() => _PlanningPageState();
}

enum _PlanningMode { type, week }

class _PlanningPageState extends ConsumerState<PlanningPage> {
  _PlanningMode _mode = _PlanningMode.type;

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planning de présence'),
      ),
      body: membersAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Erreur de chargement : $error',
            style: theme.textTheme.bodyLarge,
          ),
        ),
        data: (members) {
          if (members.isEmpty) {
            return _EmptyMembersState(theme: theme);
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: SegmentedButton<_PlanningMode>(
                  segments: const [
                    ButtonSegment(
                      value: _PlanningMode.type,
                      label: Text('Planning type'),
                      icon: Icon(Icons.calendar_today),
                    ),
                    ButtonSegment(
                      value: _PlanningMode.week,
                      label: Text('Semaine'),
                      icon: Icon(Icons.date_range),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (selected) {
                    setState(() => _mode = selected.first);
                  },
                ),
              ),
              Expanded(
                child: _mode == _PlanningMode.type
                    ? _DefaultModeContent(
                        members: members,
                      )
                    : _WeekModeContent(members: members),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyMembersState extends StatelessWidget {
  const _EmptyMembersState({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Ajoute les membres de ton foyer',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Le planning nécessite au moins un membre.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go('/household'),
              icon: const Icon(Icons.people),
              label: const Text('Aller au Foyer'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mode Planning type (Story 4.1).
class _DefaultModeContent extends ConsumerStatefulWidget {
  const _DefaultModeContent({
    required this.members,
  });

  final List<Member> members;

  @override
  ConsumerState<_DefaultModeContent> createState() =>
      _DefaultModeContentState();
}

class _DefaultModeContentState extends ConsumerState<_DefaultModeContent> {
  bool _initTriggered = false;
  bool _initError = false;

  @override
  Widget build(BuildContext context) {
    final presencesAsync = ref.watch(defaultPresencesStreamProvider);
    final theme = Theme.of(context);

    return presencesAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text('Erreur : $error')),
      data: (presences) {
        if (!_initTriggered) {
          _initTriggered = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            try {
              await ref
                  .read(planningNotifierProvider.notifier)
                  .initializeMissingMembers(widget.members);
            } catch (e) {
              if (mounted) {
                setState(() => _initError = true);
              }
            }
          });
        }

        if (presences.isEmpty && !_initError) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (presences.isEmpty && _initError) {
          return Center(
            child: Text(
              'Erreur lors de l\'initialisation des présences.',
              style: theme.textTheme.bodyLarge,
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Planning type',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Définis qui est présent par défaut.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              PresenceToggleGrid(
                members: widget.members,
                presences: presences,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Mode Semaine avec overrides (Story 4.2).
class _WeekModeContent extends ConsumerWidget {
  const _WeekModeContent({required this.members});

  final List<Member> members;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekKey = ref.watch(selectedWeekKeyProvider);
    final mergedAsync =
        ref.watch(mergedPresencesStreamProvider(weekKey));
    final overridesAsync =
        ref.watch(weeklyOverridesStreamProvider(weekKey));

    return mergedAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text('Erreur : $error')),
      data: (mergedPresences) {
        if (mergedPresences.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Aucune présence configurée pour cette semaine.\n'
                'Configure d\'abord le planning type.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        // Construire le set des créneaux override
        final overrideSlots = <String>{};
        if (overridesAsync case AsyncData(:final value)) {
          for (final o in value) {
            overrideSlots.add(
              '${o.memberId}|${o.dayOfWeek}|${o.mealSlot}',
            );
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const WeekSelector(),
              const SizedBox(height: 12),
              PresenceToggleGrid(
                members: members,
                presences: mergedPresences,
                weekKey: weekKey,
                overrideSlots: overrideSlots,
              ),
              if (overrideSlots.isNotEmpty) ...[
                const SizedBox(height: 16),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref
                          .read(
                            planningNotifierProvider.notifier,
                          )
                          .resetWeekToDefault(
                            weekKey: weekKey,
                          );
                    },
                    icon: const Icon(Icons.restore),
                    label: const Text(
                      'Réinitialiser à planning type',
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
