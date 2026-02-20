import 'package:flutter/material.dart';

class RecipesPage extends StatelessWidget {
  const RecipesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recettes'),
      ),
      body: const Center(
        child: Text('Ma collection de recettes'),
      ),
    );
  }
}
