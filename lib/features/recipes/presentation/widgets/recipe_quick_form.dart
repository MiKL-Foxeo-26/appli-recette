import 'package:appli_recette/core/theme/app_colors.dart';
import 'package:appli_recette/core/utils/time_utils.dart';
import 'package:appli_recette/features/recipes/domain/models/meal_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

export 'package:appli_recette/features/recipes/domain/models/meal_type.dart';

/// Données du formulaire de création recette (Section 1).
class RecipeFormData {
  const RecipeFormData({
    required this.name,
    required this.mealType,
    required this.prepTimeMinutes,
    this.cookTimeMinutes = 0,
    this.restTimeMinutes = 0,
  });

  final String name;
  final String mealType;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final int restTimeMinutes;

  int get totalTimeMinutes =>
      prepTimeMinutes + cookTimeMinutes + restTimeMinutes;
}

/// Formulaire progressif de création de recette — Section 1 obligatoire.
/// Champs : nom, type de repas (chips), temps préparation, cuisson, repos.
/// Le temps total est calculé automatiquement.
class RecipeQuickForm extends StatefulWidget {
  const RecipeQuickForm({
    required this.onSave,
    this.isLoading = false,
    super.key,
  });

  /// Callback appelé à la validation avec les données du formulaire.
  final void Function(RecipeFormData data) onSave;

  /// Affiche un état de chargement sur le bouton Sauvegarder.
  final bool isLoading;

  @override
  State<RecipeQuickForm> createState() => _RecipeQuickFormState();
}

class _RecipeQuickFormState extends State<RecipeQuickForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _prepTimeController = TextEditingController(text: '15');
  final _cookTimeController = TextEditingController(text: '0');
  final _restTimeController = TextEditingController(text: '0');

  MealType? _selectedMealType;

  int get _prepTime => int.tryParse(_prepTimeController.text) ?? 0;
  int get _cookTime => int.tryParse(_cookTimeController.text) ?? 0;
  int get _restTime => int.tryParse(_restTimeController.text) ?? 0;
  int get _totalTime => _prepTime + _cookTime + _restTime;

  @override
  void dispose() {
    _nameController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _restTimeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedMealType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sélectionne un type de repas'),
          ),
        );
        return;
      }
      widget.onSave(
        RecipeFormData(
          name: _nameController.text.trim(),
          mealType: _selectedMealType!.value,
          prepTimeMinutes: _prepTime,
          cookTimeMinutes: _cookTime,
          restTimeMinutes: _restTime,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // ─── Section 1 : Nom de la recette ───────────────────────────
          Text(
            'Informations essentielles',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),

          // Nom
          TextFormField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nom de la recette *',
              hintText: 'Ex. Poulet rôti aux herbes',
              prefixIcon: Icon(Icons.restaurant_outlined),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Le nom est obligatoire';
              }
              if (v.trim().length < 2) {
                return 'Le nom doit contenir au moins 2 caractères';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // ─── Type de repas ────────────────────────────────────────────
          Text(
            'Type de repas *',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MealType.values.map((type) {
              final isSelected = _selectedMealType == type;
              return ChoiceChip(
                label: Text(type.label),
                avatar: Icon(
                  type.icon,
                  size: 18,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                labelStyle: theme.textTheme.labelMedium?.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
                onSelected: (_) {
                  setState(() => _selectedMealType = type);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // ─── Temps ────────────────────────────────────────────────────
          Text(
            'Temps',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _TimeField(
                  controller: _prepTimeController,
                  label: 'Préparation *',
                  onChanged: (_) => setState(() {}),
                  required: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeField(
                  controller: _cookTimeController,
                  label: 'Cuisson',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeField(
                  controller: _restTimeController,
                  label: 'Repos',
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Temps total calculé
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Temps total : ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  formatTime(_totalTime),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ─── Bouton Sauvegarder ───────────────────────────────────────
          ElevatedButton(
            onPressed: widget.isLoading ? null : _submit,
            child: widget.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Sauvegarder la recette'),
          ),
        ],
      ),
    );
  }

}

/// Champ de saisie de temps (en minutes).
class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.controller,
    required this.label,
    required this.onChanged,
    this.required = false,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: label,
        suffixText: 'min',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 14,
        ),
      ),
      onChanged: onChanged,
      validator: required
          ? (v) {
              if (v == null || v.isEmpty) return 'Requis';
              final val = int.tryParse(v);
              if (val == null || val < 0) return 'Invalide';
              return null;
            }
          : null,
    );
  }
}
