import 'package:appli_recette/core/auth/auth_provider.dart';
import 'package:appli_recette/core/auth/household_auth_service.dart';
import 'package:appli_recette/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mode d'utilisation de [HouseholdCodeScreen].
enum HouseholdCodeMode { create, join }

/// Écran de création ou de jointure d'un foyer via Code Foyer 6 chiffres.
///
/// En mode [HouseholdCodeMode.create] : génère et affiche le code.
/// En mode [HouseholdCodeMode.join] : saisie du code par l'utilisateur.
///
/// [onDone] est appelé après une opération réussie (ou après "Passer").
class HouseholdCodeScreen extends ConsumerStatefulWidget {
  const HouseholdCodeScreen({
    required this.mode,
    required this.onDone,
    super.key,
  });

  final HouseholdCodeMode mode;
  final VoidCallback onDone;

  @override
  ConsumerState<HouseholdCodeScreen> createState() =>
      _HouseholdCodeScreenState();
}

class _HouseholdCodeScreenState extends ConsumerState<HouseholdCodeScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _generatedCode; // null = pas encore créé

  bool get _isCreateMode => widget.mode == HouseholdCodeMode.create;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _createHousehold() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(householdAuthServiceProvider);
      final code = await service.createHousehold();
      if (mounted) setState(() => _generatedCode = code);
      // Invalider le provider pour que l'UI réactive se mette à jour
      ref.invalidate(currentHouseholdIdProvider);
    } catch (e) {
      if (mounted) _showError('Erreur lors de la création : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinHousehold() async {
    final code = _codeController.text.trim();
    setState(() => _isLoading = true);
    try {
      final service = ref.read(householdAuthServiceProvider);
      await service.joinHousehold(code);
      ref.invalidate(currentHouseholdIdProvider);
      widget.onDone();
    } on InvalidCodeFormatException {
      if (mounted) {
        _showError('Format invalide — saisis exactement 6 chiffres.');
      }
    } on HouseholdNotFoundException {
      if (mounted) {
        _showError(
          'Code invalide. Vérifie le code partagé par ton foyer.',
        );
      }
    } catch (e) {
      if (mounted) _showError('Erreur lors de la jointure : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _copyCode() {
    if (_generatedCode == null) return;
    Clipboard.setData(ClipboardData(text: _generatedCode!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code copié dans le presse-papier')),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          _isCreateMode ? 'Code Foyer' : 'Rejoindre un foyer',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isCreateMode ? _buildCreateBody(theme) : _buildJoinBody(theme),
        ),
      ),
    );
  }

  // ── Create mode ────────────────────────────────────────────────────────────

  Widget _buildCreateBody(ThemeData theme) {
    if (_generatedCode != null) {
      return _buildCodeDisplay(theme, _generatedCode!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Icon(Icons.home_outlined, size: 64, color: AppColors.primary),
        const SizedBox(height: 24),
        Text(
          'Créer un Code Foyer',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Génère un code à 6 chiffres à partager avec ton partenaire '
          'pour synchroniser vos recettes et menus.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: _isLoading ? null : _createHousehold,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.add_home_outlined),
            label: const Text('Créer mon foyer'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isLoading ? null : widget.onDone,
          child: Text(
            'Passer — continuer sans code foyer',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeDisplay(ThemeData theme, String code) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
        const SizedBox(height: 24),
        Text(
          'Foyer créé !',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Partage ce code avec ton partenaire :',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Code display
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary),
          ),
          child: Text(
            code,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),

        OutlinedButton.icon(
          onPressed: _copyCode,
          icon: const Icon(Icons.copy_outlined, size: 18),
          label: const Text('Copier le code'),
        ),
        const Spacer(),

        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: widget.onDone,
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Continuer'),
          ),
        ),
      ],
    );
  }

  // ── Join mode ──────────────────────────────────────────────────────────────

  Widget _buildJoinBody(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Icon(Icons.group_add_outlined, size: 64, color: AppColors.primary),
        const SizedBox(height: 24),
        Text(
          'Rejoindre un foyer',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Saisis le Code Foyer à 6 chiffres partagé par ton foyer.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Code input
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _codeController,
          builder: (context, value, _) {
            return TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: '000000',
                hintStyle: theme.textTheme.headlineMedium?.copyWith(
                  letterSpacing: 8,
                  color: AppColors.disabled,
                ),
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
        ),
        const Spacer(),

        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _codeController,
          builder: (context, value, _) {
            final isValid = value.text.length == 6;
            return SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: (_isLoading || !isValid) ? null : _joinHousehold,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.login_outlined),
                label: const Text('Rejoindre'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.disabled,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
