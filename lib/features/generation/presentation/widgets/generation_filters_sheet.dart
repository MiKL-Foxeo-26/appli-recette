import 'package:appli_recette/core/theme/app_colors.dart';
import 'package:appli_recette/features/generation/domain/models/generation_filters.dart';
import 'package:appli_recette/features/recipes/domain/models/season.dart';
import 'package:flutter/material.dart';

/// Bottom sheet Material 3 pour configurer les filtres de génération.
///
/// Affiche :
/// - Slider temps de préparation max (0–120 min)
/// - Switch végétarien
/// - Chips saison exclusifs
class GenerationFiltersSheet extends StatefulWidget {
  const GenerationFiltersSheet({
    super.key,
    this.initialFilters,
    this.onApply,
  });

  /// Filtres actuellement actifs (pré-remplis à l'ouverture).
  final GenerationFilters? initialFilters;

  /// Appelé avec les nouveaux filtres quand l'utilisateur tape "Appliquer".
  final void Function(GenerationFilters filters)? onApply;

  @override
  State<GenerationFiltersSheet> createState() => _GenerationFiltersSheetState();
}

class _GenerationFiltersSheetState extends State<GenerationFiltersSheet> {
  late double _prepTime;
  late bool _vegetarianOnly;
  late Season? _season;

  @override
  void initState() {
    super.initState();
    final f = widget.initialFilters;
    _prepTime = (f?.maxPrepTimeMinutes ?? 0).toDouble();
    _vegetarianOnly = f?.vegetarianOnly ?? false;
    _season = f?.season;
  }

  void _reset() {
    setState(() {
      _prepTime = 0;
      _vegetarianOnly = false;
      _season = null;
    });
  }

  void _apply() {
    final filters = GenerationFilters(
      maxPrepTimeMinutes: _prepTime > 0 ? _prepTime.toInt() : null,
      vegetarianOnly: _vegetarianOnly,
      season: _season,
    );
    widget.onApply?.call(filters);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── DragHandle ──
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Titre ──
            Text(
              'Filtres de génération',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),

            // ── Slider temps de préparation ──
            Text(
              'Temps de préparation maximum',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _prepTime,
                    min: 0,
                    max: 120,
                    divisions: 24,
                    activeColor: AppColors.primary,
                    label: _prepTime == 0
                        ? 'Pas de limite'
                        : '${_prepTime.toInt()} min',
                    onChanged: (v) => setState(() => _prepTime = v),
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Text(
                    _prepTime == 0
                        ? 'Pas de limite'
                        : '${_prepTime.toInt()} min',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Switch végétarien ──
            SwitchListTile(
              title: const Text('Végétarien uniquement'),
              value: _vegetarianOnly,
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() => _vegetarianOnly = v),
            ),
            const SizedBox(height: 16),

            // ── Chips saison ──
            Text(
              'Saison',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                Season.spring,
                Season.summer,
                Season.autumn,
                Season.winter,
              ].map((s) {
                final selected = _season == s;
                return FilterChip(
                  label: Text(s.label),
                  selected: selected,
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.primary,
                  onSelected: (_) {
                    setState(() => _season = selected ? null : s);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── Boutons ──
            Row(
              children: [
                TextButton(
                  onPressed: _reset,
                  child: const Text('Réinitialiser'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _apply,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Appliquer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
