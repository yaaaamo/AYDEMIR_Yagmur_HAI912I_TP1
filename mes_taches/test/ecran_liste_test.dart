// Tests de widgets de l'écran de liste (partie B).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mes_taches/ecrans/ecran_liste.dart';
import 'package:mes_taches/modele/taches.dart';

/// Monte un écran dans une MaterialApp (thème, Navigator, textes Material).
Widget enApp(Widget ecran) => MaterialApp(home: ecran);

/// La case à cocher de la tâche dont le titre est [titre].
Finder caseDe(String titre) => find.descendant(
  of: find.widgetWithText(ListTile, titre),
  matching: find.byType(Checkbox),
);

void main() {
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
}
