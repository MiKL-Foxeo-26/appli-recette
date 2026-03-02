/// Tests unitaires RLS — Story 8.4 (AC 2, 8)
///
/// Valide la logique côté Dart :
/// - La whitelist de SyncQueueProcessor autorise household_id pour toutes les tables de données
/// - La méthode tableAllowsField() fonctionne correctement
library;

import 'package:appli_recette/core/sync/sync_queue_processor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncQueueProcessor.tableAllowsField — whitelist household_id (AC 8)',
      () {
    const tablesRequiringHouseholdId = [
      'recipes',
      'members',
      'ingredients',
      'meal_ratings',
      'presence_schedules',
      'weekly_menus',
      'menu_slots',
    ];

    for (final table in tablesRequiringHouseholdId) {
      test('$table — household_id autorisé dans la whitelist', () {
        expect(
          SyncQueueProcessor.tableAllowsField(table, 'household_id'),
          isTrue,
          reason:
              'La table $table doit autoriser household_id pour les politiques RLS',
        );
      });
    }

    test('households — created_by autorisé (propriétaire du foyer)', () {
      expect(
        SyncQueueProcessor.tableAllowsField('households', 'created_by'),
        isTrue,
      );
    });

    test('households — name autorisé', () {
      expect(
        SyncQueueProcessor.tableAllowsField('households', 'name'),
        isTrue,
      );
    });

    test('Table inconnue → field non autorisé', () {
      expect(
        SyncQueueProcessor.tableAllowsField('table_inexistante', 'household_id'),
        isFalse,
      );
    });

    test('Champ inconnu sur table connue → non autorisé', () {
      expect(
        SyncQueueProcessor.tableAllowsField('recipes', 'champ_invalide'),
        isFalse,
      );
    });
  });

  group('SyncQueueProcessor.tableAllowsField — champs essentiels présents',
      () {
    test('recipes — champs essentiels tous présents', () {
      const essentialFields = [
        'id', 'name', 'meal_type', 'household_id', 'is_favorite',
      ];
      for (final field in essentialFields) {
        expect(
          SyncQueueProcessor.tableAllowsField('recipes', field),
          isTrue,
          reason: 'recipes.$field doit être dans la whitelist',
        );
      }
    });

    test('members — champs essentiels tous présents', () {
      const essentialFields = ['id', 'name', 'household_id'];
      for (final field in essentialFields) {
        expect(
          SyncQueueProcessor.tableAllowsField('members', field),
          isTrue,
          reason: 'members.$field doit être dans la whitelist',
        );
      }
    });

    test('presence_schedules — champs essentiels tous présents', () {
      const essentialFields = [
        'id', 'member_id', 'day_of_week', 'meal_slot', 'is_present',
        'household_id',
      ];
      for (final field in essentialFields) {
        expect(
          SyncQueueProcessor.tableAllowsField('presence_schedules', field),
          isTrue,
          reason: 'presence_schedules.$field doit être dans la whitelist',
        );
      }
    });
  });
}
