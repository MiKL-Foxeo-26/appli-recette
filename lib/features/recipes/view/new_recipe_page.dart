import 'package:flutter/material.dart';

class NewRecipePage extends StatelessWidget {
  const NewRecipePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle recette'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Text('Formulaire de création de recette — Epic 2'),
      ),
    );
  }
}
