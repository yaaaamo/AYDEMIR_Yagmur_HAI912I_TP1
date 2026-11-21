// « Mes tâches », un gestionnaire de tâches personnel.
// Point d'entrée : runApp() attache la racine de l'arbre de widgets à l'écran.
// Tout le reste est une composition de widgets.
import 'package:flutter/material.dart';

void main() => runApp(const MesTachesApp());

class MesTachesApp extends StatelessWidget {
  const MesTachesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mes tâches',
      debugShowCheckedModeBanner: false,
      // Material 3 est le défaut et tout le thème dérive d'une couleur.
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.teal)),
      // Écran provisoire : à remplacer par votre écran de liste (B1).
      home: const _EcranProvisoire(),
    );
  }
}

/// Écran provisoire.
class _EcranProvisoire extends StatelessWidget {
  const _EcranProvisoire();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes tâches')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Le projet se lance.\n'
            'Remplacez cet écran par votre liste de tâches (partie B).',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
