import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/features/planning/presentation/providers/planning_provider.dart';
import 'package:appli_recette/features/planning/presentation/widgets/presence_toggle_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPlanningNotifier extends AsyncNotifier<void>
    with Mock
    implements PlanningNotifier {
  @override
  Future<void> build() async {}
}

/// Crée un Member de test.
Member _member(String id, String name) {
  final now = DateTime.now();
  return Member(
    id: id,
    name: name,
    createdAt: now,
    updatedAt: now,
    isSynced: false,
  );
}

/// Crée une PresenceSchedule de test pour le planning type.
PresenceSchedule _presence({
  required String memberId,
  required int dayOfWeek,
  required String mealSlot,
  bool isPresent = true,
}) {
  return PresenceSchedule(
    id: 'ps-$memberId-$dayOfWeek-$mealSlot',
    memberId: memberId,
    dayOfWeek: dayOfWeek,
    mealSlot: mealSlot,
    isPresent: isPresent,
  );
}

/// Génère les 14 entrées de planning type pour un membre.
List<PresenceSchedule> _fullSchedule(String memberId,
    {bool allPresent = true}) {
  return [
    for (var day = 1; day <= 7; day++)
      for (final slot in ['lunch', 'dinner'])
        _presence(
          memberId: memberId,
          dayOfWeek: day,
          mealSlot: slot,
          isPresent: allPresent,
        ),
  ];
}

Widget _buildGrid({
  required List<Member> members,
  required List<PresenceSchedule> presences,
  required MockPlanningNotifier mockNotifier,
}) {
  return ProviderScope(
    overrides: [
      planningNotifierProvider.overrideWith(() => mockNotifier),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: PresenceToggleGrid(
            members: members,
            presences: presences,
          ),
        ),
      ),
    ),
  );
}

void main() {
  late MockPlanningNotifier mockNotifier;

  setUp(() {
    mockNotifier = MockPlanningNotifier();
  });

  group('PresenceToggleGrid', () {
    testWidgets('affiche les noms des membres en lignes', (tester) async {
      final members = [
        _member('m1', 'MiKL'),
        _member('m2', 'Partenaire'),
      ];
      final presences = [
        ..._fullSchedule('m1'),
        ..._fullSchedule('m2'),
      ];

      await tester.pumpWidget(_buildGrid(
        members: members,
        presences: presences,
        mockNotifier: mockNotifier,
      ));

      expect(find.text('MiKL'), findsOneWidget);
      expect(find.text('Partenaire'), findsOneWidget);
    });

    testWidgets('affiche les en-têtes de jours abrégés', (tester) async {
      final members = [_member('m1', 'Test')];
      final presences = _fullSchedule('m1');

      await tester.pumpWidget(_buildGrid(
        members: members,
        presences: presences,
        mockNotifier: mockNotifier,
      ));

      expect(find.text('Lun'), findsOneWidget);
      expect(find.text('Dim'), findsOneWidget);
    });

    testWidgets('affiche les sous-colonnes M (midi) et S (soir)',
        (tester) async {
      final members = [_member('m1', 'Test')];
      final presences = _fullSchedule('m1');

      await tester.pumpWidget(_buildGrid(
        members: members,
        presences: presences,
        mockNotifier: mockNotifier,
      ));

      // 7 jours × 2 sous-colonnes, mais 'M' apparaît dans le header
      expect(find.text('M'), findsWidgets);
      expect(find.text('S'), findsWidgets);
    });

    testWidgets('affiche 14 checkboxes par membre', (tester) async {
      final members = [_member('m1', 'Solo')];
      final presences = _fullSchedule('m1');

      await tester.pumpWidget(_buildGrid(
        members: members,
        presences: presences,
        mockNotifier: mockNotifier,
      ));

      // 14 checkboxes (7 jours × 2 repas)
      expect(find.byType(Checkbox), findsNWidgets(14));
    });

    testWidgets('checkboxes cochées quand isPresent = true', (tester) async {
      final members = [_member('m1', 'Présent')];
      final presences = _fullSchedule('m1', allPresent: true);

      await tester.pumpWidget(_buildGrid(
        members: members,
        presences: presences,
        mockNotifier: mockNotifier,
      ));

      final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox));
      for (final cb in checkboxes) {
        expect(cb.value, isTrue);
      }
    });

    testWidgets('checkboxes décochées quand isPresent = false',
        (tester) async {
      final members = [_member('m1', 'Absent')];
      final presences = _fullSchedule('m1', allPresent: false);

      await tester.pumpWidget(_buildGrid(
        members: members,
        presences: presences,
        mockNotifier: mockNotifier,
      ));

      final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox));
      for (final cb in checkboxes) {
        expect(cb.value, isFalse);
      }
    });

    testWidgets('Semantics labels présents pour accessibilité',
        (tester) async {
      final members = [_member('m1', 'MiKL')];
      final presences = _fullSchedule('m1');

      await tester.pumpWidget(_buildGrid(
        members: members,
        presences: presences,
        mockNotifier: mockNotifier,
      ));

      // Vérifier qu'un Semantics label existe pour le premier créneau
      expect(
        find.bySemanticsLabel('Présence de MiKL — Lun midi'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Présence de MiKL — Lun soir'),
        findsOneWidget,
      );
    });

    testWidgets('tap sur checkbox appelle togglePresence', (tester) async {
      when(
        () => mockNotifier.togglePresence(
          memberId: any(named: 'memberId'),
          dayOfWeek: any(named: 'dayOfWeek'),
          mealSlot: any(named: 'mealSlot'),
        ),
      ).thenAnswer((_) async {});

      final members = [_member('m1', 'Tap')];
      final presences = _fullSchedule('m1');

      await tester.pumpWidget(_buildGrid(
        members: members,
        presences: presences,
        mockNotifier: mockNotifier,
      ));

      // Tap sur la première checkbox
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();

      verify(
        () => mockNotifier.togglePresence(
          memberId: 'm1',
          dayOfWeek: 1,
          mealSlot: 'lunch',
        ),
      ).called(1);
    });

    testWidgets('deux membres affichent 28 checkboxes', (tester) async {
      final members = [
        _member('m1', 'Alpha'),
        _member('m2', 'Beta'),
      ];
      final presences = [
        ..._fullSchedule('m1'),
        ..._fullSchedule('m2'),
      ];

      await tester.pumpWidget(_buildGrid(
        members: members,
        presences: presences,
        mockNotifier: mockNotifier,
      ));

      expect(find.byType(Checkbox), findsNWidgets(28));
    });
  });
}
