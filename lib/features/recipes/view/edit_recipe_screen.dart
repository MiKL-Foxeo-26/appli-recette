import 'dart:io';

import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/core/theme/app_colors.dart';
import 'package:appli_recette/core/utils/time_utils.dart';
import 'package:appli_recette/features/recipes/domain/repositories/ingredient_repository.dart';
import 'package:appli_recette/features/recipes/presentation/providers/recipes_provider.dart';
import 'package:appli_recette/features/recipes/presentation/widgets/recipe_quick_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

/// Écran d'édition complet d'une recette.
/// Pré-remplit tous les champs et sauvegarde en un seul appel.
class EditRecipeScreen extends ConsumerStatefulWidget {
  const EditRecipeScreen({required this.recipeId, super.key});

  final String recipeId;

  @override
  ConsumerState<EditRecipeScreen> createState() => _EditRecipeScreenState();
}

class _EditRecipeScreenState extends ConsumerState<EditRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _initialized = false;
  bool _isSaving = false;

  // Section 1
  final _nameController = TextEditingController();
  final _prepTimeController = TextEditingController(text: '0');
  final _cookTimeController = TextEditingController(text: '0');
  final _restTimeController = TextEditingController(text: '0');
  MealType? _selectedMealType;

  // Section 2
  String _season = 'all';
  bool _isVegetarian = false;
  final _servingsController = TextEditingController(text: '4');
  final List<_IngredientRow> _ingredients = [];

  // Section 3
  final _notesController = TextEditingController();
  final _variantsController = TextEditingController();
  final _sourceUrlController = TextEditingController();

  // Photo
  String? _photoPath;
  bool _isUploadingPhoto = false;

  int get _totalTime =>
      (int.tryParse(_prepTimeController.text) ?? 0) +
      (int.tryParse(_cookTimeController.text) ?? 0) +
      (int.tryParse(_restTimeController.text) ?? 0);

  @override
  void dispose() {
    _nameController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _restTimeController.dispose();
    _servingsController.dispose();
    _notesController.dispose();
    _variantsController.dispose();
    _sourceUrlController.dispose();
    for (final row in _ingredients) {
      row.dispose();
    }
    super.dispose();
  }

  void _initFromRecipe(Recipe recipe) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = recipe.name;
    _prepTimeController.text = recipe.prepTimeMinutes.toString();
    _cookTimeController.text = recipe.cookTimeMinutes.toString();
    _restTimeController.text = recipe.restTimeMinutes.toString();
    _selectedMealType = MealType.tryFromValue(recipe.mealType) ?? MealType.lunch;
    _season = recipe.season;
    _isVegetarian = recipe.isVegetarian;
    _servingsController.text = recipe.servings.toString();
    _notesController.text = recipe.notes ?? '';
    _variantsController.text = recipe.variants ?? '';
    _sourceUrlController.text = recipe.sourceUrl ?? '';
    _photoPath = recipe.photoPath;
  }

  void _initIngredients(List<Ingredient> ingredients) {
    if (_ingredients.isNotEmpty) return;
    for (final ing in ingredients) {
      _ingredients.add(_IngredientRow.fromIngredient(ing));
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final imageService = ref.read(imageServiceProvider);
    setState(() => _isUploadingPhoto = true);
    try {
      final path = source == ImageSource.camera
          ? await imageService.pickFromCamera()
          : await imageService.pickFromGallery();
      if (path != null) {
        // Supprimer l'ancienne photo pour éviter les fichiers orphelins
        if (_photoPath != null) {
          await imageService.deletePhoto(_photoPath!);
        }
        setState(() => _photoPath = path);
      }
    } finally {
      setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _showPhotoOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Prendre une photo'),
              onTap: () async {
                Navigator.of(ctx).pop();
                await _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir depuis la galerie'),
              onTap: () async {
                Navigator.of(ctx).pop();
                await _pickPhoto(ImageSource.gallery);
              },
            ),
            if (_photoPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Supprimer la photo',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() => _photoPath = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedMealType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionne un type de repas')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(recipesNotifierProvider.notifier);

      final ingInputs = _ingredients
          .where((r) => r.nameController.text.trim().isNotEmpty)
          .map(
            (r) => IngredientInput(
              name: r.nameController.text.trim(),
              quantity: double.tryParse(r.quantityController.text),
              unit: r.unitController.text.trim().isEmpty
                  ? null
                  : r.unitController.text.trim(),
              supermarketSection: r.sectionController.text.trim().isEmpty
                  ? null
                  : r.sectionController.text.trim(),
            ),
          )
          .toList();

      // Transaction atomique : recette + ingrédients
      await notifier.updateRecipeWithIngredients(
        id: widget.recipeId,
        name: _nameController.text.trim(),
        mealType: _selectedMealType!.value,
        prepTimeMinutes: int.tryParse(_prepTimeController.text) ?? 0,
        cookTimeMinutes: int.tryParse(_cookTimeController.text) ?? 0,
        restTimeMinutes: int.tryParse(_restTimeController.text) ?? 0,
        season: _season,
        isVegetarian: _isVegetarian,
        servings: int.tryParse(_servingsController.text) ?? 4,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        variants: _variantsController.text.trim().isEmpty
            ? null
            : _variantsController.text.trim(),
        sourceUrl: _sourceUrlController.text.trim().isEmpty
            ? null
            : _sourceUrlController.text.trim(),
        photoPath: _photoPath,
        ingredients: ingInputs,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recette mise à jour !')),
        );
        context.pop();
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipeAsync = ref.watch(recipeByIdProvider(widget.recipeId));
    final ingredientsAsync =
        ref.watch(ingredientsForRecipeProvider(widget.recipeId));

    return recipeAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: Center(child: Text('Erreur : $e')),
      ),
      data: (recipe) {
        if (recipe == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Recette introuvable')),
            body: const Center(child: Text("Cette recette n'existe plus.")),
          );
        }
        _initFromRecipe(recipe);

        return ingredientsAsync.when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Scaffold(
            appBar: AppBar(title: const Text('Erreur')),
            body: Center(child: Text('$e')),
          ),
          data: (ingredients) {
            _initIngredients(ingredients);
            return _buildForm(context);
          },
        );
      },
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier la recette'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enregistrer'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            // ─── Photo ──────────────────────────────────────────────────
            _PhotoSection(
              photoPath: _photoPath,
              isLoading: _isUploadingPhoto,
              onTap: _showPhotoOptions,
            ),
            const SizedBox(height: 24),

            // ─── Section 1 : Infos essentielles ─────────────────────────
            const _SectionHeader('Informations essentielles'),
            const SizedBox(height: 16),

            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nom de la recette *',
                prefixIcon: Icon(Icons.restaurant_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().length < 2) {
                  return 'Nom obligatoire (min. 2 caractères)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            Text('Type de repas *',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MealType.values.map((type) {
                final isSelected = _selectedMealType == type;
                return ChoiceChip(
                  label: Text(type.label),
                  avatar: Icon(type.icon,
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.textSecondary),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                  onSelected: (_) =>
                      setState(() => _selectedMealType = type),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _TimeField(
                    controller: _prepTimeController,
                    label: 'Préparation *',
                    required: true,
                    onChanged: (_) => setState(() {}),
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
            const SizedBox(height: 8),
            Text(
              'Temps total : ${formatTime(_totalTime)}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // ─── Section 2 : Enrichissement ──────────────────────────────
            const _SectionHeader('Détails de la recette'),
            const SizedBox(height: 16),

            // Saison
            Text('Saison',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ('all', 'Toute saison'),
                ('spring', 'Printemps'),
                ('summer', 'Été'),
                ('autumn', 'Automne'),
                ('winter', 'Hiver'),
              ].map((entry) {
                final isSelected = _season == entry.$1;
                return ChoiceChip(
                  label: Text(entry.$2),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                  onSelected: (_) => setState(() => _season = entry.$1),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Végétarien + Portions
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    value: _isVegetarian,
                    onChanged: (v) => setState(() => _isVegetarian = v),
                    title: const Text('Végétarien'),
                    secondary: const Icon(Icons.eco_outlined),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: _servingsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      labelText: 'Portions',
                      suffixText: 'pers.',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Ingrédients
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ingrédients',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _ingredients.add(_IngredientRow())),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._buildIngredientRows(context),
            const SizedBox(height: 24),

            // ─── Section 3 : Notes, variantes, URL ───────────────────────
            const _SectionHeader('Notes & Sources'),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesController,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notes libres',
                hintText: 'Instructions, étapes, conseils...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _variantsController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Variantes & astuces',
                hintText: 'Substitutions, variantes possibles...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _sourceUrlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'URL source',
                hintText: 'https://...',
                prefixIcon: Icon(Icons.link_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final url = v.trim();
                final uri = Uri.tryParse(
                  url.startsWith('http') ? url : 'https://$url',
                );
                if (uri == null || !uri.hasAuthority) {
                  return 'URL invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Enregistrer les modifications'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildIngredientRows(BuildContext context) {
    return List.generate(_ingredients.length, (i) {
      final row = _ingredients[i];
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            // Quantité
            SizedBox(
              width: 64,
              child: TextFormField(
                controller: row.quantityController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: 'Qté',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Unité
            SizedBox(
              width: 64,
              child: TextFormField(
                controller: row.unitController,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: 'Unité',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Nom
            Expanded(
              child: TextFormField(
                controller: row.nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: "Nom de l'ingrédient *",
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Rayon
            SizedBox(
              width: 80,
              child: TextFormField(
                controller: row.sectionController,
                decoration: const InputDecoration(
                  hintText: 'Rayon',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                ),
              ),
            ),
            // Supprimer
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              color: AppColors.textSecondary,
              onPressed: () => setState(() {
                _ingredients[i].dispose();
                _ingredients.removeAt(i);
              }),
            ),
          ],
        ),
      );
    });
  }

}

// ---------------------------------------------------------------------------
// Modèle d'une ligne ingrédient dans le formulaire
// ---------------------------------------------------------------------------

class _IngredientRow {
  _IngredientRow()
      : nameController = TextEditingController(),
        quantityController = TextEditingController(),
        unitController = TextEditingController(),
        sectionController = TextEditingController();

  _IngredientRow.fromIngredient(Ingredient ing)
      : nameController = TextEditingController(text: ing.name),
        quantityController = TextEditingController(
          text: ing.quantity != null ? _fmtQty(ing.quantity!) : '',
        ),
        unitController = TextEditingController(text: ing.unit ?? ''),
        sectionController = TextEditingController(
          text: ing.supermarketSection ?? '',
        );

  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController unitController;
  final TextEditingController sectionController;

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    unitController.dispose();
    sectionController.dispose();
  }

  static String _fmtQty(double qty) {
    return qty == qty.truncateToDouble()
        ? qty.toInt().toString()
        : qty.toString();
  }
}

// ---------------------------------------------------------------------------
// Widgets locaux
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
        const Divider(),
      ],
    );
  }
}

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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
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

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({
    required this.photoPath,
    required this.isLoading,
    required this.onTap,
  });

  final String? photoPath;
  final bool isLoading;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async => onTap(),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          image: photoPath != null
              ? DecorationImage(
                  image: FileImage(File(photoPath!)),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : photoPath == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_a_photo_outlined,
                        size: 40,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ajouter une photo',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  )
                : const Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.black54,
                        child: Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}
