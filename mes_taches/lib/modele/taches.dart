/// Modèle de « Mes tâches » (TP 1, partie A).
///
/// Ce fichier ne dépend que de Dart (aucun import de Flutter) : il se teste
/// donc sans interface, avec de simples tests unitaires.
library;

// ---------------------------------------------------------------------------
// Priorité
// ---------------------------------------------------------------------------

/// Priorité d'une tâche, ordonnée de la plus basse à la plus haute.
///
/// L'ordre de déclaration EST l'ordre métier : `index` vaut 0, 1, 2.
/// Chaque valeur porte son code JSON et son libellé affichable.
enum Priorite implements Comparable<Priorite> {
  basse('low', 'Basse'),
  normale('normal', 'Normale'),
  haute('high', 'Haute');

  const Priorite(this.code, this.libelle);

  /// Code utilisé dans les documents JSON ('low', 'normal', 'high').
  final String code;

  /// Texte affiché à l'utilisateur.
  final String libelle;

  @override
  int compareTo(Priorite autre) => index.compareTo(autre.index);
}

/// La priorité désignée par [code], ou `null` si le code est inconnu.
///
/// La comparaison est exacte : 'High' ou '' donnent `null`.
Priorite? prioriteDepuisCode(String code) {
  for (final priorite in Priorite.values) {
    if (priorite.code == code) return priorite;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Échéance : une classe scellée, donc une liste de formes FERMÉE
// ---------------------------------------------------------------------------

/// L'échéance d'une tâche : aucune, une date, ou un jour de chaque semaine.
///
/// `sealed` : toutes les sous-classes sont dans ce fichier. Un `switch` sur
/// une [Echeance] est donc vérifié exhaustif par le compilateur.
sealed class Echeance {
  const Echeance();
}

/// Pas d'échéance (valeur par défaut d'une tâche).
final class SansEcheance extends Echeance {
  const SansEcheance();

  @override
  bool operator ==(Object other) => other is SansEcheance;

  @override
  int get hashCode => (SansEcheance).hashCode;

  @override
  String toString() => 'SansEcheance()';
}

/// Une échéance datée : seuls le jour, le mois et l'année comptent.
final class EcheanceDate extends Echeance {
  /// L'heure éventuelle de [date] est retirée dès la construction.
  EcheanceDate(DateTime date)
    : date = DateTime(date.year, date.month, date.day);

  /// La date, toujours à minuit (heure locale).
  final DateTime date;

  @override
  bool operator ==(Object other) => other is EcheanceDate && other.date == date;

  @override
  int get hashCode => date.hashCode;

  @override
  String toString() => 'EcheanceDate($date)';
}

/// Une échéance hebdomadaire : un jour de la semaine, de lundi (1) à
/// dimanche (7), comme [DateTime.weekday].
final class EcheanceHebdo extends Echeance {
  /// Lève une [RangeError] si [jour] n'est pas entre 1 et 7 : c'est une
  /// erreur de programmation, refusée dès la construction.
  EcheanceHebdo(int jour)
    : jour = RangeError.checkValueInInterval(
        jour,
        DateTime.monday,
        DateTime.sunday,
        'jour',
      );

  /// 1 = lundi, …, 7 = dimanche.
  final int jour;

  @override
  bool operator ==(Object other) =>
      other is EcheanceHebdo && other.jour == jour;

  @override
  int get hashCode => jour.hashCode;

  @override
  String toString() => 'EcheanceHebdo($jour)';
}

// ---------------------------------------------------------------------------
// Tâche : une classe immuable
// ---------------------------------------------------------------------------

/// Une tâche. Elle ne change jamais après sa construction : tous ses champs
/// sont `final`. « Modifier » une tâche, c'est en obtenir une nouvelle avec
/// [copyWith].
class Tache {
  /// Lève une [ArgumentError] si [id] ou [titre] est vide.
  Tache({
    required this.id,
    required this.titre,
    this.priorite = Priorite.normale,
    this.echeance = const SansEcheance(),
    this.note,
    this.faite = false,
  }) {
    if (id.isEmpty) {
      throw ArgumentError.value(
        id,
        'id',
        "l'identifiant ne doit pas être vide",
      );
    }
    if (titre.isEmpty) {
      throw ArgumentError.value(
        titre,
        'titre',
        'le titre ne doit pas être vide',
      );
    }
  }

  /// Identifiant non vide, unique dans l'application ; il ne change jamais.
  final String id;

  /// Titre non vide.
  final String titre;

  /// Priorité ([Priorite.normale] par défaut).
  final Priorite priorite;

  /// Échéance ([SansEcheance] par défaut) : jamais `null`, l'absence
  /// d'échéance est une forme d'[Echeance] à part entière.
  final Echeance echeance;

  /// Note facultative (`null` = pas de note).
  final String? note;

  /// Faite ou non (non faite par défaut).
  final bool faite;

  /// Une nouvelle tâche, de même [id], où seuls les éléments donnés diffèrent.
  /// La tâche d'origine reste intacte.
  ///
  /// `note: x ?? this.note` ne permettrait jamais de revenir à `null`.
  /// D'où [sansNote] : `copyWith(sansNote: true)` retire la note.
  Tache copyWith({
    String? titre,
    Priorite? priorite,
    Echeance? echeance,
    String? note,
    bool sansNote = false,
    bool? faite,
  }) {
    if (sansNote && note != null) {
      throw ArgumentError(
        'note et sansNote ne peuvent pas être donnés ensemble',
      );
    }
    return Tache(
      id: id,
      titre: titre ?? this.titre,
      priorite: priorite ?? this.priorite,
      echeance: echeance ?? this.echeance,
      note: sansNote ? null : (note ?? this.note),
      faite: faite ?? this.faite,
    );
  }

  // Égalité par valeur : deux tâches aux contenus identiques sont égales.
  // Utile dans les tests (expect(a, b)).
  @override
  bool operator ==(Object other) =>
      other is Tache &&
      other.id == id &&
      other.titre == titre &&
      other.priorite == priorite &&
      other.echeance == echeance &&
      other.note == note &&
      other.faite == faite;

  @override
  int get hashCode => Object.hash(id, titre, priorite, echeance, note, faite);

  @override
  String toString() =>
      'Tache(id: $id, titre: $titre, priorite: ${priorite.name}, '
      'echeance: $echeance, note: $note, faite: $faite)';
}

// ---------------------------------------------------------------------------
// A1 — Lecture d'un document JSON
// ---------------------------------------------------------------------------

/// Construit une tâche à partir d'un document JSON déjà décodé.
///
/// Lève une [FormatException] si le document ne respecte pas les règles :
/// clé obligatoire absente, mauvais type, chaîne vide, priorité inconnue,
/// "due" illisible, "note" qui n'est pas une chaîne.
Tache tacheDepuisJson(Map<String, Object?> json) {
  // Le motif vérifie en une fois : les quatre clés existent, elles ont le bon
  // type, et lie leurs valeurs. La garde `when` refuse les chaînes vides.
  if (json
      case {
        'id': String id,
        'title': String titre,
        'priority': String code,
        'done': bool faite,
      }
      when id.isNotEmpty && titre.isNotEmpty) {
    final priorite = prioriteDepuisCode(code);
    if (priorite == null) {
      throw FormatException('Priorité inconnue : "$code"', json);
    }
    return Tache(
      id: id,
      titre: titre,
      priorite: priorite,
      echeance: _echeanceDepuisJson(json['due']),
      note: _noteDepuisJson(json['note']),
      faite: faite,
    );
  }
  throw FormatException('Tâche mal formée : $json', json);
}

/// "due" absente ou `null` : pas d'échéance ; sinon une date AAAA-MM-JJ.
Echeance _echeanceDepuisJson(Object? due) => switch (due) {
  null => const SansEcheance(),
  String texte => EcheanceDate(_lireDate(texte)),
  _ => throw FormatException('"due" doit être une chaîne AAAA-MM-JJ', due),
};

/// "note" absente ou `null` : pas de note ; sinon une chaîne.
String? _noteDepuisJson(Object? note) => switch (note) {
  null => null,
  String texte => texte,
  _ => throw FormatException('"note" doit être une chaîne', note),
};

final _formeDate = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

/// Lit une date AAAA-MM-JJ qui existe vraiment (2026-02-30 est refusée).
DateTime _lireDate(String texte) {
  final correspondance = _formeDate.firstMatch(texte);
  if (correspondance == null) {
    throw FormatException('Date illisible (AAAA-MM-JJ attendu)', texte);
  }
  // Les trois groupes existent toujours quand l'expression correspond.
  final annee = int.parse(correspondance.group(1)!);
  final mois = int.parse(correspondance.group(2)!);
  final jour = int.parse(correspondance.group(3)!);
  final date = DateTime(annee, mois, jour);
  // DateTime « corrige » silencieusement 2026-02-30 en 2026-03-02 :
  // on refuse toute date qui ne se relit pas à l'identique.
  if (date.year != annee || date.month != mois || date.day != jour) {
    throw FormatException('Date inexistante', texte);
  }
  return date;
}

// ---------------------------------------------------------------------------
// A2 — Échéances et retards
// ---------------------------------------------------------------------------

const _joursSemaine = [
  'lundi',
  'mardi',
  'mercredi',
  'jeudi',
  'vendredi',
  'samedi',
  'dimanche',
];

/// Le texte d'une échéance : « sans échéance », « pour le 1/12 »,
/// « chaque samedi ».
///
/// Aucun cas par défaut : si une nouvelle forme d'[Echeance] est ajoutée,
/// ce `switch` ne compile plus tant qu'elle n'est pas traitée.
String libelleEcheance(Echeance echeance) => switch (echeance) {
  SansEcheance() => 'sans échéance',
  EcheanceDate(:final date) => 'pour le ${date.day}/${date.month}',
  EcheanceHebdo(:final jour) => 'chaque ${_joursSemaine[jour - 1]}',
};

/// Vrai si et seulement si la tâche n'est pas faite et que son échéance est
/// une date d'un jour strictement antérieur à [aujourdhui] (l'heure ne compte
/// pas). Sans échéance ou hebdomadaire : jamais en retard.
///
/// [aujourdhui] est un paramètre (et non `DateTime.now()`) pour que la
/// fonction soit testable avec une date fixe.
bool estEnRetard(Tache tache, {required DateTime aujourdhui}) {
  if (tache.faite) return false;
  return switch (tache.echeance) {
    EcheanceDate(:final date) => date.isBefore(_jourSeul(aujourdhui)),
    SansEcheance() || EcheanceHebdo() => false,
  };
}

/// Le même jour, à minuit : retire l'heure pour comparer des jours.
DateTime _jourSeul(DateTime instant) =>
    DateTime(instant.year, instant.month, instant.day);

// ---------------------------------------------------------------------------
// A3 — Bilan et tâches à faire
// ---------------------------------------------------------------------------

/// Le nombre de tâches faites et le nombre total, dans un record à champs
/// nommés. Une collection vide donne `(faites: 0, total: 0)`.
({int faites, int total}) bilan(Iterable<Tache> taches) {
  var faites = 0;
  var total = 0;
  for (final tache in taches) {
    total++;
    if (tache.faite) faites++;
  }
  return (faites: faites, total: total);
}

/// Une NOUVELLE liste : les tâches non faites de priorité au moins [auMoins],
/// de la plus urgente à la moins urgente, puis par titre.
/// La collection reçue n'est jamais modifiée.
List<Tache> aFaire(
  Iterable<Tache> taches, {
  Priorite auMoins = Priorite.basse,
}) {
  final resultat = [
    for (final tache in taches)
      if (!tache.faite && tache.priorite.compareTo(auMoins) >= 0) tache,
  ];
  resultat.sort((a, b) {
    final parPriorite = b.priorite.compareTo(a.priorite); // décroissant
    return parPriorite != 0 ? parPriorite : a.titre.compareTo(b.titre);
  });
  return resultat;
}
