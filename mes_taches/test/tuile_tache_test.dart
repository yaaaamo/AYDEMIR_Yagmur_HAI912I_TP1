// Tests de widgets de la tuile de tâche (partie C2), avec une date FIXE.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mes_taches/modele/taches.dart';
import 'package:mes_taches/widgets/tuile_tache.dart';

final aujourdhui = DateTime(2026, 11, 21, 15);

Widget enApp(Widget tuile) => MaterialApp(home: Scaffold(body: tuile));

TextStyle? styleDe(WidgetTester tester, String texte) =>
    tester.widget<Text>(find.text(texte)).style;

void main() {
  testWidgets('le titre est barré si la tâche est faite', (tester) async {
    await tester.pumpWidget(
      enApp(
        TuileTache(
          tache: Tache(id: 'a', titre: 'Lire', faite: true),
          aujourdhui: aujourdhui,
        ),
      ),
    );
    expect(styleDe(tester, 'Lire')?.decoration, TextDecoration.lineThrough);
  });

  testWidgets("le titre n'est pas barré si la tâche est à faire", (
    tester,
  ) async {
    await tester.pumpWidget(
      enApp(
        TuileTache(
          tache: Tache(id: 'a', titre: 'Lire'),
          aujourdhui: aujourdhui,
        ),
      ),
    );
    expect(styleDe(tester, 'Lire')?.decoration, isNull);
  });

  testWidgets("une tâche en retard affiche son échéance en couleur d'alerte", (
    tester,
  ) async {
    await tester.pumpWidget(
      enApp(
        TuileTache(
          tache: Tache(
            id: 'a',
            titre: 'Dentiste',
            echeance: EcheanceDate(DateTime(2026, 11, 20)),
          ),
          aujourdhui: aujourdhui,
        ),
      ),
    );
    final contexte = tester.element(find.byType(TuileTache));
    final rouge = Theme.of(contexte).colorScheme.error;

    expect(find.text('pour le 20/11 · en retard'), findsOneWidget);
    expect(styleDe(tester, 'pour le 20/11 · en retard')?.color, rouge);
  });

  testWidgets("une tâche à l'heure affiche son échéance sans alerte", (
    tester,
  ) async {
    await tester.pumpWidget(
      enApp(
        TuileTache(
          tache: Tache(
            id: 'a',
            titre: 'Passeport',
            echeance: EcheanceDate(DateTime(2027, 1, 15)),
          ),
          aujourdhui: aujourdhui,
        ),
      ),
    );
    expect(find.text('pour le 15/1'), findsOneWidget);
    expect(find.textContaining('en retard'), findsNothing);
  });

  testWidgets('la tuile affiche la priorité', (tester) async {
    await tester.pumpWidget(
      enApp(
        TuileTache(
          tache: Tache(id: 'a', titre: 'Lire', priorite: Priorite.haute),
          aujourdhui: aujourdhui,
        ),
      ),
    );
    expect(find.text('Haute'), findsOneWidget);
  });

  testWidgets('toucher la case appelle onBasculer, pas onOuvrir', (
    tester,
  ) async {
    var basculee = 0;
    var ouverte = 0;
    await tester.pumpWidget(
      enApp(
        TuileTache(
          tache: Tache(id: 'a', titre: 'Lire'),
          aujourdhui: aujourdhui,
          onBasculer: () => basculee++,
          onOuvrir: () => ouverte++,
        ),
      ),
    );

    await tester.tap(find.byType(Checkbox));
    expect(basculee, 1);
    expect(ouverte, 0);

    await tester.tap(find.text('Lire'));
    expect(ouverte, 1);
    expect(basculee, 1);
  });
}
