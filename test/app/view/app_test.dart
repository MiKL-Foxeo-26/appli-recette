import 'package:appli_recette/app/app.dart';
import 'package:appli_recette/core/config/app_config.dart';
import 'package:appli_recette/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('App', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('se lance sans erreur et affiche un Scaffold', (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      const config = AppConfig(
        supabaseUrl: 'https://placeholder.supabase.co',
        supabaseAnonKey: 'placeholder-anon-key',
        flavor: AppFlavor.development,
      );

      await tester.pumpWidget(App(database: db, config: config));
      await tester.pump(); // Premier frame
      await tester.pump(const Duration(milliseconds: 100)); // Laisse le Future se résoudre

      expect(find.byType(Scaffold), findsWidgets);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      await db.close();
    });
  });
}
