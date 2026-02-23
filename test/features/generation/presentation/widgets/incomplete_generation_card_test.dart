import 'package:appli_recette/features/generation/presentation/widgets/incomplete_generation_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildApp(Widget child) {
  return MaterialApp(
    theme: ThemeData(useMaterial3: true),
    home: Scaffold(body: child),
  );
}

void main() {
  group('IncompleteGenerationCard', () {
    testWidgets('n\'est pas affichée quand emptySlotCount = 0', (tester) async {
      await tester.pumpWidget(_buildApp(
        const IncompleteGenerationCard(emptySlotCount: 0),
      ));

      expect(find.byType(Card), findsNothing);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    testWidgets('affiche texte singulier avec 1 créneau', (tester) async {
      await tester.pumpWidget(_buildApp(
        const IncompleteGenerationCard(emptySlotCount: 1),
      ));

      expect(
        find.text('1 créneau n\'a pas pu être rempli'),
        findsOneWidget,
      );
    });

    testWidgets('affiche texte pluriel avec 3 créneaux', (tester) async {
      await tester.pumpWidget(_buildApp(
        const IncompleteGenerationCard(emptySlotCount: 3),
      ));

      expect(
        find.text('3 créneaux n\'ont pas pu être remplis'),
        findsOneWidget,
      );
    });

    testWidgets('affiche les 3 options', (tester) async {
      await tester.pumpWidget(_buildApp(
        const IncompleteGenerationCard(emptySlotCount: 2),
      ));

      expect(find.text('Élargir les filtres'), findsOneWidget);
      expect(find.text('Compléter manuellement'), findsOneWidget);
      expect(find.text('Laisser les créneaux vides'), findsOneWidget);
    });

    testWidgets('tap "Laisser vides" appelle onLeaveEmpty', (tester) async {
      var called = false;
      await tester.pumpWidget(_buildApp(
        IncompleteGenerationCard(
          emptySlotCount: 2,
          onLeaveEmpty: () => called = true,
        ),
      ));

      await tester.tap(find.text('Laisser les créneaux vides'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('tap "Élargir les filtres" appelle onExpandFilters', (tester) async {
      var called = false;
      await tester.pumpWidget(_buildApp(
        IncompleteGenerationCard(
          emptySlotCount: 2,
          onExpandFilters: () => called = true,
        ),
      ));

      await tester.tap(find.text('Élargir les filtres'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('tap "Compléter manuellement" appelle onCompleteManually', (tester) async {
      var called = false;
      await tester.pumpWidget(_buildApp(
        IncompleteGenerationCard(
          emptySlotCount: 2,
          onCompleteManually: () => called = true,
        ),
      ));

      await tester.tap(find.text('Compléter manuellement'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });
  });
}
