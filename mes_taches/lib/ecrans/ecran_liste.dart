// Écran principal : la liste des tâches (parties B à E, bonus G2 à G4).
import 'package:flutter/material.dart';

import '../donnees/exemples.dart';
import '../donnees/lecture_taches.dart';
import '../modele/filtre.dart';
import '../modele/taches.dart';
import '../modele/tri.dart';
import '../widgets/panneau_detail.dart';
import '../widgets/tuile_tache.dart';
import 'ecran_detail.dart';
import 'ecran_formulaire.dart';

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
  // L'ÉTAT de l'écran, modifié par setState : les tâches, le filtre et
  // (bonus G3) l'ordre d'affichage.
  late List<Tache> _taches;
  Filtre _filtre = Filtre.toutes;
  Tri _tri = Tri.saisie;

  // G4 : la tâche dont le détail est affiché à côté de la liste (écran
  // large). On garde son IDENTIFIANT, pas une copie de la tâche : la tâche
  // affichée est toujours celle, à jour, de _taches.
  String? _idSelectionne;

  /// G4 : au-delà de cette largeur, liste et détail sont côte à côte.
  static const largeurDeuxPanneaux = 840.0;

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

  /// La date du jour : celle de l'horloge fournie (tests), sinon l'actuelle.
  DateTime get _aujourdhui => (widget.horloge ?? DateTime.now)();

  /// E1 : un identifiant qui n'est utilisé par aucune tâche de la liste.
  ///
  /// Le compteur ne fait qu'augmenter (un numéro n'est jamais redonné) et
  /// chaque candidat est comparé aux identifiants existants, y compris ceux
  /// venus du JSON : l'unicité est garantie, pas seulement probable.
  String _nouvelIdentifiant() {
    String candidat;
    do {
      _numeroAjout++;
      candidat = 'tache-$_numeroAjout';
    } while (_taches.any((t) => t.id == candidat));
    return candidat;
  }

  /// E1 : ouvre le formulaire et ajoute la tâche créée, s'il y en a une.
  Future<void> _creer() async {
    final nouvelle = await Navigator.of(context).push<Tache>(
      MaterialPageRoute(
        builder: (_) => EcranFormulaire.creation(
          identifiant: _nouvelIdentifiant(),
          aujourdhui: _aujourdhui,
        ),
      ),
    );
    // Retour sans enregistrer : null, rien n'est ajouté.
    if (!mounted || nouvelle == null) return;
    setState(() => _taches = [..._taches, nouvelle]);
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

  /// G2 : retire la tâche de l'état et propose de l'annuler.
  ///
  /// La position retenue est celle dans la liste COMPLÈTE (et non dans la
  /// liste filtrée) : c'est là que la tâche sera remise.
  void _supprimer(Tache tache) {
    final position = _taches.indexWhere((t) => t.id == tache.id);
    if (position < 0) return;
    setState(() {
      _taches = [
        for (final t in _taches)
          if (t.id != tache.id) t,
      ];
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('« ${tache.titre} » supprimée'),
          action: SnackBarAction(
            label: 'Annuler',
            onPressed: () => _restaurer(tache, position),
          ),
        ),
      );
  }

  /// G2 : remet [tache] à sa [position] d'origine (bornée si la liste a
  /// raccourci entre-temps). Sans effet si elle est déjà présente.
  void _restaurer(Tache tache, int position) {
    if (!mounted || _taches.any((t) => t.id == tache.id)) return;
    setState(() {
      _taches = [..._taches]..insert(position.clamp(0, _taches.length), tache);
    });
  }

  /// B2 : marque la tâche faite ou à faire, depuis la liste.
  void _basculer(Tache tache) =>
      _remplacer(tache.copyWith(faite: !tache.faite));

  /// G4 (écran large) : « Modifier » depuis le panneau de détail.
  Future<void> _modifierDansPanneau(Tache tache) async {
    final modifiee = await modifierTache(context, tache, _aujourdhui);
    if (!mounted || modifiee == null) return;
    _remplacer(modifiee);
  }

  /// Une tâche de la liste ; G2 : la glisser vers la gauche la supprime.
  ///
  /// G4 : la toucher ouvre son détail dans une nouvelle page (écran étroit)
  /// ou la sélectionne pour le panneau voisin (écran large).
  Widget _tuile(
    Tache tache,
    DateTime aujourdhui, {
    required bool deuxPanneaux,
    required bool selectionnee,
  }) => Dismissible(
    // La clé suit la tâche (et non sa position) quand la liste filtrée ou
    // triée change, ou qu'une tâche disparaît.
    key: ValueKey(tache.id),
    direction: DismissDirection.endToStart,
    background: const _FondSuppression(),
    onDismissed: (_) => _supprimer(tache),
    child: TuileTache(
      tache: tache,
      aujourdhui: aujourdhui,
      selectionnee: selectionnee,
      onBasculer: () => _basculer(tache),
      onOuvrir: deuxPanneaux
          ? () => setState(() => _idSelectionne = tache.id)
          : () => _ouvrir(tache, aujourdhui),
    ),
  );

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
    final aujourdhui = _aujourdhui;
    // G3 : les éléments affichés, triés ; par échéance, chaque groupe non
    // vide est précédé de son en-tête.
    final List<Object> elements = _tri == Tri.echeance
        ? [
            for (final (:groupe, :taches) in grouperParEcheance(
              visibles,
              aujourdhui: aujourdhui,
            )) ...[groupe, ...taches],
          ]
        : trier(visibles, _tri, aujourdhui: aujourdhui);

    // G4 : la mise en page dépend de la largeur disponible.
    final deuxPanneaux = MediaQuery.sizeOf(context).width > largeurDeuxPanneaux;
    // La tâche sélectionnée se DÉDUIT de l'état ; elle n'est affichée que si
    // elle est encore visible (pas supprimée, pas écartée par le filtre).
    final selection = deuxPanneaux
        ? visibles.where((t) => t.id == _idSelectionne).firstOrNull
        : null;

    final barre = AppBar(
      title: const Text('Mes tâches'),
      actions: [
        // G3 : le menu de tri.
        PopupMenuButton<Tri>(
          icon: const Icon(Icons.sort),
          tooltip: 'Trier',
          initialValue: _tri,
          onSelected: (tri) => setState(() => _tri = tri),
          itemBuilder: (_) => [
            for (final t in Tri.values)
              CheckedPopupMenuItem(
                value: t,
                checked: t == _tri,
                child: Text(t.libelle),
              ),
          ],
        ),
      ],
    );

    // La colonne de la liste : en-tête fixe (compteur, filtre) et tâches.
    final liste = Column(
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
                  itemCount: elements.length,
                  itemBuilder: (context, i) => switch (elements[i]) {
                    final Tache tache => _tuile(
                      tache,
                      aujourdhui,
                      deuxPanneaux: deuxPanneaux,
                      selectionnee: tache.id == selection?.id,
                    ),
                    final GroupeEcheance groupe => _EnTeteGroupe(groupe),
                    // La liste ne contient que des tâches et des en-têtes.
                    final autre => throw StateError('Élément : $autre'),
                  },
                ),
        ),
      ],
    );

    return Scaffold(
      appBar: barre,
      body: deuxPanneaux
          // G4 : liste à gauche, détail de la tâche sélectionnée à droite.
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 400, child: liste),
                const VerticalDivider(width: 1),
                Expanded(
                  child: selection == null
                      ? const Center(child: Text('Sélectionnez une tâche'))
                      : PanneauDetail(
                          key: ValueKey(selection.id),
                          tache: selection,
                          aujourdhui: aujourdhui,
                          onBasculer: () => _basculer(selection),
                          onModifier: () => _modifierDansPanneau(selection),
                        ),
                ),
              ],
            )
          : liste,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _creer,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }
}

/// Le fond rouge révélé quand on fait glisser une tâche pour la supprimer.
class _FondSuppression extends StatelessWidget {
  const _FondSuppression();

  @override
  Widget build(BuildContext context) {
    final couleurs = Theme.of(context).colorScheme;
    return ColoredBox(
      color: couleurs.errorContainer,
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Icon(
            Icons.delete_outline,
            color: couleurs.onErrorContainer,
            semanticLabel: 'Supprimer',
          ),
        ),
      ),
    );
  }
}

/// G3 : l'en-tête d'un groupe dans l'affichage par échéance.
class _EnTeteGroupe extends StatelessWidget {
  const _EnTeteGroupe(this.groupe);

  final GroupeEcheance groupe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        groupe.libelle,
        style: theme.textTheme.titleSmall?.copyWith(
          color: groupe == GroupeEcheance.enRetard
              ? theme.colorScheme.error
              : theme.colorScheme.primary,
        ),
      ),
    );
  }
}
