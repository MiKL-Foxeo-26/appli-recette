/// Configuration de l'application par flavor (development/production)
class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.flavor,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;
  final AppFlavor flavor;

  bool get isDevelopment => flavor == AppFlavor.development;
  bool get isProduction => flavor == AppFlavor.production;
}

enum AppFlavor { development, production }
