// Écran principal : la liste des tâches (parties B, puis C, D, E).
import 'package:flutter/material.dart';

import '../donnees/exemples.dart';
import '../donnees/lecture_taches.dart';
import '../modele/taches.dart';

/// La liste des tâches, avec le compteur « n à faire ».
///
/// C'est un StatefulWidget : la liste des tâches est l'état de l'écran, et ce
/// widget en est le seul propriétaire (une seule source de vérité).
class EcranListe extends StatefulWidget {
  /// [tachesInitiales] permet aux tests de fournir leurs propres tâches ;
  /// par défaut, l'écran lit les données d'exemple JSON.
  const EcranListe({super.key, this.tachesInitiales});

  final List<Tache>? tachesInitiales;

  @override
  State<EcranListe> createState() => _EcranListeState();
}

class _EcranListeState extends State<EcranListe> {
  // L'ÉTAT de l'écran. Il vit dans cet objet State, qui survit aux
  // reconstructions (et au rechargement à chaud).
  late List<Tache> _taches;

  // Sert à fabriquer des identifiants uniques pour les tâches ajoutées.
  int _numeroAjout = 0;

  @override
  void initState() {
    super.initState();
    // initState n'est exécuté qu'UNE fois, à la création du State :
    // un rechargement à chaud ne le rappelle pas, un redémarrage (R) si.
    _taches =
        widget.tachesInitiales ?? tachesDepuisJsonTexte(tachesExempleJson);
  }

  /// Un identifiant qui n'est utilisé par aucune tâche de la liste.
  String _nouvelIdentifiant() {
    String candidat;
    do {
      _numeroAjout++;
      candidat = 'ajout-$_numeroAjout';
    } while (_taches.any((t) => t.id == candidat));
    return candidat;
  }

  /// B1 : ajoute une tâche d'exemple (remplacé par le formulaire en E1).
  void _ajouter() {
    setState(() {
      final id = _nouvelIdentifiant();
      _taches = [..._taches, Tache(id: id, titre: 'Tâche $_numeroAjout')];
    });
  }

  /// B2 : marque la tâche [id] faite ou à faire.
  ///
  /// La tâche n'est pas modifiée (elle est immuable) : on la REMPLACE dans
  /// l'état par une copie, retrouvée par son identifiant (jamais par sa
  /// position, qui change avec les filtres de la partie C).
  void _basculer(String id) {
    setState(() {
      _taches = [
        for (final t in _taches)
          if (t.id == id) t.copyWith(faite: !t.faite) else t,
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    // Le compteur se CALCULE à partir de l'état ; il n'est pas stocké.
    final (:faites, :total) = bilan(_taches);
    final restantes = total - faites;

    return Scaffold(
      appBar: AppBar(title: const Text('Mes tâches')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '$restantes à faire',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          // Expanded donne à la ListView une hauteur bornée (l'espace restant).
          Expanded(
            child: ListView.builder(
              itemCount: _taches.length,
              itemBuilder: (context, i) {
                final tache = _taches[i];
                return ListTile(
                  leading: Checkbox(
                    value: tache.faite,
                    onChanged: (_) => _basculer(tache.id),
                  ),
                  title: Text(tache.titre),
                  subtitle: Text(tache.priorite.libelle),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ajouter,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }
}
