// Tests de widgets du bonus G4 : mise en page adaptative.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mes_taches/ecrans/ecran_detail.dart';
import 'package:mes_taches/ecrans/ecran_liste.dart';
import 'package:mes_taches/modele/filtre.dart';
import 'package:mes_taches/modele/taches.dart';
import 'package:mes_taches/widgets/panneau_detail.dart';

DateTime horloge() => DateTime(2026, 11, 21, 15);

Widget liste() => MaterialApp(
  home: EcranListe(
    horloge: horloge,
    tachesInitiales: [
      Tache(id: 'c', titre: 'Courses', note: 'pain, lait'),
      Tache(id: 'd', titre: 'Dentiste', priorite: Priorite.haute),
    ],
  ),
);

/// Fixe la taille de la fenêtre simulée pour la durée du test.
void fenetre(WidgetTester tester, double largeur, double hauteur) {
  tester.view.physicalSize = Size(largeur, hauteur);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Finder caseDe(String titre) => find.descendant(
  of: find.widgetWithText(ListTile, titre),
  matching: find.byType(Checkbox),
);

void main() {
  group('au-delà de 840 px', () {
    testWidgets('sans sélection, le panneau invite à choisir une tâche', (
      tester,
    ) async {
      fenetre(tester, 1200, 800);
      await tester.pumpWidget(liste());

      expect(find.text('Sélectionnez une tâche'), findsOneWidget);
      expect(find.byType(PanneauDetail), findsNothing);
    });

    testWidgets('toucher une tâche affiche son détail À CÔTÉ de la liste', (
      tester,
    ) async {
      fenetre(tester, 1200, 800);
      await tester.pumpWidget(liste());

      await tester.tap(find.text('Courses'));
      await tester.pumpAndSettle();

      // Pas de navigation : la liste reste visible, le détail est à droite.
      expect(find.byType(EcranDetail), findsNothing);
      expect(find.text('Dentiste'), findsOneWidget);
      expect(find.byType(PanneauDetail), findsOneWidget);
      expect(find.text('pain, lait'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byType(PanneauDetail)).dx,
        greaterThan(tester.getTopRight(find.byType(ListView).first).dx - 1),
      );

      // Toucher une autre tâche change le détail affiché.
      await tester.tap(find.text('Dentiste').first);
      await tester.pumpAndSettle();
      expect(find.text('pain, lait'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(PanneauDetail),
          matching: find.text('Haute'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('agir dans le panneau met à jour la liste et le compteur', (
      tester,
    ) async {
      fenetre(tester, 1200, 800);
      await tester.pumpWidget(liste());
      await tester.tap(find.text('Courses'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Marquer comme faite'));
      await tester.pumpAndSettle();

      expect(find.text('1 à faire'), findsOneWidget);
      expect(tester.widget<Checkbox>(caseDe('Courses')).value, isTrue);
      expect(find.text('Marquer à faire'), findsOneWidget); // panneau à jour
    });

    testWidgets('cocher dans la liste met à jour le panneau', (tester) async {
      fenetre(tester, 1200, 800);
      await tester.pumpWidget(liste());
      await tester.tap(find.text('Courses'));
      await tester.pumpAndSettle();

      await tester.tap(caseDe('Courses'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(PanneauDetail),
          matching: find.text('Faite'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('modifier depuis le panneau met à jour liste et panneau', (
      tester,
    ) async {
      fenetre(tester, 1200, 800);
      await tester.pumpWidget(liste());
      await tester.tap(find.text('Courses'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Modifier'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Titre'),
        'Courses bio',
      );
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      // Liste ET panneau affichent le nouveau titre.
      expect(find.text('Courses bio'), findsNWidgets(2));
      expect(find.text('Courses'), findsNothing);
    });

    testWidgets('une tâche écartée par le filtre quitte le panneau', (
      tester,
    ) async {
      fenetre(tester, 1200, 800);
      await tester.pumpWidget(liste());
      await tester.tap(find.text('Courses'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(SegmentedButton<Filtre>),
          matching: find.text('Faites'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PanneauDetail), findsNothing);
      expect(find.text('Sélectionnez une tâche'), findsOneWidget);
    });

    for (final largeur in [841.0, 1280.0]) {
      testWidgets('aucun débordement à ${largeur.toInt()} px', (tester) async {
        fenetre(tester, largeur, 700);
        await tester.pumpWidget(liste());
        await tester.tap(find.text('Courses'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(PanneauDetail), findsOneWidget);
      });
    }
  });

  group("jusqu'à 840 px", () {
    testWidgets('toucher une tâche ouvre toujours la page de détail', (
      tester,
    ) async {
      fenetre(tester, 840, 800);
      await tester.pumpWidget(liste());

      expect(find.text('Sélectionnez une tâche'), findsNothing);
      await tester.tap(find.text('Courses'));
      await tester.pumpAndSettle();

      expect(find.byType(EcranDetail), findsOneWidget);
      expect(find.text('Détail de la tâche'), findsOneWidget);
    });
  });
}
