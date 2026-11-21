// L'affichage d'une tâche dans la liste (partie C2).
import 'package:flutter/material.dart';

import '../modele/taches.dart';

/// Une tâche dans la liste : case à cocher, titre (barré si faite),
/// échéance (en couleur d'alerte si en retard) et indicateur de priorité.
///
/// Widget SANS état : il affiche ce qu'il reçoit par son constructeur et
/// signale les gestes par des fonctions de rappel. Il n'appelle jamais
/// setState ; c'est l'écran propriétaire de l'état qui décide quoi faire.
class TuileTache extends StatelessWidget {
  const TuileTache({
    super.key,
    required this.tache,
    required this.aujourdhui,
    this.onBasculer,
    this.onOuvrir,
  });

  final Tache tache;

  /// Reçu du parent (et non lu ici avec DateTime.now()) : un test peut ainsi
  /// fixer la date et vérifier l'affichage du retard.
  final DateTime aujourdhui;

  /// Toucher la case : marquer faite ou à faire.
  final VoidCallback? onBasculer;

  /// Toucher la tuile ailleurs que sur la case : ouvrir le détail.
  final VoidCallback? onOuvrir;

  @override
  Widget build(BuildContext context) {
    final couleurs = Theme.of(context).colorScheme;
    final enRetard = estEnRetard(tache, aujourdhui: aujourdhui);
    final echeance = libelleEcheance(tache.echeance);

    return ListTile(
      leading: Checkbox(
        value: tache.faite,
        onChanged: onBasculer == null ? null : (_) => onBasculer!(),
      ),
      title: Text(
        tache.titre,
        // Une ligne au plus, puis « … » : pas de débordement en largeur.
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          decoration: tache.faite ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        enRetard ? '$echeance · en retard' : echeance,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: enRetard
            ? TextStyle(color: couleurs.error, fontWeight: FontWeight.bold)
            : null,
      ),
      trailing: _IndicateurPriorite(priorite: tache.priorite),
      onTap: onOuvrir,
    );
  }
}

/// Une icône et le libellé de la priorité.
class _IndicateurPriorite extends StatelessWidget {
  const _IndicateurPriorite({required this.priorite});

  final Priorite priorite;

  @override
  Widget build(BuildContext context) {
    final icone = switch (priorite) {
      Priorite.haute => Icons.keyboard_double_arrow_up,
      Priorite.normale => Icons.drag_handle,
      Priorite.basse => Icons.keyboard_double_arrow_down,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 18),
        const SizedBox(width: 4),
        Text(priorite.libelle),
      ],
    );
  }
}
