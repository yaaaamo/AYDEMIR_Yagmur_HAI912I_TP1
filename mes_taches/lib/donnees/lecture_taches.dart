// Lecture d'une liste de tâches depuis un texte JSON.
//
// Pur Dart (dart:convert) : réutilisable au TP 2, quand le même texte viendra
// d'un service REST au lieu de `tachesExempleJson`.
import 'dart:convert';

import '../modele/taches.dart';

/// Décode [texte] (un tableau JSON de tâches) et construit les tâches avec
/// [tacheDepuisJson].
///
/// Lève une [FormatException] si le texte n'est pas du JSON, si ce n'est pas
/// un tableau, ou si l'un des éléments n'est pas une tâche valide.
List<Tache> tachesDepuisJsonTexte(String texte) {
  final document = jsonDecode(texte); // FormatException si JSON invalide
  if (document is! List<Object?>) {
    throw FormatException('Un tableau JSON de tâches est attendu', texte);
  }
  return [
    for (final element in document)
      switch (element) {
        Map<String, Object?> json => tacheDepuisJson(json),
        _ => throw FormatException('Tâche mal formée', element),
      },
  ];
}
