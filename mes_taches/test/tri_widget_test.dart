// Tests de widgets du bonus G3 : menu de tri et regroupement par échéance.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mes_taches/ecrans/ecran_liste.dart';
import 'package:mes_taches/modele/filtre.dart';
import 'package:mes_taches/modele/taches.dart';

DateTime horloge() => DateTime(2026, 11, 21, 15);

Widget liste() => MaterialApp(
  home: EcranListe(
    horloge: horloge,
    tachesInitiales: [
      Tache(id: '1', titre: 'Courses', priorite: Priorite.basse),
      Tache(
        id: '2',
        titre: 'Passeport',
        priorite: Priorite.haute,
        echeance: EcheanceDate(DateTime(2027, 1, 15)),
      ),
      Tache(
        id: '3',
        titre: 'Dentiste',
        echeance: EcheanceDate(DateTime(2026, 11, 20)),
      ),
      Tache(id: '4', titre: 'Sport', echeance: EcheanceHebdo(DateTime.monday)),
    ],
  ),
);

/// Les titres des tâches affichées, dans l'ordre de la liste.
List<String> titresAffiches(WidgetTester tester) => [
  for (final tuile in tester.widgetList<ListTile>(find.byType(ListTile)))
    (tuile.title! as Text).data!,
];

Future<void> choisirTri(WidgetTester tester, String libelle) async {
  await tester.tap(find.byTooltip('Trier'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(libelle).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("par défaut, l'ordre de saisie", (tester) async {
    await tester.pumpWidget(liste());
    expect(titresAffiches(tester), [
      'Courses',
      'Passeport',
      'Dentiste',
      'Sport',
    ]);
  });

  testWidgets('le menu trie par titre puis par priorité', (tester) async {
    await tester.pumpWidget(liste());

    await choisirTri(tester, 'Par titre');
    expect(titresAffiches(tester), [
      'Courses',
      'Dentiste',
      'Passeport',
      'Sport',
    ]);

    await choisirTri(tester, 'Par priorité');
    expect(titresAffiches(tester), [
      'Passeport', // haute
      'Dentiste', // normale
      'Sport', // normale
      'Courses', // basse
    ]);
  });

  testWidgets('par échéance, la liste est regroupée sous des en-têtes', (
    tester,
  ) async {
    await tester.pumpWidget(liste());

    await choisirTri(tester, 'Par échéance');

    expect(titresAffiches(tester), [
      'Dentiste', // en retard
      'Passeport', // datée
      'Sport', // hebdomadaire
      'Courses', // sans échéance
    ]);
    // Les quatre en-têtes, dans l'ordre, chacun au-dessus de sa tâche.
    final enTetes = ['En retard', 'Datées', 'Hebdomadaires', 'Sans échéance'];
    final taches = ['Dentiste', 'Passeport', 'Sport', 'Courses'];
    for (var i = 0; i < enTetes.length; i++) {
      final yEnTete = tester.getTopLeft(find.text(enTetes[i])).dy;
      expect(yEnTete, lessThan(tester.getTopLeft(find.text(taches[i])).dy));
      if (i > 0) {
        expect(
          yEnTete,
          greaterThan(tester.getTopLeft(find.text(taches[i - 1])).dy),
        );
      }
    }
  });

  testWidgets('un groupe vide n\'a pas d\'en-tête ; filtre et tri se '
      'combinent', (tester) async {
    await tester.pumpWidget(liste());
    await choisirTri(tester, 'Par échéance');

    // Cocher Dentiste : il n'est plus en retard (il passe dans « Datées »).
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Dentiste'),
        matching: find.byType(Checkbox),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('En retard'), findsNothing);

    // Filtre « À faire » : la tâche faite disparaît, le tri reste actif.
    await tester.tap(
      find.descendant(
        of: find.byType(SegmentedButton<Filtre>),
        matching: find.text('À faire'),
      ),
    );
    await tester.pumpAndSettle();
    expect(titresAffiches(tester), ['Passeport', 'Sport', 'Courses']);
    expect(find.text('Hebdomadaires'), findsOneWidget);
  });
}
