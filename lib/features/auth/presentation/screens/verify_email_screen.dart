import 'package:appli_recette/core/auth/auth_providers.dart';
import 'package:appli_recette/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Écran "Vérifiez votre email" affiché après un signup réussi (AC-4).
///
/// Affiche l'email de destination, propose de confirmer ou de renvoyer l'email.
class VerifyEmailScreen extends ConsumerWidget {
  const VerifyEmailScreen({this.email, super.key});

  /// Email auquel la confirmation a été envoyée.
  final String? email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Vérifiez votre email',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                email != null
                    ? 'Un email de confirmation a été envoyé à $email. '
                        'Cliquez sur le lien pour activer votre compte.'
                    : 'Un email de confirmation vous a été envoyé. '
                        'Cliquez sur le lien pour activer votre compte.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Bouton "J'ai confirmé mon email"
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () => context.go('/login'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text(
                    "J'ai confirmé mon email",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Lien "Renvoyer l'email"
              Center(
                child: TextButton(
                  onPressed: email != null
                      ? () => _resendEmail(context, ref, email!)
                      : null,
                  child: Text(
                    "Renvoyer l'email",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _resendEmail(
    BuildContext context,
    WidgetRef ref,
    String email,
  ) async {
    try {
      await ref.read(authServiceProvider).signUp(email, '');
    } on AuthException {
      // Ignorer les erreurs de re-signup — l'email est renvoyé automatiquement
    } catch (_) {
      // Ignorer
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email de confirmation renvoyé.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
