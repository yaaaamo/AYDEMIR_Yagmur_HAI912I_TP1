// Écran principal : la liste des tâches (parties B, C, D, puis E).
import 'package:flutter/material.dart';

import '../donnees/exemples.dart';
import '../donnees/lecture_taches.dart';
import '../modele/filtre.dart';
import '../modele/taches.dart';
import '../widgets/tuile_tache.dart';
import 'ecran_detail.dart';

/// La liste des tâches, avec le compteur « n à faire » et le filtre.
///
/// C'est un StatefulWidget : la liste des tâches et le filtre forment l'état
/// de l'écran, et ce widget en est le seul propriétaire.
class EcranListe extends StatefulWidget {
  const EcranListe({super.key, this.tachesInitiales, this.horloge});

  /// Les tâches de départ (pour les tests) ; par défaut, les données
  /// d'exemple JSON.
  final List<Tache>? tachesInitiales;

  /// Donne la date du jour (pour les tests) ; par défaut, DateTime.now.
  final DateTime Function()? horloge;

  @override
  State<EcranListe> createState() => _EcranListeState();
}

class _EcranListeState extends State<EcranListe> {
  // L'ÉTAT de l'écran : deux informations, modifiées par setState.
  late List<Tache> _taches;
  Filtre _filtre = Filtre.toutes;

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

  /// Remplace dans l'état la tâche de même identifiant que [nouvelle].
  ///
  /// Les tâches sont immuables : on ne les modifie pas, on les REMPLACE.
  /// La tâche est retrouvée par son identifiant, jamais par sa position
  /// (qui dépend du filtre).
  void _remplacer(Tache nouvelle) {
    setState(() {
      _taches = [
        for (final t in _taches)
          if (t.id == nouvelle.id) nouvelle else t,
      ];
    });
  }

  /// B2 : marque la tâche faite ou à faire, depuis la liste.
  void _basculer(Tache tache) =>
      _remplacer(tache.copyWith(faite: !tache.faite));

  /// D1, D2 : ouvre le détail et attend son résultat.
  Future<void> _ouvrir(Tache tache, DateTime aujourdhui) async {
    // push renvoie un Future, complété au moment du pop : la tâche modifiée,
    // ou null si l'utilisateur revient en arrière sans agir.
    final resultat = await Navigator.of(context).push<Tache>(
      MaterialPageRoute(
        builder: (_) => EcranDetail(tache: tache, aujourdhui: aujourdhui),
      ),
    );
    // Après un await, l'écran a pu être retiré : vérifier mounted.
    if (!mounted || resultat == null) return;
    _remplacer(resultat);
  }

  @override
  Widget build(BuildContext context) {
    // Tout ce qui suit se DÉDUIT de l'état ; rien n'est stocké en double.
    final (:faites, :total) = bilan(_taches);
    final restantes = total - faites; // compte global, quel que soit le filtre
    final visibles = [
      for (final t in _taches)
        if (_filtre.retient(t)) t,
    ];
    final aujourdhui = (widget.horloge ?? DateTime.now)();

    return Scaffold(
      appBar: AppBar(title: const Text('Mes tâches')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête fixe : compteur et filtre ne défilent pas.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '$restantes à faire',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<Filtre>(
              showSelectedIcon: false,
              segments: [
                for (final f in Filtre.values)
                  ButtonSegment(value: f, label: Text(f.libelle)),
              ],
              selected: {_filtre},
              onSelectionChanged: (choix) =>
                  setState(() => _filtre = choix.single),
            ),
          ),
          const SizedBox(height: 8),
          // Expanded donne à la liste une hauteur bornée : l'espace restant.
          // Seule cette partie défile.
          Expanded(
            child: visibles.isEmpty
                ? Center(child: Text(_filtre.messageVide))
                : ListView.builder(
                    // Marge basse : le bouton flottant ne cache pas la
                    // dernière tâche.
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: visibles.length,
                    itemBuilder: (context, i) {
                      final tache = visibles[i];
                      return TuileTache(
                        // La clé suit la tâche (et non sa position) quand la
                        // liste filtrée change.
                        key: ValueKey(tache.id),
                        tache: tache,
                        aujourdhui: aujourdhui,
                        onBasculer: () => _basculer(tache),
                        onOuvrir: () => _ouvrir(tache, aujourdhui),
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
