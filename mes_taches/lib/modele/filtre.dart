/// Le filtre de la liste des tâches (partie C1). Pur Dart, testable seul.
library;

import 'taches.dart';

/// Les trois choix du sélecteur, avec leur libellé et le message affiché
/// quand aucune tâche n'est retenue.
enum Filtre {
  toutes('Toutes', 'Aucune tâche'),
  aFaire('À faire', 'Aucune tâche à faire'),
  faites('Faites', 'Aucune tâche faite');

  const Filtre(this.libelle, this.messageVide);

  final String libelle;
  final String messageVide;

  /// Vrai si [tache] doit apparaître avec ce filtre. Ne modifie rien.
  bool retient(Tache tache) => switch (this) {
    Filtre.toutes => true,
    Filtre.aFaire => !tache.faite,
    Filtre.faites => tache.faite,
  };
}
