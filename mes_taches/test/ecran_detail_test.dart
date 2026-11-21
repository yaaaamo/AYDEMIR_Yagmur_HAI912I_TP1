// Tests de widgets de l'écran de détail seul (partie D1), date fixe.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mes_taches/ecrans/ecran_detail.dart';
import 'package:mes_taches/modele/taches.dart';

final aujourdhui = DateTime(2026, 11, 21, 15);

Widget enApp(Widget ecran) => MaterialApp(home: ecran);

void main() {
  testWidgets('affiche tout le contenu, titre long en entier', (tester) async {
    const titreLong =
        'Un titre vraiment très long qui ne doit pas être coupé dans le '
        'détail de la tâche';
    await tester.pumpWidget(
      enApp(
        EcranDetail(
          tache: Tache(
            id: 'a',
            titre: titreLong,
            priorite: Priorite.haute,
            echeance: EcheanceDate(DateTime(2026, 11, 20)),
            note: 'apporter la carte vitale',
          ),
          aujourdhui: aujourdhui,
        ),
      ),
    );

    final titre = tester.widget<Text>(find.text(titreLong));
    expect(titre.maxLines, isNull); // pas coupé
    expect(find.text('Haute'), findsOneWidget);
    expect(find.text('pour le 20/11 · en retard'), findsOneWidget);
    expect(find.text('apporter la carte vitale'), findsOneWidget);
    expect(find.text('À faire'), findsOneWidget);
    expect(find.text('Marquer comme faite'), findsOneWidget);
  });

  testWidgets('sans note : mention « Aucune note » ; faite : « Faite »', (
    tester,
  ) async {
    await tester.pumpWidget(
      enApp(
        EcranDetail(
          tache: Tache(id: 'a', titre: 'Lire', faite: true),
          aujourdhui: aujourdhui,
        ),
      ),
    );

    expect(find.text('Aucune note'), findsOneWidget);
    expect(find.text('sans échéance'), findsOneWidget);
    expect(find.text('Faite'), findsOneWidget);
    expect(find.text('Marquer à faire'), findsOneWidget);
  });
}
