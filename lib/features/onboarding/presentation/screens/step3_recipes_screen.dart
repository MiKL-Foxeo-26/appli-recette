import 'package:appli_recette/core/constants/generation_constants.dart';
import 'package:appli_recette/core/theme/app_colors.dart';
import 'package:appli_recette/features/recipes/presentation/providers/recipes_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Étape 3 de l'onboarding : ajout des premières recettes.
///
/// Affiche un formulaire simplifié + compteur "X/3 recettes".
/// Le bouton Terminer est actif dès qu'au moins 1 recette a été ajoutée.
class Step3RecipesScreen extends ConsumerStatefulWidget {
  const Step3RecipesScreen({
    required this.onComplete,
    required this.onPrevious,
    super.key,
  });

  final VoidCallback onComplete;
  final VoidCallback onPrevious;

  @override
  ConsumerState<Step3RecipesScreen> createState() =>
      _Step3RecipesScreenState();
}

class _Step3RecipesScreenState extends ConsumerState<Step3RecipesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedMealType = 'lunch';
  bool _isAdding = false;

  /// Seuls lunch et dinner sont utilisés par l'algorithme de génération
  /// (14 créneaux = 7 jours × 2 repas). Les autres types ne seraient
  /// jamais sélectionnés, donnant une mauvaise première expérience.
  static const _mealTypes = [
    ('lunch', 'Déjeuner'),
    ('dinner', 'Dîner'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    setState(() => _isAdding = true);
    try {
      await ref.read(recipesNotifierProvider.notifier).createRecipe(
            name: name,
            mealType: _selectedMealType,
            prepTimeMinutes: 15, // Défaut raisonnable pour l'onboarding
          );
      _nameController.clear();
      _formKey.currentState?.reset();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipes = ref.watch(recipesStreamProvider).value ?? [];
    final count = recipes.length;
    final remaining = (kMinRecipesForGeneration - count).clamp(0, kMinRecipesForGeneration);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tes premières recettes',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$kMinRecipesForGeneration recettes suffisent pour générer ton premier menu !',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Compteur de progression
          _RecipeProgressBanner(count: count),
          const SizedBox(height: 16),

          // Formulaire d'ajout rapide
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la recette *',
                    hintText: 'Ex: Pâtes bolognaise',
                    prefixIcon: Icon(Icons.restaurant_menu_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le nom est requis';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _addRecipe(),
                ),
                const SizedBox(height: 12),

                // Type de repas
                DropdownButtonFormField<String>(
                  value: _selectedMealType,
                  decoration: const InputDecoration(
                    labelText: 'Type de repas',
                    prefixIcon: Icon(Icons.schedule_outlined),
                  ),
                  items: _mealTypes
                      .map(
                        (t) => DropdownMenuItem(
                          value: t.$1,
                          child: Text(t.$2),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedMealType = v);
                  },
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isAdding ? null : _addRecipe,
                    icon: _isAdding
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                    label: const Text('Ajouter cette recette'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Recettes ajoutées
          if (recipes.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: recipes.length,
                itemBuilder: (context, i) {
                  final r = recipes[i];
                  return ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 20,
                    ),
                    title: Text(
                      r.name,
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                },
              ),
            )
          else
            const Expanded(child: SizedBox.shrink()),

          const SizedBox(height: 12),

          // Message d'encouragement si < 3 recettes
          if (remaining > 0 && count > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                remaining == 1
                    ? 'Plus qu\'1 recette pour débloquer la génération !'
                    : 'Encore $remaining recettes pour débloquer la génération.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // Boutons navigation
          Row(
            children: [
              TextButton.icon(
                onPressed: widget.onPrevious,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour'),
              ),
              const Spacer(),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: count >= 1 ? widget.onComplete : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.disabled,
                    ),
                    child: Text(
                      count >= kMinRecipesForGeneration
                          ? 'Terminer et générer !'
                          : 'Terminer',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Banner affichant la progression "X/3 recettes".
class _RecipeProgressBanner extends StatelessWidget {
  const _RecipeProgressBanner({required this.count});

  final int count;
  static const _target = kMinRecipesForGeneration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (count / _target).clamp(0.0, 1.0);
    final isComplete = count >= _target;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isComplete
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.primaryLight.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isComplete ? AppColors.success : AppColors.primaryLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$count / $_target recettes',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isComplete ? AppColors.success : AppColors.primary,
                ),
              ),
              Icon(
                isComplete ? Icons.lock_open : Icons.lock_outline,
                size: 18,
                color: isComplete ? AppColors.success : AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(
              isComplete ? AppColors.success : AppColors.primary,
            ),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          if (isComplete) ...[
            const SizedBox(height: 6),
            Text(
              'Génération débloquée !',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
