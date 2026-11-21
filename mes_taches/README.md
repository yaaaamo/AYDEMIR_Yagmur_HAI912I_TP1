# Mes tâches : projet de démarrage du TP 1
« Mes tâches » est un petit gestionnaire de tâches personnel.
C'est l'application que vous développerez tout au long des TP 1, 2 et 3.
Ce projet en est le point de départ.
Il se lance, mais **il ne contient ni modèle, ni écran de liste, ni tests des exercices**.
Vous les concevez et les écrivez en suivant le sujet du TP 1.

| Fichier                                 | Rôle                                                          |
| --------------------------------------- | ------------------------------------------------------------- |
| `lib/main.dart`                         | point d'entrée, thème ; un écran provisoire, à remplacer (B1) |
| `lib/donnees/exemples.dart`             | `tachesExempleJson` : quelques tâches au format JSON (A1, B1) |
| `test/widget_test.dart`                 | un premier test de widget, qui passe ; à garder               |
| `pubspec.yaml`, `analysis_options.yaml` | dépendances, règles de l'analyseur (`flutter_lints`)          |

Organisation suggérée de votre code (adaptez-la si vous la justifiez) :
`lib/modele/` pour le modèle (dont `lib/modele/taches.dart`, imposé par le contrat public du sujet),
`lib/ecrans/` pour les écrans,
`lib/widgets/` pour les widgets réutilisables,
`test/` pour vos tests.

## Démarrer
Copiez le dossier dans un chemin **court**, sans espaces ni accents (par exemple `C:\dev\mes_taches` sous Windows), puis, dans ce dossier :

```
flutter create --platforms=web,android .
flutter pub get
flutter run -d chrome
```

La première commande crée les dossiers `web/` et `android/` sans toucher à `lib/` ni à `test/`.
Sur Android (si votre poste est configuré) : `flutter devices`, puis `flutter run -d <id>`.

## Vérifier votre travail

```
flutter test
flutter analyze
flutter build web
```

Au départ, le seul test fourni passe et `flutter analyze` ne signale aucun problème.
Ensuite, ce sont **vos** tests qui vérifient votre travail.