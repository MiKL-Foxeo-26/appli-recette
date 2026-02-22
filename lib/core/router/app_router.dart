import 'package:appli_recette/features/home/view/home_page.dart';
import 'package:appli_recette/features/household/view/household_page.dart';
import 'package:appli_recette/features/planning/view/planning_page.dart';
import 'package:appli_recette/features/recipes/view/edit_recipe_screen.dart';
import 'package:appli_recette/features/recipes/view/new_recipe_page.dart';
import 'package:appli_recette/features/recipes/view/recipe_detail_screen.dart';
import 'package:appli_recette/features/recipes/view/recipes_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Routes de l'application
abstract class AppRoutes {
  static const home = '/';
  static const recipes = '/recipes';
  static const household = '/household';
  static const planning = '/planning';
  static const newRecipe = '/recipes/new';
  static const recipeDetail = '/recipes/:id';
  static const recipeEdit = '/recipes/:id/edit';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.recipes,
              builder: (context, state) => const RecipesPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.household,
              builder: (context, state) => const HouseholdPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.planning,
              builder: (context, state) => const PlanningPage(),
            ),
          ],
        ),
      ],
    ),

    // ─── Routes modales hors shell ─────────────────────────────────────────

    // Nouvelle recette (FAB)
    GoRoute(
      path: AppRoutes.newRecipe,
      builder: (context, state) => const NewRecipePage(),
    ),

    // Fiche détail — doit être AVANT la route d'édition pour éviter ambiguïté
    GoRoute(
      path: AppRoutes.recipeDetail,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return RecipeDetailScreen(recipeId: id);
      },
    ),

    // Édition d'une recette
    GoRoute(
      path: AppRoutes.recipeEdit,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return EditRecipeScreen(recipeId: id);
      },
    ),
  ],
);

/// Shell principal avec BottomNavigationBar + FAB
class AppShell extends StatelessWidget {
  const AppShell({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.newRecipe),
        tooltip: 'Nouvelle recette',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Recettes',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: 'Foyer',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Planning',
          ),
        ],
      ),
    );
  }
}
