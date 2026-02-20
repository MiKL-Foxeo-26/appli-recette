import 'package:appli_recette/app/app.dart';
import 'package:appli_recette/bootstrap.dart';

Future<void> main() async {
  await bootstrap(() => const App());
}
