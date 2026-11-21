// Tests de widgets du formulaire de création (parties E1 et E2), depuis la
// liste : on vérifie le parcours complet, jusqu'au retour dans la liste.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mes_taches/ecrans/ecran_liste.dart';
import 'package:mes_taches/modele/taches.dart';

/// Date fixe : le date picker s'ouvre sur novembre 2026, quel que soit le jour
/// où les tests sont lancés.
DateTime horloge() => DateTime(2026, 11, 21, 15);

/// La liste avec une seule tâche (à faire), dans une MaterialApp.
Widget liste() => MaterialApp(
  home: EcranListe(
    tachesInitiales: [Tache(id: 'x', titre: 'Existante')],
    horloge: horloge,
  ),
);

Finder champ(String libelle) => find.widgetWithText(TextFormField, libelle);

Future<void> ouvrirFormulaire(WidgetTester tester) async {
  await tester.tap(find.text('Ajouter'));
  await tester.pumpAndSettle(); // animation de push
  expect(find.text('Nouvelle tâche'), findsOneWidget);
}

Future<void> enregistrer(WidgetTester tester) async {
  await tester.tap(find.text('Enregistrer'));
  await tester.pumpAndSettle(); // messages d'erreur, ou animation de pop
}

void main() {
  // ---------------------------------------------------------------- E2
  testWidgets('un formulaire vide affiche un message et reste ouvert', (
    tester,
  ) async {
    await tester.pumpWidget(liste());
    await ouvrirFormulaire(tester);

    await enregistrer(tester);

    expect(find.text('Le titre est obligatoire'), findsOneWidget);
    expect(find.text('Nouvelle tâche'), findsOneWidget); // toujours ouvert
  });

  testWidgets('un titre fait d\'espaces est refusé', (tester) async {
    await tester.pumpWidget(liste());
    await ouvrirFormulaire(tester);

    await tester.enterText(champ('Titre'), '    ');
    await enregistrer(tester);

    expect(find.text('Le titre est obligatoire'), findsOneWidget);
    expect(find.text('Nouvelle tâche'), findsOneWidget);
  });

  testWidgets('un titre de 61 caractères est refusé, 60 est accepté', (
    tester,
  ) async {
    await tester.pumpWidget(liste());
    await ouvrirFormulaire(tester);

    await tester.enterText(champ('Titre'), 'a' * 61);
    await enregistrer(tester);
    expect(find.text('60 caractères au plus'), findsOneWidget);
    expect(find.text('Nouvelle tâche'), findsOneWidget);

    await tester.enterText(champ('Titre'), 'a' * 60);
    await enregistrer(tester);
    expect(find.text('Nouvelle tâche'), findsNothing); // formulaire fermé
    expect(find.text('a' * 60), findsOneWidget); // dans la liste
  });

  testWidgets('une note de 201 caractères est refusée', (tester) async {
    await tester.pumpWidget(liste());
    await ouvrirFormulaire(tester);

    await tester.enterText(champ('Titre'), 'Lire');
    await tester.enterText(champ('Note (facultative)'), 'n' * 201);
    await enregistrer(tester);

    expect(find.text('200 caractères au plus'), findsOneWidget);
    expect(find.text('Nouvelle tâche'), findsOneWidget);
  });

  // ---------------------------------------------------------------- E1
  testWidgets('une tâche valide avec échéance apparaît dans la liste avec le '
      'bon libellé, et le compteur augmente', (tester) async {
    await tester.pumpWidget(liste());
    expect(find.text('1 à faire'), findsOneWidget);
    await ouvrirFormulaire(tester);

    await tester.enterText(champ('Titre'), 'Dentiste');

    // Priorité : Haute.
    await tester.tap(find.byType(DropdownButtonFormField<Priorite>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Haute').last);
    await tester.pumpAndSettle();

    // Échéance : le 25 novembre, choisie dans le date picker.
    await tester.tap(find.byTooltip('Choisir une date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('25'));
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('pour le 25/11'), findsOneWidget); // dans le formulaire

    await enregistrer(tester);

    expect(find.text('Nouvelle tâche'), findsNothing);
    expect(find.text('Dentiste'), findsOneWidget);
    expect(find.text('pour le 25/11'), findsOneWidget); // dans la liste
    expect(find.text('Haute'), findsOneWidget);
    expect(find.text('2 à faire'), findsOneWidget);
  });

  testWidgets('les espaces de bord sont retirés, une note vide = pas de note', (
    tester,
  ) async {
    await tester.pumpWidget(liste());
    await ouvrirFormulaire(tester);

    await tester.enterText(champ('Titre'), '   Lire   ');
    await tester.enterText(champ('Note (facultative)'), '     ');
    await enregistrer(tester);

    expect(find.text('Lire'), findsOneWidget); // titre sans espaces
    await tester.tap(find.text('Lire'));
    await tester.pumpAndSettle();
    expect(find.text('Aucune note'), findsOneWidget);
  });

  testWidgets('revenir en arrière sans enregistrer n\'ajoute rien', (
    tester,
  ) async {
    await tester.pumpWidget(liste());
    await ouvrirFormulaire(tester);

    await tester.enterText(champ('Titre'), 'Abandonnée');
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Abandonnée'), findsNothing);
    expect(find.text('1 à faire'), findsOneWidget);
  });

  testWidgets('deux créations de même titre donnent deux tâches distinctes', (
    tester,
  ) async {
    await tester.pumpWidget(liste());
    for (var i = 0; i < 2; i++) {
      await ouvrirFormulaire(tester);
      await tester.enterText(champ('Titre'), 'Lire');
      await enregistrer(tester);
    }
    expect(find.text('Lire'), findsNWidgets(2));
    expect(find.text('3 à faire'), findsOneWidget);

    // Cocher l'une ne coche pas l'autre : leurs identifiants diffèrent.
    final cases = find.descendant(
      of: find.widgetWithText(ListTile, 'Lire'),
      matching: find.byType(Checkbox),
    );
    await tester.tap(cases.first);
    await tester.pump();
    expect(find.text('2 à faire'), findsOneWidget);
    expect(tester.widget<Checkbox>(cases.last).value, isFalse);
  });
}
