import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/core/theme/app_colors.dart';
import 'package:appli_recette/features/household/presentation/providers/household_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Formulaire de création ou d'édition d'un membre du foyer.
///
/// - [member] == null → mode création
/// - [member] != null → mode édition (champs pré-remplis)
class MemberFormPage extends ConsumerStatefulWidget {
  const MemberFormPage({this.member, super.key});

  final Member? member;

  @override
  ConsumerState<MemberFormPage> createState() => _MemberFormPageState();
}

class _MemberFormPageState extends ConsumerState<MemberFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  bool _isLoading = false;

  bool get _isEditing => widget.member != null;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.member?.name ?? '');
    _ageController = TextEditingController(
      text: widget.member?.age?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final ageText = _ageController.text.trim();
    final age = ageText.isNotEmpty ? int.tryParse(ageText) : null;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(householdNotifierProvider.notifier);
      if (_isEditing) {
        await notifier.updateMember(
          id: widget.member!.id,
          name: name,
          age: age,
        );
      } else {
        await notifier.addMember(name: name, age: age);
      }
      if (mounted) context.pop();
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier le membre' : 'Nouveau membre'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Champ Nom (obligatoire)
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Prénom *',
                hintText: 'Ex: Léonard',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le prénom est requis';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
              autofocus: !_isEditing,
            ),
            const SizedBox(height: 16),

            // Champ Âge (optionnel)
            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Âge',
                hintText: 'Ex: 11 (optionnel)',
              ),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final age = int.tryParse(value.trim());
                  if (age == null || age <= 0) {
                    return 'L\'âge doit être un entier positif';
                  }
                }
                return null;
              },
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 32),

            // Bouton Enregistrer
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Enregistrer',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Bouton Annuler
            SizedBox(
              height: 48,
              child: TextButton(
                onPressed: _isLoading ? null : () => context.pop(),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
                child: const Text('Annuler'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
