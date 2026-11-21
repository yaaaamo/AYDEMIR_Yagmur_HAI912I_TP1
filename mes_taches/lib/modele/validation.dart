/// Règles de saisie du formulaire de tâche (partie E2).
///
/// Ce sont des fonctions ordinaires, sans Flutter : elles se testent seules.
/// Chacune renvoie le message à afficher sous le champ, ou null si la saisie
/// est correcte (c'est la forme attendue par `TextFormField.validator`).
library;

const titreMax = 60;
const noteMax = 200;

/// Titre obligatoire (des espaces seuls ne comptent pas), [titreMax]
/// caractères au plus une fois les espaces de bord retirés.
String? validerTitre(String? saisie) {
  final titre = saisie?.trim() ?? '';
  if (titre.isEmpty) return 'Le titre est obligatoire';
  if (titre.length > titreMax) return '$titreMax caractères au plus';
  return null;
}

/// Note facultative, [noteMax] caractères au plus une fois les espaces de
/// bord retirés.
String? validerNote(String? saisie) {
  final note = saisie?.trim() ?? '';
  if (note.length > noteMax) return '$noteMax caractères au plus';
  return null;
}

/// Une échéance datée ne peut pas être antérieure à [aujourdhui] (le jour
/// même est accepté ; l'heure ne compte pas). Pas d'échéance : correct.
String? validerEcheance(DateTime? date, {required DateTime aujourdhui}) {
  if (date == null) return null;
  final jour = DateTime(date.year, date.month, date.day);
  final debut = DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day);
  if (jour.isBefore(debut)) {
    return "L'échéance ne peut pas être antérieure à aujourd'hui";
  }
  return null;
}

/// Le texte saisi pour la note, ou null s'il est vide après retrait des
/// espaces de bord (une note vide équivaut à « pas de note »).
String? noteNettoyee(String saisie) {
  final note = saisie.trim();
  return note.isEmpty ? null : note;
}
