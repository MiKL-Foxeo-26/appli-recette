import 'package:appli_recette/core/router/app_router.dart';
import 'package:appli_recette/features/recipes/presentation/providers/recipes_provider.dart';
import 'package:appli_recette/features/recipes/presentation/widgets/recipe_quick_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Écran de création d'une nouvelle recette (modale hors shell).
/// Accessible via le FAB depuis tous les onglets.
class NewRecipePage extends ConsumerStatefulWidget {
  const NewRecipePage({super.key});

  @override
  ConsumerState<NewRecipePage> createState() => _NewRecipePageState();
}

class _NewRecipePageState extends ConsumerState<NewRecipePage> {
  bool _isSaving = false;

  Future<void> _handleSave(RecipeFormData data) async {
    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(recipesNotifierProvider.notifier);
      await notifier.createRecipe(
        name: data.name,
        mealType: data.mealType,
        prepTimeMinutes: data.prepTimeMinutes,
        cookTimeMinutes: data.cookTimeMinutes,
        restTimeMinutes: data.restTimeMinutes,
      );

      if (mounted) {
        // Naviguer vers l'onglet Recettes après création
        context.go(AppRoutes.recipes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('« ${data.name} » ajoutée à ta collection !'),
            backgroundColor: const Color(0xFF6BAE75),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde : $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle recette'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
          tooltip: 'Annuler',
        ),
      ),
      body: RecipeQuickForm(
        onSave: _handleSave,
        isLoading: _isSaving,
      ),
    );
  }
}
