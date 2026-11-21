// Tests de widgets du bonus G2 : supprimer une tâche, avec annulation.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mes_taches/ecrans/ecran_liste.dart';
import 'package:mes_taches/modele/filtre.dart';
import 'package:mes_taches/modele/taches.dart';

Widget liste(List<Tache> taches) =>
    MaterialApp(home: EcranListe(tachesInitiales: taches));

List<Tache> troisTaches() => [
  Tache(id: 'a', titre: 'Courses'),
  Tache(id: 'b', titre: 'Dentiste'),
  Tache(id: 'c', titre: 'Banque'),
];

/// Fait glisser la tâche [titre] vers la gauche, jusqu'à la supprimer.
Future<void> glisser(WidgetTester tester, String titre) async {
  await tester.drag(find.text(titre), const Offset(-600, 0));
  await tester.pumpAndSettle(); // animations de glissement et de SnackBar
}

/// Les titres affichés, dans l'ordre de la liste.
List<String> titresAffiches(WidgetTester tester) => [
  for (final tuile in tester.widgetList<ListTile>(find.byType(ListTile)))
    (tuile.title! as Text).data!,
];

void main() {
  testWidgets('glisser une tâche la supprime et affiche « Annuler »', (
    tester,
  ) async {
    await tester.pumpWidget(liste(troisTaches()));
    expect(find.text('3 à faire'), findsOneWidget);

    await glisser(tester, 'Dentiste');

    expect(find.text('Dentiste'), findsNothing);
    expect(find.text('2 à faire'), findsOneWidget);
    expect(find.text('« Dentiste » supprimée'), findsOneWidget);
    expect(find.text('Annuler'), findsOneWidget);
  });

  testWidgets('« Annuler » remet la tâche à la même place', (tester) async {
    await tester.pumpWidget(liste(troisTaches()));

    await glisser(tester, 'Dentiste');
    expect(titresAffiches(tester), ['Courses', 'Banque']);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(titresAffiches(tester), ['Courses', 'Dentiste', 'Banque']);
    expect(find.text('3 à faire'), findsOneWidget);
  });

  testWidgets('avec un filtre, la tâche revient à sa place dans la liste '
      'complète', (tester) async {
    await tester.pumpWidget(
      liste([
        Tache(id: 'i', titre: 'Installer', faite: true),
        ...troisTaches(),
      ]),
    );
    await tester.tap(
      find.descendant(
        of: find.byType(SegmentedButton<Filtre>),
        matching: find.text('À faire'),
      ),
    );
    await tester.pumpAndSettle();

    await glisser(tester, 'Courses');
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(SegmentedButton<Filtre>),
        matching: find.text('Toutes'),
      ),
    );
    await tester.pumpAndSettle();
    expect(titresAffiches(tester), [
      'Installer',
      'Courses',
      'Dentiste',
      'Banque',
    ]);
  });

  testWidgets('sans annulation, la suppression est définitive', (tester) async {
    await tester.pumpWidget(liste(troisTaches()));

    await glisser(tester, 'Banque');
    // La SnackBar disparaît d'elle-même (ou est fermée) : rien ne revient.
    ScaffoldMessenger.of(tester.element(find.byType(EcranListe)))
        .hideCurrentSnackBar();
    await tester.pumpAndSettle();

    expect(find.text('Banque'), findsNothing);
    expect(find.text('Annuler'), findsNothing);
    expect(find.text('2 à faire'), findsOneWidget);
  });
}
