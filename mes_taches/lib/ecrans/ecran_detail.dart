// Écran de détail d'une tâche (parties D1 et D2).
import 'package:flutter/material.dart';

import '../modele/taches.dart';

/// Affiche tout le contenu d'une tâche et permet de la marquer faite ou à
/// faire.
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
    final enRetard = estEnRetard(tache, aujourdhui: aujourdhui);
    final echeance = libelleEcheance(tache.echeance);
    final couleurs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Détail de la tâche')),
      body: ListView(
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
            label: Text(
              tache.faite ? 'Marquer à faire' : 'Marquer comme faite',
            ),
            // Technique 1 : la tâche modifiée (une NOUVELLE tâche, de même
            // identifiant) est la valeur de retour de l'écran.
            onPressed: () =>
                Navigator.of(context).pop(tache.copyWith(faite: !tache.faite)),
          ),
        ],
      ),
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
