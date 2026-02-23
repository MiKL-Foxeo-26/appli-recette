import 'package:appli_recette/features/generation/domain/models/generation_filters.dart';
import 'package:appli_recette/features/generation/presentation/providers/generation_provider.dart';
import 'package:appli_recette/features/generation/presentation/widgets/generation_filters_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildApp({GenerationFilters? initialFilters, void Function(GenerationFilters)? onApply}) {
  return ProviderScope(
    child: MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        body: GenerationFiltersSheet(
          initialFilters: initialFilters,
          onApply: onApply,
        ),
      ),
    ),
  );
}

void main() {
  group('GenerationFiltersSheet', () {
    testWidgets('affiche les valeurs par défaut (slider 0, switch off, aucun chip)', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Le slider doit être à 0 → label "Pas de limite"
      expect(find.text('Pas de limite'), findsAtLeast(1));

      // Le switch doit être désactivé
      final switchWidget = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(switchWidget.value, isFalse);
    });

    testWidgets('tap "Réinitialiser" remet les filtres à zéro', (tester) async {
      const initialFilters = GenerationFilters(
        maxPrepTimeMinutes: 30,
        vegetarianOnly: true,
      );

      GenerationFilters? appliedFilters;
      await tester.pumpWidget(_buildApp(
        initialFilters: initialFilters,
        onApply: (f) => appliedFilters = f,
      ));
      await tester.pumpAndSettle();

      // Tap Réinitialiser
      await tester.tap(find.text('Réinitialiser'));
      await tester.pumpAndSettle();

      // Switch doit être désactivé
      final switchWidget = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(switchWidget.value, isFalse);

      // Appliquer les filtres
      await tester.tap(find.text('Appliquer'));
      await tester.pumpAndSettle();

      expect(appliedFilters?.maxPrepTimeMinutes, isNull);
      expect(appliedFilters?.vegetarianOnly, isFalse);
      expect(appliedFilters?.season, isNull);
    });

    testWidgets('sélection végétarien met à jour le filtre', (tester) async {
      GenerationFilters? appliedFilters;
      await tester.pumpWidget(_buildApp(
        onApply: (f) => appliedFilters = f,
      ));
      await tester.pumpAndSettle();

      // Activer le switch végétarien
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      // Appliquer
      await tester.tap(find.text('Appliquer'));
      await tester.pumpAndSettle();

      expect(appliedFilters?.vegetarianOnly, isTrue);
    });
  });

  group('hasActiveFiltersProvider', () {
    testWidgets('est false quand aucun filtre actif', (tester) async {
      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          child: Builder(
            builder: (context) {
              container = ProviderScope.containerOf(context);
              return const MaterialApp(home: Scaffold());
            },
          ),
        ),
      );

      expect(container.read(hasActiveFiltersProvider), isFalse);
    });

    testWidgets('est true quand filtre végétarien actif', (tester) async {
      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          child: Builder(
            builder: (context) {
              container = ProviderScope.containerOf(context);
              return const MaterialApp(home: Scaffold());
            },
          ),
        ),
      );

      container
          .read(filtersProvider.notifier)
          .update(const GenerationFilters(vegetarianOnly: true));

      expect(container.read(hasActiveFiltersProvider), isTrue);
    });
  });
}
