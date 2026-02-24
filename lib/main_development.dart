import 'package:appli_recette/app/app.dart';
import 'package:appli_recette/bootstrap.dart';
import 'package:appli_recette/core/config/app_config.dart';
import 'package:appli_recette/core/database/app_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  const config = AppConfig(
    // Remplacer par les vraies clés depuis .env.development
    supabaseUrl: String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://placeholder.supabase.co',
    ),
    supabaseAnonKey: String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'placeholder-anon-key',
    ),
    flavor: AppFlavor.development,
  );

  final database = AppDatabase();

  await bootstrap(
    () async {
      await Supabase.initialize(
        url: config.supabaseUrl,
        anonKey: config.supabaseAnonKey,
        debug: true,
        // La session anonyme est persistée automatiquement dans le stockage
        // local Flutter par supabase_flutter. Au redémarrage, Supabase la
        // restaure lors de l'initialisation — aucune action supplémentaire
        // requise (AC-7 Story 7.2).
      );
      return App(database: database, config: config);
    },
  );
}
