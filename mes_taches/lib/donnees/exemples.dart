// Données d'exemple de « Mes tâches », au format JSON (HAI912I, TP 1).
//
// C'est la forme qu'aura, au TP 2, la réponse du service REST de l'application.
// Ce fichier ne contient que du texte.
// Il faut le lire et en faire des tâches, avec votre modèle.
// `jsonDecode`, de la bibliothèque `dart:convert`,
// transforme ce texte en une `List<dynamic>` de `Map<String, dynamic>`.
library;

const tachesExempleJson = '''
[
  {"id": "t1", "title": "Installer Flutter", "priority": "high", "done": true},
  {"id": "t2", "title": "Relire le CM 01", "priority": "normal",
   "done": false, "note": "records, patterns, classes scellées"},
  {"id": "t3", "title": "Faire les courses", "priority": "low",
   "done": false, "note": "pain, lait, café"},
  {"id": "t4", "title": "Appeler le dentiste", "priority": "normal",
   "done": false, "due": "2026-11-20"},
  {"id": "t5", "title": "Renouveler le passeport", "priority": "high",
   "done": false, "due": "2027-01-15"},
  {"id": "t6", "title": "Rendre la convention de stage", "priority": "normal",
   "done": false, "due": "2026-11-02"}
]
''';
