import 'dart:math';

import 'package:appli_recette/core/database/app_database.dart';
import 'package:appli_recette/features/generation/domain/models/generation_filters.dart';
import 'package:appli_recette/features/generation/domain/models/generation_input.dart';
import 'package:appli_recette/features/generation/domain/services/generation_service.dart';
import 'package:appli_recette/features/recipes/domain/models/season.dart';
import 'package:flutter_test/flutter_test.dart';

Recipe _recipe(
  String id, {
  String mealType = 'lunch',
  bool isFavorite = false,
  bool isVegetarian = false,
  String season = 'all',
  int prepTimeMinutes = 30,
}) {
  return Recipe(
    id: id,
    name: 'Recipe $id',
    mealType: mealType,
    prepTimeMinutes: prepTimeMinutes,
    cookTimeMinutes: 0,
    restTimeMinutes: 0,
    season: season,
    isVegetarian: isVegetarian,
    servings: 4,
    isFavorite: isFavorite,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    isSynced: false,
  );
}

Member _member(String id) => Member(
      id: id,
      name: 'Member $id',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      isSynced: false,
    );

PresenceSchedule _presence(
  String id,
  String memberId,
  int dayOfWeek,
  String mealSlot, {
  bool isPresent = true,
}) =>
    PresenceSchedule(
      id: id,
      memberId: memberId,
      dayOfWeek: dayOfWeek,
      mealSlot: mealSlot,
      isPresent: isPresent,
    );

MealRating _rating(
  String id,
  String memberId,
  String recipeId,
  String rating,
) =>
    MealRating(
      id: id,
      memberId: memberId,
      recipeId: recipeId,
      rating: rating,
      updatedAt: DateTime(2026),
      isSynced: false,
    );

MenuSlot _menuSlot(
  String id,
  String weeklyMenuId,
  String? recipeId, {
  int dayOfWeek = 1,
  String mealSlot = 'lunch',
}) =>
    MenuSlot(
      id: id,
      weeklyMenuId: weeklyMenuId,
      recipeId: recipeId,
      dayOfWeek: dayOfWeek,
      mealSlot: mealSlot,
      isLocked: false,
      isSynced: false,
    );

// Présences par défaut : tous présents lundi–dimanche midi et soir
List<PresenceSchedule> _allPresent(String memberId) {
  final presences = <PresenceSchedule>[];
  var idx = 0;
  for (var day = 1; day <= 7; day++) {
    for (final meal in ['lunch', 'dinner']) {
      presences.add(_presence('p${idx++}', memberId, day, meal));
    }
  }
  return presences;
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late GenerationService service;

  setUp(() {
    service = GenerationService(random: Random(42));
  });

  // ─── Couche 1 : filtrage par type de repas + présences ───────────────────

  group('Couche 1 — filtrage par type de repas et présences', () {
    test('inclut uniquement les recettes lunch pour un créneau midi', () {
      final recipes = [
        _recipe('r1', mealType: 'lunch'),
        _recipe('r2', mealType: 'dinner'),
        _recipe('r3', mealType: 'breakfast'),
      ];
      final member = _member('m1');
      final input = GenerationInput(
        weekKey: '2026-W09',
        recipes: recipes,
        members: [member],
        presences: _allPresent('m1'),
        ratings: [],
        previousMenuSlots: [],
      );

      final result = service.generateMenu(input);

      // Les 7 créneaux midi (indices pairs) ne doivent contenir que r1
      final lunchSlots = result.asMap().entries
          .where((e) => e.key.isEven && e.value != null)
          .toList();
      for (final s in lunchSlots) {
        expect(s.value!.recipeId, 'r1');
      }
    });

    test('retourne null si aucun membre présent au créneau', () {
      final recipes = [_recipe('r1', mealType: 'lunch')];
      // Aucune présence configurée → tous les créneaux = null
      final input = GenerationInput(
        weekKey: '2026-W09',
        recipes: recipes,
        members: [_member('m1')],
        presences: [], // pas de présences
        ratings: [],
        previousMenuSlots: [],
      );

      final result = service.generateMenu(input);
      expect(result.every((s) => s == null), isTrue);
    });

    test('retourne null pour un créneau sans membres présents même avec recettes', () {
      final recipes = [_recipe('r1', mealType: 'lunch')];
      // Seulement présent lundi midi
      final input = GenerationInput(
        weekKey: '2026-W09',
        recipes: recipes,
        members: [_member('m1')],
        presences: [_presence('p1', 'm1', 1, 'lunch')], // lundi midi seulement
        ratings: [],
        previousMenuSlots: [],
      );

      final result = service.generateMenu(input);
      // Index 0 = lundi midi → doit avoir une recette
      expect(result[0], isNotNull);
      // Index 1 = lundi soir → pas de membres → null
      expect(result[1], isNull);
    });
  });

  // ─── Couche 2 : exclusion "pas aimé" ─────────────────────────────────────

  group('Couche 2 — exclusion "pas aimé"', () {
    test('exclut une recette détestée par un membre présent', () {
      final recipes = [
        _recipe('r1', mealType: 'lunch'),
        _recipe('r2', mealType: 'lunch'),
      ];
      // m1 déteste r1
      final ratings = [_rating('rt1', 'm1', 'r1', 'disliked')];
      final input = GenerationInput(
        weekKey: '2026-W09',
        recipes: recipes,
        members: [_member('m1')],
        presences: _allPresent('m1'),
        ratings: ratings,
        previousMenuSlots: [],
      );

      final result = service.generateMenu(input);
      // Tous les créneaux lunch doivent contenir r2, jamais r1
      final lunchSlots = result.asMap().entries
          .where((e) => e.key.isEven && e.value != null)
          .map((e) => e.value!)
          .toList();
      expect(lunchSlots.every((s) => s.recipeId != 'r1'), isTrue);
    });

    test('ne exclut pas si le membre qui déteste est ABSENT au créneau', () {
      final recipes = [
        _recipe('r1', mealType: 'lunch'),
      ];
      // m1 déteste r1 mais m2 est présent (pas m1)
      final ratings = [_rating('rt1', 'm1', 'r1', 'disliked')];
      final input = GenerationInput(
        weekKey: '2026-W09',
        recipes: recipes,
        members: [_member('m1'), _member('m2')],
        presences: _allPresent('m2'), // seulement m2 présent
        ratings: ratings,
        previousMenuSlots: [],
      );

      final result = service.generateMenu(input);
      // r1 doit être inclus car seul m2 est présent
      final lunchSlots = result.asMap().entries
          .where((e) => e.key.isEven && e.value != null)
          .map((e) => e.value!)
          .toList();
      expect(lunchSlots.every((s) => s.recipeId == 'r1'), isTrue);
    });
  });

  // ─── Couche 3+4 : priorisation ────────────────────────────────────────────

  group('Couche 3+4 — priorisation favoris > aimés > neutres', () {
    test('place les favoris en tête des créneaux', () {
      final recipes = [
        _recipe('r1', mealType: 'lunch', isFavorite: false),
        _recipe('r2', mealType: 'lunch', isFavorite: true),
      ];
      final input = GenerationInput(
        weekKey: '2026-W09',
        recipes: recipes,
        members: [_member('m1')],
        presences: _allPresent('m1'),
        ratings: [],
        previousMenuSlots: [],
      );

      final result = service.generateMenu(input);
      // Premier créneau lunch → r2 (favori)
      expect(result[0]?.recipeId, 'r2');
    });

    test('place les recettes aimées avant les neutres', () {
      final recipes = [
        _recipe('r1', mealType: 'lunch'),
        _recipe('r2', mealType: 'lunch'),
      ];
      // m1 aime r2
      final ratings = [_rating('rt1', 'm1', 'r2', 'liked')];
      final input = GenerationInput(
        weekKey: '2026-W09',
        recipes: recipes,
        members: [_member('m1')],
        presences: _allPresent('m1'),
        ratings: ratings,
        previousMenuSlots: [],
      );

      final result = service.generateMenu(input);
      // Premier créneau → r2 (aimé)
      expect(result[0]?.recipeId, 'r2');
    });
  });

  // ─── Couche 5 : anti-répétition ───────────────────────────────────────────

  group('Couche 5 — anti-répétition', () {
    test('exclut les recettes présentes dans les menus précédents', () {
      final recipes = [
        _recipe('r1', mealType: 'lunch'),
        _recipe('r2', mealType: 'lunch'),
      ];
      // r1 était dans un menu précédent
      final previousSlots = [
        _menuSlot('ms1', 'wm1', 'r1', dayOfWeek: 1, mealSlot: 'lunch'),
      ];
      final input = GenerationInput(
        weekKey: '2026-W09',
        recipes: recipes,
        members: [_member('m1')],
        presences: _allPresent('m1'),
        ratings: [],
        previousMenuSlots: previousSlots,
      );

      final result = service.generateMenu(input);
      // Les créneaux lunch doivent préférer r2
      final lunchSlots = result.asMap().entries
          .where((e) => e.key.isEven && e.value != null)
          .map((e) => e.value!)
          .toList();
      // Au moins le premier créneau doit être r2
      expect(lunchSlots.first.recipeId, 'r2');
    });
  });

  // ─── Couche 6 : complétion aléatoire + reproductibilité ──────────────────

  group('Couche 6 — complétion aléatoire', () {
    test('résultat reproductible avec le même seed', () {
      final recipes = List.generate(
        20,
        (i) => _recipe('r$i', mealType: i.isEven ? 'lunch' : 'dinner'),
      );
      final input = GenerationInput(
        weekKey: '2026-W09',
        recipes: recipes,
        members: [_member('m1')],
        presences: _allPresent('m1'),
        ratings: [],
        previousMenuSlots: [],
      );

      final service1 = GenerationService(random: Random(42));
      final service2 = GenerationService(random: Random(42));

      final result1 = service1.generateMenu(input);
      final result2 = service2.generateMenu(input);

      expect(
        result1.map((s) => s?.recipeId).toList(),
        equals(result2.map((s) => s?.recipeId).toList()),
      );
    });

    test('retourne null pour un créneau si pool vide après tous les filtres', () {
      // Aucune recette lunch disponible
      final input = GenerationInput(
        weekKey: '2026-W09',
        recipes: [_recipe('r1', mealType: 'dinner')], // seulement dinner
        members: [_member('m1')],
        presences: _allPresent('m1'),
        ratings: [],
        previousMenuSlots: [],
      );

      final result = service.generateMenu(input);
      // Tous les créneaux midi doivent être null
      expect(result.asMap().entries
          .where((e) => e.key.isEven)
          .every((e) => e.value == null), isTrue);
    });
  });

  // ─── Filtres utilisateur ─────────────────────────────────────────────────

  group('Filtres utilisateur', () {
    test('filtre par maxPrepTimeMinutes', () {
      final recipes = [
        _recipe('r1', mealType: 'lunch', prepTimeMinutes: 90),
        _recipe('r2', mealType: 'lunch', prepTimeMinutes: 20),
      ];
      const filters = GenerationFilters(maxPrepTimeMinutes: 30);
      final input = GenerationInput(
        weekKey: '2026-W09',
        recipes: recipes,
        members: [_member('m1')],
        presences: _allPresent('m1'),
        ratings: [],
        previousMenuSlots: [],
        filters: filters,
      );

      final result = service.generateMenu(input);
      final slots = result.whereType<dynamic>().toList();
      // Seule r2 (20min) passe le filtre 30min
      expect(result.where((s) => s?.recipeId == 'r1').isEmpty, isTrue);
    });

    test('filtre végétarien exclut les non-végétariens', () {
      final recipes = [
        _recipe('r1', mealType: 'lunch', isVegetarian: false),
        _recipe('r2', mealType: 'lunch', isVegetarian: true),
      ];
      const filters = GenerationFilters(vegetarianOnly: true);
      final input = GenerationInput(
        weekKey: '2026-W09',
        recipes: recipes,
        members: [_member('m1')],
        presences: _allPresent('m1'),
        ratings: [],
        previousMenuSlots: [],
        filters: filters,
      );

      final result = service.generateMenu(input);
      expect(result.every((s) => s == null || s.recipeId == 'r2'), isTrue);
    });

    test('filtre saison exclut les mauvaises saisons', () {
      final recipes = [
        _recipe('r1', mealType: 'lunch', season: 'summer'),
        _recipe('r2', mealType: 'lunch', season: 'winter'),
        _recipe('r3', mealType: 'lunch', season: 'all'), // toujours inclus
      ];
      const filters = GenerationFilters(season: Season.summer);
      final input = GenerationInput(
        weekKey: '2026-W09',
        recipes: recipes,
        members: [_member('m1')],
        presences: _allPresent('m1'),
        ratings: [],
        previousMenuSlots: [],
        filters: filters,
      );

      final result = service.generateMenu(input);
      // Seules r1 (summer) et r3 (all) passent
      expect(
        result.every((s) => s == null || s.recipeId != 'r2'),
        isTrue,
      );
    });
  });

  // ─── Performance NFR1 ─────────────────────────────────────────────────────

  group('Performance (NFR1 < 2s)', () {
    test('génération de 14 créneaux avec 50 recettes et 5 membres < 2s', () {
      final recipes = List.generate(
        50,
        (i) => _recipe('r$i', mealType: i.isEven ? 'lunch' : 'dinner'),
      );
      final members = List.generate(5, (i) => _member('m$i'));
      final presences = members
          .expand((m) => _allPresent(m.id))
          .toList();

      final input = GenerationInput(
        weekKey: '2026-W09',
        recipes: recipes,
        members: members,
        presences: presences,
        ratings: [],
        previousMenuSlots: [],
      );

      final stopwatch = Stopwatch()..start();
      service.generateMenu(input);
      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(2000),
        reason:
            'La génération a pris ${stopwatch.elapsedMilliseconds}ms, doit être < 2000ms',
      );
    });
  });

  // ─── Intégration complète ─────────────────────────────────────────────────

  group('Intégration — generateMenu complet', () {
    test('génère 14 slots avec données réalistes', () {
      final recipes = List.generate(
        20,
        (i) => _recipe(
          'r$i',
          mealType: i % 3 == 0 ? 'dinner' : 'lunch',
          isFavorite: i < 3,
        ),
      );
      final member = _member('m1');
      final input = GenerationInput(
        weekKey: '2026-W09',
        recipes: recipes,
        members: [member],
        presences: _allPresent('m1'),
        ratings: [_rating('rt1', 'm1', 'r0', 'liked')],
        previousMenuSlots: [],
      );

      final result = service.generateMenu(input);

      expect(result.length, 14);
      // Avec 20 recettes et tous présents, au moins quelques créneaux doivent être remplis
      expect(result.whereType<dynamic>().length, greaterThan(5));
    });

    test('retourne une liste de 14 éléments même si pool vide', () {
      final input = GenerationInput(
        weekKey: '2026-W09',
        recipes: [],
        members: [_member('m1')],
        presences: _allPresent('m1'),
        ratings: [],
        previousMenuSlots: [],
      );

      final result = service.generateMenu(input);
      expect(result.length, 14);
      expect(result.every((s) => s == null), isTrue);
    });
  });
}
