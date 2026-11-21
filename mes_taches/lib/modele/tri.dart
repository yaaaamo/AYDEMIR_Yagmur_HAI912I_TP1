/// Tri et regroupement de la liste (bonus G3). Pur Dart, testable seul.
library;

import 'taches.dart';

/// Les ordres proposés par le menu de la barre d'application.
enum Tri {
  saisie('Ordre de saisie'),
  priorite('Par priorité'),
  echeance('Par échéance'),
  titre('Par titre');

  const Tri(this.libelle);

  final String libelle;
}

/// Les groupes de l'affichage par échéance, dans l'ordre d'affichage.
enum GroupeEcheance {
  enRetard('En retard'),
  datees('Datées'),
  hebdomadaires('Hebdomadaires'),
  sansEcheance('Sans échéance');

  const GroupeEcheance(this.libelle);

  final String libelle;
}

/// Le groupe de [tache] : « en retard » au sens de [estEnRetard] (une tâche
/// faite n'est donc jamais en retard), sinon selon la forme de l'échéance.
GroupeEcheance groupeDe(Tache tache, {required DateTime aujourdhui}) {
  if (estEnRetard(tache, aujourdhui: aujourdhui)) {
    return GroupeEcheance.enRetard;
  }
  return switch (tache.echeance) {
    EcheanceDate() => GroupeEcheance.datees,
    EcheanceHebdo() => GroupeEcheance.hebdomadaires,
    SansEcheance() => GroupeEcheance.sansEcheance,
  };
}

/// Une NOUVELLE liste, triée selon [tri]. La collection reçue n'est pas
/// modifiée. À critère égal, le titre départage.
List<Tache> trier(
  Iterable<Tache> taches,
  Tri tri, {
  required DateTime aujourdhui,
}) {
  final resultat = List.of(taches);
  final comparer = switch (tri) {
    Tri.saisie => null, // ordre de la liste, inchangé
    Tri.priorite => _parPriorite,
    Tri.titre => _parTitre,
    Tri.echeance => (Tache a, Tache b) => _parEcheance(
      a,
      b,
      aujourdhui: aujourdhui,
    ),
  };
  if (comparer != null) resultat.sort(comparer);
  return resultat;
}

/// Les tâches triées par échéance et regroupées : un record par groupe NON
/// vide, dans l'ordre de [GroupeEcheance].
List<({GroupeEcheance groupe, List<Tache> taches})> grouperParEcheance(
  Iterable<Tache> taches, {
  required DateTime aujourdhui,
}) {
  final triees = trier(taches, Tri.echeance, aujourdhui: aujourdhui);
  final groupes = <({GroupeEcheance groupe, List<Tache> taches})>[];
  for (final groupe in GroupeEcheance.values) {
    final membres = [
      for (final t in triees)
        if (groupeDe(t, aujourdhui: aujourdhui) == groupe) t,
    ];
    if (membres.isNotEmpty) groupes.add((groupe: groupe, taches: membres));
  }
  return groupes;
}

/// Titre, sans tenir compte des majuscules.
int _parTitre(Tache a, Tache b) =>
    a.titre.toLowerCase().compareTo(b.titre.toLowerCase());

/// De la plus urgente à la moins urgente, puis par titre.
int _parPriorite(Tache a, Tache b) {
  final parPriorite = b.priorite.compareTo(a.priorite); // décroissant
  return parPriorite != 0 ? parPriorite : _parTitre(a, b);
}

/// Par groupe ; dans un groupe daté, par date croissante ; dans le groupe
/// hebdomadaire, du lundi au dimanche ; puis par titre.
int _parEcheance(Tache a, Tache b, {required DateTime aujourdhui}) {
  final parGroupe = groupeDe(
    a,
    aujourdhui: aujourdhui,
  ).index.compareTo(groupeDe(b, aujourdhui: aujourdhui).index);
  if (parGroupe != 0) return parGroupe;
  final parValeur = switch ((a.echeance, b.echeance)) {
    (EcheanceDate(date: final da), EcheanceDate(date: final db)) =>
      da.compareTo(db),
    (EcheanceHebdo(jour: final ja), EcheanceHebdo(jour: final jb)) =>
      ja.compareTo(jb),
    _ => 0,
  };
  return parValeur != 0 ? parValeur : _parTitre(a, b);
}
