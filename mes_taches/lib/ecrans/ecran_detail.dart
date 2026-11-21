// Écran de détail d'une tâche (parties D1, D2 et bonus G1), pour les écrans
// étroits. Au-delà de 840 px, le même contenu s'affiche en panneau (G4).
import 'package:flutter/material.dart';

import '../modele/taches.dart';
import '../widgets/panneau_detail.dart';
import 'ecran_formulaire.dart';

/// Une page qui affiche le détail d'une tâche.
///
/// L'écran ne possède rien : il reçoit la tâche par son constructeur.
/// Il RENVOIE son résultat en se fermant (Navigator.pop avec la tâche
/// modifiée) ; un simple retour renvoie null et ne change rien.
class EcranDetail extends StatelessWidget {
  const EcranDetail({super.key, required this.tache, required this.aujourdhui});

  final Tache tache;

  /// Reçu de la liste, comme pour la tuile : testable avec une date fixe.
  final DateTime aujourdhui;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détail de la tâche')),
      body: PanneauDetail(
        tache: tache,
        aujourdhui: aujourdhui,
        // Technique 1 : la tâche modifiée (une NOUVELLE tâche, de même
        // identifiant) est la valeur de retour de l'écran.
        onBasculer: () =>
            Navigator.of(context).pop(tache.copyWith(faite: !tache.faite)),
        onModifier: () => _modifier(context),
      ),
    );
  }

  /// G1 : si la tâche est modifiée, le détail se ferme en la renvoyant à la
  /// liste, par le même chemin que « Marquer comme faite ».
  Future<void> _modifier(BuildContext context) async {
    final modifiee = await modifierTache(context, tache, aujourdhui);
    // Après un await, l'écran a pu être retiré : vérifier context.mounted.
    if (!context.mounted || modifiee == null) return;
    Navigator.of(context).pop(modifiee);
  }
}

/// G1 : ouvre le formulaire pré-rempli et renvoie la tâche modifiée, ou null
/// si l'utilisateur revient en arrière. Utilisé par cette page et par le
/// panneau de détail de la liste (G4).
Future<Tache?> modifierTache(
  BuildContext context,
  Tache tache,
  DateTime aujourdhui,
) {
  return Navigator.of(context).push<Tache>(
    MaterialPageRoute(
      builder: (_) => EcranFormulaire.modification(
        tacheInitiale: tache,
        aujourdhui: aujourdhui,
      ),
    ),
  );
}
