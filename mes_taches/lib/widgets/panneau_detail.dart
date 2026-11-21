// Le contenu du détail d'une tâche (D1), réutilisé par l'écran de détail
// (écran étroit) et par le panneau à côté de la liste (bonus G4).
import 'package:flutter/material.dart';

import '../modele/taches.dart';

/// Tout le contenu d'une tâche, et ses deux actions.
///
/// Widget SANS état : il ne sait pas s'il est dans une page ou dans un
/// panneau. Les actions remontent par les fonctions de rappel ; c'est le
/// parent qui décide (fermer la page, ou mettre à jour la liste voisine).
class PanneauDetail extends StatelessWidget {
  const PanneauDetail({
    super.key,
    required this.tache,
    required this.aujourdhui,
    required this.onBasculer,
    required this.onModifier,
  });

  final Tache tache;

  /// Reçu du parent : testable avec une date fixe.
  final DateTime aujourdhui;

  /// « Marquer comme faite » / « Marquer à faire ».
  final VoidCallback onBasculer;

  /// « Modifier » (bonus G1).
  final VoidCallback onModifier;

  @override
  Widget build(BuildContext context) {
    final enRetard = estEnRetard(tache, aujourdhui: aujourdhui);
    final echeance = libelleEcheance(tache.echeance);
    final couleurs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Titre COMPLET : pas de maxLines, il passe à la ligne si besoin.
        Text(tache.titre, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        _Ligne(
          icone: Icons.flag_outlined,
          libelle: 'Priorité',
          valeur: tache.priorite.libelle,
        ),
        _Ligne(
          icone: Icons.event_outlined,
          libelle: 'Échéance',
          valeur: enRetard ? '$echeance · en retard' : echeance,
          couleur: enRetard ? couleurs.error : null,
        ),
        _Ligne(
          icone: Icons.notes_outlined,
          libelle: 'Note',
          valeur: tache.note ?? 'Aucune note',
        ),
        _Ligne(
          icone: tache.faite
              ? Icons.check_circle_outline
              : Icons.radio_button_unchecked,
          libelle: 'État',
          valeur: tache.faite ? 'Faite' : 'À faire',
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          icon: Icon(tache.faite ? Icons.undo : Icons.check),
          label: Text(tache.faite ? 'Marquer à faire' : 'Marquer comme faite'),
          onPressed: onBasculer,
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Modifier'),
          onPressed: onModifier,
        ),
      ],
    );
  }
}

/// Une ligne « libellé : valeur » du détail.
class _Ligne extends StatelessWidget {
  const _Ligne({
    required this.icone,
    required this.libelle,
    required this.valeur,
    this.couleur,
  });

  final IconData icone;
  final String libelle;
  final String valeur;
  final Color? couleur;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icone),
      title: Text(libelle),
      subtitle: Text(
        valeur,
        style: couleur == null
            ? null
            : TextStyle(color: couleur, fontWeight: FontWeight.bold),
      ),
    );
  }
}
