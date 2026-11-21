# Mes tâches — HAI912I · TP 1 · Fondamentaux de Dart et Flutter

## Projet

**Mes tâches** est un gestionnaire de tâches personnel écrit en Flutter : la
même application sera enrichie aux TP 2 et 3. Les données restent en mémoire et
sont perdues au redémarrage.

| | |
| --- | --- |
| Étudiante | **Yagmur AYDEMIR** — n° étudiant 22113752 — Master 2 Informatique, parcours GL |
| Travail | réalisé seule (pas de binôme) |
| Module | HAI912I — Développement mobile avancé, IoT et embarqué (enseignant : Bachar Rima), 2026–2027 |

### Fonctionnalités

- **Liste des tâches** lues depuis un document JSON d'exemple, avec un compteur
  « *n* à faire » (B1).
- **Cocher / décocher** une tâche depuis la liste (B2) ; la tâche n'est jamais
  modifiée, elle est remplacée par une nouvelle tâche (modèle immuable).
- **Filtre** « Toutes / À faire / Faites » (C1) ; le compteur reste global.
- **Tuile réutilisable** : titre barré si la tâche est faite, échéance en rouge
  si elle est en retard, indicateur de priorité (C2).
- **Mise en page robuste** : en-tête fixe, titres longs coupés par « … »,
  message si le filtre ne retient rien, aucun débordement de 360 à 1 280 px (C3).
- **Détail** d'une tâche, et action « Marquer comme faite / à faire » depuis le
  détail (D1, D2).
- **Formulaire de création validé** : titre (obligatoire, 60 caractères au
  plus), priorité, échéance (date picker, pas dans le passé), note
  (200 caractères au plus) (E1, E2).
- **Bonus** : modification (G1), suppression avec annulation (G2), tri et
  regroupement par échéance (G3), liste et détail côte à côte au-delà de 840 px
  (G4) — voir la section *Bonus*.

## Architecture

```
mes_taches/
├── lib/
│   ├── main.dart                   point d'entrée, thème (MaterialApp)
│   ├── modele/                     Dart pur, sans Flutter : testé sans interface
│   │   ├── taches.dart             contrat public : Priorite, Echeance (classe
│   │   │                           scellée), Tache (immuable, copyWith) et les six
│   │   │                           fonctions de la partie A
│   │   ├── filtre.dart             enum Filtre (C1)
│   │   ├── validation.dart         règles de saisie du formulaire (E2)
│   │   └── tri.dart                tri et regroupement par échéance (G3)
│   ├── donnees/
│   │   ├── exemples.dart           tachesExempleJson (fourni)
│   │   └── lecture_taches.dart     texte JSON → List<Tache>
│   ├── ecrans/
│   │   ├── ecran_liste.dart        écran principal, PROPRIÉTAIRE DE L'ÉTAT
│   │   │                           (tâches, filtre, tri, sélection)
│   │   ├── ecran_detail.dart       page de détail (écran étroit)
│   │   └── ecran_formulaire.dart   création et modification d'une tâche
│   └── widgets/
│       ├── tuile_tache.dart        une tâche dans la liste (sans état)
│       └── panneau_detail.dart     contenu du détail (sans état), réutilisé
│                                   par la page de détail et par le panneau G4
└── test/                           tests unitaires (modèle, validation, tri)
                                    et tests de widgets (un fichier par écran
                                    ou bonus)
```

Principes : une seule source de vérité (`_EcranListeState`) ; ce qui se déduit
de l'état (compteur, liste filtrée et triée, tâche sélectionnée) est calculé
dans `build` ; les données descendent par les constructeurs, les événements
remontent par des fonctions de rappel ; les écrans ouverts renvoient leur
résultat par `Navigator.pop`.

## Environnement

| | |
| --- | --- |
| Système | macOS 14.6.1 (Apple Silicon, arm64) |
| Flutter | **3.47.7**, canal stable (tag `3.47.7`) |
| Dart | **3.13.5** |
| DevTools | 2.60.0 |
| Éditeur | Visual Studio Code, extensions officielles **Flutter** et **Dart** |
| Dépendances | `flutter`, `cupertino_icons` ; développement : `flutter_test`, `flutter_lints` (règles de `analysis_options.yaml`) |

> Flutter 3.50 signale `package:flutter/material.dart` comme obsolète
> (`deprecated_member_use`). Le projet utilise la version du cours, 3.47.7, avec
> laquelle `flutter analyze` ne signale aucun problème.

## Plateformes

| Plateforme | Matériel | Commande |
| --- | --- | --- |
| **Web** (obligatoire) | Google Chrome 153 | `flutter run -d chrome` |
| **Android** | émulateur Pixel 9a, API 36 (Android 16), image Google Play ARM64 | `flutter run -d emulator-5554` |

Les deux cibles ont été essayées ; `flutter build web` et
`flutter build apk --debug` réussissent.

## Installation

Depuis une copie propre (un dossier au chemin court, sans espaces ni accents) :

```bash
cd mes_taches
flutter create --platforms=web,android .   # (re)crée web/ et android/ sans toucher à lib/ ni test/
flutter pub get
```

Pour Android : Android Studio, SDK Platform 36, Build-Tools, Command-line Tools,
Platform-Tools et Emulator ; puis `flutter emulators --launch <id>`.

## Exécution et tests

```bash
flutter run -d chrome          # Web
flutter devices                # liste les appareils
flutter run -d emulator-5554   # Android (identifiant donné par flutter devices)

flutter test                   # tous les tests : All tests passed!
flutter analyze                # No issues found!
dart format lib test           # mise en forme officielle
flutter build web              # construit build/web
flutter build apk --debug      # construit l'APK de débogage
```

Pendant `flutter run` : `r` rechargement à chaud, `R` redémarrage, `q` quitter.

Les tests (132 au total) couvrent le modèle (`modele_test.dart`, contrat public
de la partie A), la lecture JSON, la validation, le filtre, le tri, et chaque
écran par des tests de widgets, dont les scénarios des points de contrôle B à
E et un test de chaque bonus.

## Limites

- Les données ne sont pas persistantes : tout est perdu au redémarrage
  (persistance prévue au TP 3).
- La création et la modification ne proposent pas d'échéance **hebdomadaire**
  (seulement « aucune » ou une date) ; une échéance hebdomadaire existante est
  conservée telle quelle lors d'une modification.
- En modification, une échéance déjà passée et laissée inchangée est acceptée
  (choix délibéré, pour pouvoir corriger le titre d'une tâche en retard) ; toute
  date choisie dans le formulaire doit être aujourd'hui ou plus tard.
- La suppression ne se fait que depuis la liste (glisser vers la gauche), pas
  depuis le détail.
- Les textes de l'interface sont en français, sans localisation (le date picker
  utilise la langue par défaut de Flutter).

## Bonus

| Bonus | Où le voir | Tests |
| --- | --- | --- |
| **G1** Modifier une tâche | Détail → bouton **Modifier** : même formulaire, pré-rempli ; la tâche garde son identifiant et son état | `test/modification_test.dart` |
| **G2** Supprimer, avec annulation | Liste : faire glisser une tâche vers la gauche ; **Annuler** dans la SnackBar la remet à sa place | `test/suppression_test.dart` |
| **G3** Trier et regrouper | Barre d'application → icône de tri : ordre de saisie, priorité, échéance, titre ; par échéance, en-têtes *En retard / Datées / Hebdomadaires / Sans échéance* | `test/tri_test.dart`, `test/tri_widget_test.dart` |
| **G4** Mise en page adaptative | Fenêtre de plus de 840 px : toucher une tâche affiche son détail à droite de la liste ; en dessous, la navigation de la partie D | `test/adaptatif_test.dart` |

## Liens

- Dépôt Git : <https://github.com/yaaaamo/AYDEMIR_Yagmur_HAI912I_TP1>
  (tag `v1-obligatoire` : version sans bonus)
- Vidéo de démonstration : <https://youtu.be/SgEqzuNEtvM>
