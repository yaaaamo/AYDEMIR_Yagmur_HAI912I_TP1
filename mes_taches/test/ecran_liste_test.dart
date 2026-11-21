// Tests de widgets de l'écran de liste (parties B et C).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mes_taches/ecrans/ecran_liste.dart';
import 'package:mes_taches/modele/filtre.dart';
import 'package:mes_taches/modele/taches.dart';

/// Monte un écran dans une MaterialApp (thème, Navigator, textes Material).
Widget enApp(Widget ecran) => MaterialApp(home: ecran);

/// La case à cocher de la tâche dont le titre est [titre].
Finder caseDe(String titre) => find.descendant(
  of: find.widgetWithText(ListTile, titre),
  matching: find.byType(Checkbox),
);

/// Trois tâches : deux à faire, une faite.
List<Tache> troisTaches() => [
  Tache(id: 'a', titre: 'Courses'),
  Tache(id: 'b', titre: 'Dentiste'),
  Tache(id: 'c', titre: 'Installer', faite: true),
];

/// Choisit un filtre dans le sélecteur.
Future<void> filtrer(WidgetTester tester, String libelle) async {
  await tester.tap(
    find.descendant(
      of: find.byType(SegmentedButton<Filtre>),
      matching: find.text(libelle),
    ),
  );
  await tester.pump();
}

void main() {
  // ---------------------------------------------------------------- B1, B2
  testWidgets('affiche les tâches lues dans le JSON et le compteur', (
    tester,
  ) async {
    await tester.pumpWidget(enApp(const EcranListe()));

    // Données d'exemple : 6 tâches dont une seule faite.
    expect(find.text('5 à faire'), findsOneWidget);
    expect(find.text('Installer Flutter'), findsOneWidget);
    expect(find.text('Relire le CM 01'), findsOneWidget);
  });

  testWidgets('chaque tâche affiche sa priorité', (tester) async {
    await tester.pumpWidget(
      enApp(
        EcranListe(
          tachesInitiales: [
            Tache(id: 'a', titre: 'Passeport', priorite: Priorite.haute),
          ],
        ),
      ),
    );

    expect(find.text('Haute'), findsOneWidget);
  });

  testWidgets('cocher puis décocher une tâche met à jour le compteur', (
    tester,
  ) async {
    await tester.pumpWidget(
      enApp(
        EcranListe(
          tachesInitiales: [
            Tache(id: 'a', titre: 'Courses'),
            Tache(id: 'b', titre: 'Dentiste'),
          ],
        ),
      ),
    );
    expect(find.text('2 à faire'), findsOneWidget);

    await tester.tap(caseDe('Courses'));
    await tester.pump(); // reconstruire après setState
    expect(find.text('1 à faire'), findsOneWidget);
    expect(tester.widget<Checkbox>(caseDe('Courses')).value, isTrue);

    await tester.tap(caseDe('Courses'));
    await tester.pump();
    expect(find.text('2 à faire'), findsOneWidget);
    expect(tester.widget<Checkbox>(caseDe('Courses')).value, isFalse);
  });

  testWidgets('cocher une tâche ne touche pas aux autres', (tester) async {
    await tester.pumpWidget(
      enApp(
        EcranListe(
          tachesInitiales: [
            Tache(id: 'a', titre: 'Courses'),
            Tache(id: 'b', titre: 'Dentiste'),
          ],
        ),
      ),
    );

    await tester.tap(caseDe('Dentiste'));
    await tester.pump();

    expect(tester.widget<Checkbox>(caseDe('Dentiste')).value, isTrue);
    expect(tester.widget<Checkbox>(caseDe('Courses')).value, isFalse);
  });

  testWidgets('« Ajouter » ajoute une tâche et augmente le compteur', (
    tester,
  ) async {
    await tester.pumpWidget(enApp(const EcranListe(tachesInitiales: [])));
    expect(find.text('0 à faire'), findsOneWidget);

    await tester.tap(find.text('Ajouter'));
    await tester.pump();
    await tester.tap(find.text('Ajouter'));
    await tester.pump();

    expect(find.text('2 à faire'), findsOneWidget);
    expect(find.text('Tâche 1'), findsOneWidget);
    expect(find.text('Tâche 2'), findsOneWidget);
  });

  // -------------------------------------------------------------------- C1
  testWidgets('« Toutes » est le filtre par défaut', (tester) async {
    await tester.pumpWidget(enApp(EcranListe(tachesInitiales: troisTaches())));

    expect(find.text('Courses'), findsOneWidget);
    expect(find.text('Dentiste'), findsOneWidget);
    expect(find.text('Installer'), findsOneWidget);
  });

  testWidgets('« À faire » et « Faites » filtrent, le compteur reste global', (
    tester,
  ) async {
    await tester.pumpWidget(enApp(EcranListe(tachesInitiales: troisTaches())));

    await filtrer(tester, 'À faire');
    expect(find.text('Courses'), findsOneWidget);
    expect(find.text('Dentiste'), findsOneWidget);
    expect(find.text('Installer'), findsNothing);
    expect(find.text('2 à faire'), findsOneWidget);

    await filtrer(tester, 'Faites');
    expect(find.text('Courses'), findsNothing);
    expect(find.text('Installer'), findsOneWidget);
    expect(find.text('2 à faire'), findsOneWidget);
  });

  testWidgets('avec « À faire », cocher fait disparaître la tâche', (
    tester,
  ) async {
    await tester.pumpWidget(enApp(EcranListe(tachesInitiales: troisTaches())));
    await filtrer(tester, 'À faire');

    await tester.tap(caseDe('Courses'));
    await tester.pump();

    expect(find.text('Courses'), findsNothing);
    expect(find.text('1 à faire'), findsOneWidget);

    await filtrer(tester, 'Faites');
    expect(find.text('Courses'), findsOneWidget);
  });

  testWidgets('décocher depuis « Faites » fait réapparaître dans « À faire »', (
    tester,
  ) async {
    await tester.pumpWidget(enApp(EcranListe(tachesInitiales: troisTaches())));
    await filtrer(tester, 'Faites');

    await tester.tap(caseDe('Installer'));
    await tester.pump();
    expect(find.text('Installer'), findsNothing);

    await filtrer(tester, 'À faire');
    expect(find.text('Installer'), findsOneWidget);
    expect(find.text('3 à faire'), findsOneWidget);
  });

  // -------------------------------------------------------------------- C3
  testWidgets('un message centré remplace une liste filtrée vide', (
    tester,
  ) async {
    await tester.pumpWidget(
      enApp(
        EcranListe(
          tachesInitiales: [Tache(id: 'a', titre: 'Courses')],
        ),
      ),
    );
    await filtrer(tester, 'Faites');

    expect(find.text('Aucune tâche faite'), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
  });

  const titreLong =
      'Un titre vraiment très long pour vérifier que la tuile ne déborde '
      'jamais, même sur un écran étroit de téléphone';

  for (final largeur in [360.0, 1280.0]) {
    testWidgets('aucun débordement à ${largeur.toInt()} px, titre long', (
      tester,
    ) async {
      tester.view.physicalSize = Size(largeur, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        enApp(
          EcranListe(
            tachesInitiales: [
              Tache(
                id: 'a',
                titre: titreLong,
                priorite: Priorite.haute,
                echeance: EcheanceDate(DateTime(2020, 1, 1)),
              ),
              ...troisTaches(),
            ],
          ),
        ),
      );

      // Un débordement lèverait une exception, récupérée ici.
      expect(tester.takeException(), isNull);
      // Le titre est sur une seule ligne, coupé par « … ».
      final titre = tester.widget<Text>(find.text(titreLong));
      expect(titre.maxLines, 1);
      expect(titre.overflow, TextOverflow.ellipsis);
    });
  }

  testWidgets('le compteur et le filtre restent fixes quand la liste défile', (
    tester,
  ) async {
    await tester.pumpWidget(
      enApp(
        EcranListe(
          tachesInitiales: [
            for (var i = 0; i < 40; i++) Tache(id: '$i', titre: 'Tâche n°$i'),
          ],
        ),
      ),
    );
    final avant = tester.getTopLeft(find.text('40 à faire'));

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();

    expect(tester.getTopLeft(find.text('40 à faire')), avant);
    expect(find.text('Tâche n°0'), findsNothing); // la liste a bien défilé
  });

  // ---------------------------------------------------------------- D1, D2
  /// Quatre tâches dont la première est faite : avec le filtre « À faire »,
  /// la 2e tâche AFFICHÉE (Dentiste) n'est pas la 2e de la liste complète
  /// (Courses). C'est le piège signalé par le sujet.
  List<Tache> quatreTaches() => [
    Tache(id: 'i', titre: 'Installer', faite: true),
    Tache(id: 'c', titre: 'Courses'),
    Tache(id: 'd', titre: 'Dentiste', note: 'carte vitale'),
    Tache(id: 'b', titre: 'Banque'),
  ];

  testWidgets('toucher une tâche ouvre son détail, retour sans rien changer', (
    tester,
  ) async {
    await tester.pumpWidget(enApp(EcranListe(tachesInitiales: quatreTaches())));

    await tester.tap(find.text('Dentiste'));
    await tester.pumpAndSettle(); // animation de push
    expect(find.text('Détail de la tâche'), findsOneWidget);
    expect(find.text('carte vitale'), findsOneWidget);

    await tester.pageBack(); // bouton retour de la barre d'application
    await tester.pumpAndSettle();
    expect(find.text('Mes tâches'), findsOneWidget);
    expect(find.text('3 à faire'), findsOneWidget); // rien n'a changé
    expect(tester.widget<Checkbox>(caseDe('Dentiste')).value, isFalse);
  });

  testWidgets('avec « À faire », marquer faite la 2e tâche affichée depuis le '
      'détail modifie la bonne tâche', (tester) async {
    await tester.pumpWidget(enApp(EcranListe(tachesInitiales: quatreTaches())));
    await filtrer(tester, 'À faire');

    // La 2e tâche affichée : Dentiste.
    final tuiles = find.byType(ListTile);
    expect(
      find.descendant(of: tuiles.at(1), matching: find.text('Dentiste')),
      findsOneWidget,
    );
    await tester.tap(find.text('Dentiste'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Marquer comme faite'));
    await tester.pumpAndSettle(); // animation de pop

    // De retour à la liste : Dentiste a disparu, le compteur a baissé de un.
    expect(find.text('Dentiste'), findsNothing);
    expect(find.text('2 à faire'), findsOneWidget);
    expect(find.text('Courses'), findsOneWidget); // pas la mauvaise tâche

    await filtrer(tester, 'Faites');
    expect(find.text('Dentiste'), findsOneWidget);
    expect(find.text('Courses'), findsNothing);
  });

  testWidgets('« Marquer à faire » depuis le détail décoche la tâche', (
    tester,
  ) async {
    await tester.pumpWidget(enApp(EcranListe(tachesInitiales: quatreTaches())));

    await tester.tap(find.text('Installer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marquer à faire'));
    await tester.pumpAndSettle();

    expect(find.text('4 à faire'), findsOneWidget);
    expect(tester.widget<Checkbox>(caseDe('Installer')).value, isFalse);
  });
}
