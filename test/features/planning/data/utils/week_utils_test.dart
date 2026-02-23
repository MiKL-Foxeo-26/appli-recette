import 'package:appli_recette/features/planning/data/utils/week_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dateToWeekKey', () {
    test('lundi 2026-02-23 → 2026-W09', () {
      final date = DateTime(2026, 2, 23); // lundi
      expect(dateToWeekKey(date), '2026-W09');
    });

    test('dimanche 2026-03-01 → 2026-W09', () {
      final date = DateTime(2026, 3, 1); // dimanche de la même semaine
      expect(dateToWeekKey(date), '2026-W09');
    });

    test('premier janvier 2026 → 2026-W01', () {
      final date = DateTime(2026, 1, 1); // jeudi
      expect(dateToWeekKey(date), '2026-W01');
    });

    test('31 décembre 2025 → 2026-W01 (semaine ISO chevauchante)', () {
      // Le 31 déc 2025 est un mercredi, le jeudi de cette semaine est le 1er jan 2026
      final date = DateTime(2025, 12, 31);
      expect(dateToWeekKey(date), '2026-W01');
    });

    test('29 décembre 2025 → 2026-W01 (lundi de la semaine W01)', () {
      final date = DateTime(2025, 12, 29);
      expect(dateToWeekKey(date), '2026-W01');
    });
  });

  group('currentWeekKey', () {
    test('retourne un format valide YYYY-Www', () {
      final wk = currentWeekKey();
      expect(wk, matches(RegExp(r'^\d{4}-W\d{2}$')));
    });
  });

  group('weekKeyToDateRange', () {
    test('2026-W09 → lundi 23 fév, dimanche 1 mar', () {
      final range = weekKeyToDateRange('2026-W09');
      expect(range.monday, DateTime(2026, 2, 23));
      expect(range.sunday, DateTime(2026, 3, 1));
    });

    test('2026-W01 → lundi 29 déc 2025, dimanche 4 jan 2026', () {
      final range = weekKeyToDateRange('2026-W01');
      expect(range.monday, DateTime(2025, 12, 29));
      expect(range.sunday, DateTime(2026, 1, 4));
    });

    test('le lundi retourné est bien un lundi (weekday == 1)', () {
      final range = weekKeyToDateRange('2026-W09');
      expect(range.monday.weekday, DateTime.monday);
    });

    test('le dimanche retourné est bien un dimanche (weekday == 7)', () {
      final range = weekKeyToDateRange('2026-W09');
      expect(range.sunday.weekday, DateTime.sunday);
    });
  });

  group('weekKeyOffset', () {
    test('+1 semaine avance de 7 jours', () {
      expect(weekKeyOffset('2026-W09', 1), '2026-W10');
    });

    test('-1 semaine recule de 7 jours', () {
      expect(weekKeyOffset('2026-W09', -1), '2026-W08');
    });

    test('+0 retourne la même semaine', () {
      expect(weekKeyOffset('2026-W09', 0), '2026-W09');
    });

    test('passage d\'année fonctionne', () {
      expect(weekKeyOffset('2026-W01', -1), '2025-W52');
    });

    test('passage d\'année avec semaine 53 (2020 a 53 semaines ISO)', () {
      // 2020 est une année ISO avec 53 semaines
      // W01 de 2021 commence le lundi 4 janvier 2021
      expect(weekKeyOffset('2021-W01', -1), '2020-W53');
    });
  });

  group('weekKeyToDateRange — validation', () {
    test('weekKey malformé lève FormatException', () {
      expect(
        () => weekKeyToDateRange('invalid'),
        throwsA(isA<FormatException>()),
      );
    });

    test('weekKey vide lève FormatException', () {
      expect(
        () => weekKeyToDateRange(''),
        throwsA(isA<FormatException>()),
      );
    });

    test('weekKey avec semaine > 53 lève FormatException', () {
      expect(
        () => weekKeyToDateRange('2026-W54'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
