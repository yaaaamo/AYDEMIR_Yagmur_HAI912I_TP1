// Tests unitaires du tri et du regroupement (bonus G3).
import 'package:flutter_test/flutter_test.dart';
import 'package:mes_taches/modele/taches.dart';
import 'package:mes_taches/modele/tri.dart';

final aujourdhui = DateTime(2026, 11, 21, 15);

Tache tache(
  String titre, {
  Priorite priorite = Priorite.normale,
  Echeance echeance = const SansEcheance(),
  bool faite = false,
}) => Tache(
  id: titre,
  titre: titre,
  priorite: priorite,
  echeance: echeance,
  faite: faite,
);

List<String> titres(List<Tache> taches) => [for (final t in taches) t.titre];

/// Un échantillon de toutes les formes d'échéance.
List<Tache> echantillon() => [
  tache('Sans', priorite: Priorite.basse),
  tache('Lundi', echeance: EcheanceHebdo(DateTime.monday)),
  tache('Décembre', echeance: EcheanceDate(DateTime(2026, 12, 1))),
  tache('Hier', echeance: EcheanceDate(DateTime(2026, 11, 20))),
  tache(
    'Janvier',
    priorite: Priorite.haute,
    echeance: EcheanceDate(DateTime(2027, 1, 15)),
  ),
  tache('Vendredi', echeance: EcheanceHebdo(DateTime.friday)),
  tache('Début novembre', echeance: EcheanceDate(DateTime(2026, 11, 2))),
  tache(
    'Faite hier',
    faite: true,
    echeance: EcheanceDate(DateTime(2026, 11, 20)),
  ),
];

void main() {
  group('trier', () {
    test("« Ordre de saisie » garde l'ordre reçu", () {
      final entree = echantillon();
      expect(
        titres(trier(entree, Tri.saisie, aujourdhui: aujourdhui)),
        titres(entree),
      );
    });

    test('par titre, sans tenir compte des majuscules', () {
      final entree = [tache('banane'), tache('Cerise'), tache('abricot')];
      expect(titres(trier(entree, Tri.titre, aujourdhui: aujourdhui)), [
        'abricot',
        'banane',
        'Cerise',
      ]);
    });

    test('par priorité décroissante, puis par titre', () {
      final entree = [
        tache('B', priorite: Priorite.basse),
        tache('Z', priorite: Priorite.haute),
        tache('A', priorite: Priorite.haute),
        tache('N'),
      ];
      expect(titres(trier(entree, Tri.priorite, aujourdhui: aujourdhui)), [
        'A',
        'Z',
        'N',
        'B',
      ]);
    });

    test('par échéance : retard, datées, hebdomadaires, sans', () {
      final triees = trier(echantillon(), Tri.echeance, aujourdhui: aujourdhui);
      expect(titres(triees), [
        'Début novembre', // en retard (2/11)
        'Hier', // en retard (20/11)
        'Faite hier', // datée : faite, donc pas en retard (20/11)
        'Décembre', // datée (1/12)
        'Janvier', // datée (15/1)
        'Lundi', // hebdomadaire (lundi)
        'Vendredi', // hebdomadaire (vendredi)
        'Sans', // sans échéance
      ]);
    });

    test('la collection reçue reste intacte', () {
      final entree = echantillon();
      final copie = List.of(entree);
      trier(entree, Tri.titre, aujourdhui: aujourdhui);
      expect(entree, copie);
    });
  });

  group('grouperParEcheance', () {
    test('quatre groupes dans le bon ordre, chacun trié', () {
      final groupes = grouperParEcheance(echantillon(), aujourdhui: aujourdhui);

      expect([for (final g in groupes) g.groupe], GroupeEcheance.values);
      expect(titres(groupes[0].taches), ['Début novembre', 'Hier']);
      expect(titres(groupes[1].taches), ['Faite hier', 'Décembre', 'Janvier']);
      expect(titres(groupes[2].taches), ['Lundi', 'Vendredi']);
      expect(titres(groupes[3].taches), ['Sans']);
    });

    test('les groupes vides sont omis', () {
      final groupes = grouperParEcheance([
        tache('Sans'),
        tache('Lundi', echeance: EcheanceHebdo(DateTime.monday)),
      ], aujourdhui: aujourdhui);

      expect(
        [for (final g in groupes) g.groupe],
        [GroupeEcheance.hebdomadaires, GroupeEcheance.sansEcheance],
      );
    });

    test('une tâche faite à échéance passée est datée, pas en retard', () {
      final faite = tache(
        'Faite',
        faite: true,
        echeance: EcheanceDate(DateTime(2026, 11, 2)),
      );
      expect(groupeDe(faite, aujourdhui: aujourdhui), GroupeEcheance.datees);
    });
  });
}
