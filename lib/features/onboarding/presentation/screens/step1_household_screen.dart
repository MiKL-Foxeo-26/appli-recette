import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/core/theme/app_colors.dart';
import 'package:appli_recette/features/household/presentation/providers/household_provider.dart';
import 'package:appli_recette/features/planning/presentation/providers/planning_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Étape 1 de l'onboarding : création du/des membres du foyer.
///
/// Le bouton Suivant est désactivé tant qu'aucun membre n'a été créé.
class Step1HouseholdScreen extends ConsumerStatefulWidget {
  const Step1HouseholdScreen({required this.onNext, super.key});

  final VoidCallback onNext;

  @override
  ConsumerState<Step1HouseholdScreen> createState() =>
      _Step1HouseholdScreenState();
}

class _Step1HouseholdScreenState extends ConsumerState<Step1HouseholdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _addMember() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final ageText = _ageController.text.trim();
    final age = ageText.isNotEmpty ? int.tryParse(ageText) : null;

    setState(() => _isAdding = true);
    try {
      final notifier = ref.read(householdNotifierProvider.notifier);
      final id = await notifier.addMember(name: name, age: age);

      // Initialiser le planning type pour ce nouveau membre
      await ref
          .read(planningNotifierProvider.notifier)
          .initializeForNewMember(id);

      _nameController.clear();
      _ageController.clear();
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
    final members = ref.watch(membersStreamProvider).value ?? [];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Qui fait partie du foyer ?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoute au moins une personne pour commencer.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Formulaire d'ajout
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Prénom *',
                    hintText: 'Ex: Léa',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le prénom est requis';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Âge (optionnel)',
                    hintText: 'Ex: 32',
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _addMember(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isAdding ? null : _addMember,
                    icon: _isAdding
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                    label: const Text('Ajouter au foyer'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Liste des membres déjà créés
          if (members.isNotEmpty) ...[
            Text(
              'Membres ajoutés',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, i) {
                  final m = members[i];
                  return _MemberChip(member: m);
                },
              ),
            ),
          ] else
            const Expanded(child: SizedBox.shrink()),

          const SizedBox(height: 16),

          // Bouton Suivant
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed:
                  members.isNotEmpty ? widget.onNext : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.disabled,
              ),
              child: const Text('Suivant →'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberChip extends StatelessWidget {
  const _MemberChip({required this.member});
  final Member member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          child: Text(
            member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(member.name),
        subtitle: member.age != null ? Text('${member.age} ans') : null,
        trailing: const Icon(
          Icons.check_circle,
          color: AppColors.success,
        ),
      ),
    );
  }
}
