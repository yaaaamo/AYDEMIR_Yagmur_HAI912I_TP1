// Tests de widgets du bonus G1 : modifier une tâche depuis son détail.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mes_taches/ecrans/ecran_liste.dart';
import 'package:mes_taches/modele/taches.dart';

DateTime horloge() => DateTime(2026, 11, 21, 15);

Widget liste(List<Tache> taches) => MaterialApp(
  home: EcranListe(tachesInitiales: taches, horloge: horloge),
);

Finder champ(String libelle) => find.widgetWithText(TextFormField, libelle);

Finder caseDe(String titre) => find.descendant(
  of: find.widgetWithText(ListTile, titre),
  matching: find.byType(Checkbox),
);

/// Ouvre le détail de [titre], puis le formulaire de modification.
Future<void> modifier(WidgetTester tester, String titre) async {
  await tester.tap(find.text(titre));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Modifier'));
  await tester.pumpAndSettle();
  expect(find.text('Modifier la tâche'), findsOneWidget);
}

Future<void> enregistrer(WidgetTester tester) async {
  await tester.tap(find.text('Enregistrer'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('le formulaire de modification est pré-rempli', (tester) async {
    await tester.pumpWidget(
      liste([
        Tache(
          id: 'd',
          titre: 'Dentiste',
          priorite: Priorite.haute,
          echeance: EcheanceDate(DateTime(2026, 12, 1)),
          note: 'carte vitale',
        ),
      ]),
    );
    await modifier(tester, 'Dentiste');

    expect(find.widgetWithText(TextFormField, 'Dentiste'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'carte vitale'), findsOneWidget);
    expect(find.text('Haute'), findsOneWidget);
    expect(find.text('pour le 1/12'), findsOneWidget);
  });

  testWidgets('enregistrer remplace la tâche (même identifiant) dans la liste', (
    tester,
  ) async {
    await tester.pumpWidget(
      liste([
        Tache(id: 'c', titre: 'Courses'),
        Tache(id: 'b', titre: 'Banque'),
      ]),
    );
    await modifier(tester, 'Courses');

    await tester.enterText(champ('Titre'), 'Courses bio');
    await enregistrer(tester);

    // Retour direct à la liste : le détail s'est fermé.
    expect(find.text('Mes tâches'), findsOneWidget);
    expect(find.text('Courses bio'), findsOneWidget);
    expect(find.text('Courses'), findsNothing);
    // Remplacée, pas ajoutée : toujours deux tâches, à la même place.
    expect(find.text('2 à faire'), findsOneWidget);
    final tuiles = find.byType(ListTile);
    expect(
      find.descendant(of: tuiles.at(0), matching: find.text('Courses bio')),
      findsOneWidget,
    );
  });

  testWidgets("la modification garde l'état « faite »", (tester) async {
    await tester.pumpWidget(
      liste([Tache(id: 'i', titre: 'Installer', faite: true)]),
    );
    await modifier(tester, 'Installer');

    await tester.enterText(champ('Titre'), 'Installer Flutter');
    await enregistrer(tester);

    expect(tester.widget<Checkbox>(caseDe('Installer Flutter')).value, isTrue);
    expect(find.text('0 à faire'), findsOneWidget);
  });

  testWidgets('vider la note retire la note', (tester) async {
    await tester.pumpWidget(
      liste([Tache(id: 'd', titre: 'Dentiste', note: 'carte vitale')]),
    );
    await modifier(tester, 'Dentiste');

    await tester.enterText(champ('Note (facultative)'), '');
    await enregistrer(tester);

    await tester.tap(find.text('Dentiste'));
    await tester.pumpAndSettle();
    expect(find.text('Aucune note'), findsOneWidget);
  });

  testWidgets('une échéance déjà passée et inchangée ne bloque pas la '
      'modification', (tester) async {
    await tester.pumpWidget(
      liste([
        Tache(
          id: 'r',
          titre: 'Convention',
          echeance: EcheanceDate(DateTime(2026, 11, 2)),
        ),
      ]),
    );
    await modifier(tester, 'Convention');

    await tester.enterText(champ('Titre'), 'Rendre la convention');
    await enregistrer(tester);

    expect(find.text('Rendre la convention'), findsOneWidget);
    expect(find.text('pour le 2/11 · en retard'), findsOneWidget);
  });

  testWidgets('revenir sans enregistrer ne change rien', (tester) async {
    await tester.pumpWidget(liste([Tache(id: 'c', titre: 'Courses')]));
    await modifier(tester, 'Courses');

    await tester.enterText(champ('Titre'), 'Autre chose');
    await tester.pageBack(); // quitte le formulaire
    await tester.pumpAndSettle();
    await tester.pageBack(); // quitte le détail
    await tester.pumpAndSettle();

    expect(find.text('Courses'), findsOneWidget);
    expect(find.text('Autre chose'), findsNothing);
  });

  testWidgets('le formulaire sert toujours à la création', (tester) async {
    await tester.pumpWidget(liste([]));
    await tester.tap(find.text('Ajouter'));
    await tester.pumpAndSettle();

    expect(find.text('Nouvelle tâche'), findsOneWidget);
    await tester.enterText(champ('Titre'), 'Lire');
    await enregistrer(tester);
    expect(find.text('Lire'), findsOneWidget);
  });
}