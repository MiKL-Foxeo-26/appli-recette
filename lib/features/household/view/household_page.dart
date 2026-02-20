import 'package:flutter/material.dart';

class HouseholdPage extends StatelessWidget {
  const HouseholdPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Foyer'),
      ),
      body: const Center(
        child: Text('Membres du foyer'),
      ),
    );
  }
}
