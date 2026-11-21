// Tests unitaires du modèle (partie A). Aucun widget ici : le modèle est du
// Dart pur. flutter_test fournit test, group et expect.
import 'package:flutter_test/flutter_test.dart';
import 'package:mes_taches/modele/taches.dart';

/// Une tâche minimale, pour ne préciser dans chaque test que ce qui compte.
Tache tache(
  String titre, {
  Priorite priorite = Priorite.normale,
  Echeance echeance = const SansEcheance(),
  bool faite = false,
}) => Tache(
  id: 'id-$titre',
  titre: titre,
  priorite: priorite,
  echeance: echeance,
  faite: faite,
);

/// Un document JSON valide, que chaque test peut modifier.
Map<String, Object?> jsonValide() => {
  'id': 't1',
  'title': 'Installer Flutter',
  'priority': 'high',
  'done': true,
};

void main() {
  group('Priorite', () {
    test('les priorités sont ordonnées basse < normale < haute', () {
      expect(Priorite.basse.compareTo(Priorite.normale), lessThan(0));
      expect(Priorite.normale.compareTo(Priorite.haute), lessThan(0));
    });

    test('chaque priorité a un libellé affichable', () {
      expect(Priorite.basse.libelle, 'Basse');
      expect(Priorite.normale.libelle, 'Normale');
      expect(Priorite.haute.libelle, 'Haute');
    });
  });

  group('prioriteDepuisCode', () {
    test('reconnaît les trois codes', () {
      expect(prioriteDepuisCode('low'), Priorite.basse);
      expect(prioriteDepuisCode('normal'), Priorite.normale);
      expect(prioriteDepuisCode('high'), Priorite.haute);
    });

    test('renvoie null pour un code inconnu, même à la casse près', () {
      expect(prioriteDepuisCode('urgent'), isNull);
      expect(prioriteDepuisCode('High'), isNull);
      expect(prioriteDepuisCode(''), isNull);
    });
  });

  group('Tache', () {
    test(
      'valeurs par défaut : normale, sans échéance, sans note, non faite',
      () {
        final t = Tache(id: 'a', titre: 'Lire');
        expect(t.priorite, Priorite.normale);
        expect(t.echeance, const SansEcheance());
        expect(t.note, isNull);
        expect(t.faite, isFalse);
      },
    );

    test('refuse un identifiant ou un titre vide', () {
      expect(() => Tache(id: '', titre: 'Lire'), throwsArgumentError);
      expect(() => Tache(id: 'a', titre: ''), throwsArgumentError);
    });
  });

  group('Echeance', () {
    test("une échéance datée ne garde que le jour, le mois et l'année", () {
      final e = EcheanceDate(DateTime(2026, 12, 1, 15, 30));
      expect(e.date, DateTime(2026, 12, 1));
    });

    test('une échéance hebdomadaire accepte lundi (1) et dimanche (7)', () {
      expect(EcheanceHebdo(1).jour, 1);
      expect(EcheanceHebdo(7).jour, 7);
    });

    test('une échéance hebdomadaire hors de 1..7 est refusée', () {
      expect(() => EcheanceHebdo(0), throwsRangeError);
      expect(() => EcheanceHebdo(8), throwsRangeError);
    });
  });

  group('tacheDepuisJson', () {
    test('lit un document valide sans échéance ni note', () {
      final t = tacheDepuisJson(jsonValide());
      expect(
        t,
        Tache(
          id: 't1',
          titre: 'Installer Flutter',
          priorite: Priorite.haute,
          faite: true,
        ),
      );
    });

    test('lit un document valide avec échéance et note', () {
      final t = tacheDepuisJson({
        'id': 't2',
        'title': 'Payer le loyer',
        'priority': 'low',
        'done': false,
        'due': '2026-12-01',
        'note': 'virement',
      });
      expect(t.priorite, Priorite.basse);
      expect(t.faite, isFalse);
      expect(t.echeance, EcheanceDate(DateTime(2026, 12, 1)));
      expect(t.note, 'virement');
    });

    test('"due" et "note" à null équivalent à leur absence', () {
      final t = tacheDepuisJson({...jsonValide(), 'due': null, 'note': null});
      expect(t.echeance, const SansEcheance());
      expect(t.note, isNull);
    });

    test('les clés inconnues sont ignorées', () {
      final t = tacheDepuisJson({...jsonValide(), 'couleur': 'rouge'});
      expect(t.id, 't1');
    });

    for (final cle in ['id', 'title', 'priority', 'done']) {
      test('clé obligatoire "$cle" absente : FormatException', () {
        final json = jsonValide()..remove(cle);
        expect(() => tacheDepuisJson(json), throwsFormatException);
      });
    }

    final invalides = <String, Map<String, Object?>>{
      'id du mauvais type': {...jsonValide(), 'id': 1},
      'id vide': {...jsonValide(), 'id': ''},
      'title du mauvais type': {...jsonValide(), 'title': 42},
      'title vide': {...jsonValide(), 'title': ''},
      'priority du mauvais type': {...jsonValide(), 'priority': 2},
      'priority inconnue': {...jsonValide(), 'priority': 'urgent'},
      'done du mauvais type': {...jsonValide(), 'done': 'non'},
      'id à null': {...jsonValide(), 'id': null},
      'due du mauvais type': {...jsonValide(), 'due': 20261201},
      'due illisible': {...jsonValide(), 'due': '01/12/2026'},
      'due avec un mois impossible': {...jsonValide(), 'due': '2026-13-01'},
      'due inexistante (30 février)': {...jsonValide(), 'due': '2026-02-30'},
      'note du mauvais type': {...jsonValide(), 'note': 3},
    };
    invalides.forEach((cause, json) {
      test('$cause : FormatException', () {
        expect(() => tacheDepuisJson(json), throwsFormatException);
      });
    });
  });

  group('libelleEcheance', () {
    test('sans échéance', () {
      expect(libelleEcheance(const SansEcheance()), 'sans échéance');
    });

    test('une date, au format jour/mois sans zéro initial', () {
      expect(
        libelleEcheance(EcheanceDate(DateTime(2026, 12, 1))),
        'pour le 1/12',
      );
      expect(
        libelleEcheance(EcheanceDate(DateTime(2027, 3, 5))),
        'pour le 5/3',
      );
    });

    test('hebdomadaire, jour en minuscules', () {
      expect(
        libelleEcheance(EcheanceHebdo(DateTime.saturday)),
        'chaque samedi',
      );
      expect(libelleEcheance(EcheanceHebdo(DateTime.monday)), 'chaque lundi');
      expect(
        libelleEcheance(EcheanceHebdo(DateTime.sunday)),
        'chaque dimanche',
      );
    });
  });

  group('estEnRetard', () {
    final jourJ15h = DateTime(2026, 11, 21, 15);
    final veille = EcheanceDate(DateTime(2026, 11, 20));

    test('échéance la veille, non faite : en retard', () {
      expect(
        estEnRetard(tache('a', echeance: veille), aujourdhui: jourJ15h),
        isTrue,
      );
    });

    test('échéance la veille, mais faite : pas en retard', () {
      expect(
        estEnRetard(
          tache('a', echeance: veille, faite: true),
          aujourdhui: jourJ15h,
        ),
        isFalse,
      );
    });

    test("échéance le jour même à une autre heure : pas en retard", () {
      final ceMatin = EcheanceDate(DateTime(2026, 11, 21, 8));
      expect(
        estEnRetard(
          tache('a', echeance: ceMatin),
          aujourdhui: DateTime(2026, 11, 21, 18),
        ),
        isFalse,
      );
    });

    test('sans échéance : jamais en retard', () {
      expect(estEnRetard(tache('a'), aujourdhui: jourJ15h), isFalse);
    });

    test('hebdomadaire : jamais en retard', () {
      final chaqueLundi = EcheanceHebdo(DateTime.monday);
      expect(
        estEnRetard(tache('a', echeance: chaqueLundi), aujourdhui: jourJ15h),
        isFalse,
      );
    });
  });

  group('bilan', () {
    test('une collection vide donne (faites: 0, total: 0)', () {
      expect(bilan(const []), (faites: 0, total: 0));
    });

    test('compte les tâches faites et le total', () {
      final taches = [
        tache('a', faite: true),
        tache('b'),
        tache('c', faite: true),
      ];
      expect(bilan(taches), (faites: 2, total: 3));
    });
  });

  group('aFaire', () {
    // L'exemple du sujet.
    List<Tache> exemple() => [
      tache('Courses', priorite: Priorite.basse),
      tache('Dentiste', priorite: Priorite.normale),
      tache('Passeport', priorite: Priorite.haute),
      tache('Installer', priorite: Priorite.haute, faite: true),
      tache('Banque', priorite: Priorite.normale),
    ];

    List<String> titres(List<Tache> taches) => [
      for (final t in taches) t.titre,
    ];

    test('écarte les tâches faites, trie par priorité puis par titre', () {
      expect(titres(aFaire(exemple())), [
        'Passeport',
        'Banque',
        'Dentiste',
        'Courses',
      ]);
    });

    test('auMoins écarte les priorités inférieures', () {
      expect(titres(aFaire(exemple(), auMoins: Priorite.normale)), [
        'Passeport',
        'Banque',
        'Dentiste',
      ]);
      expect(titres(aFaire(exemple(), auMoins: Priorite.haute)), ['Passeport']);
    });

    test('à priorité égale, les titres sont dans l\'ordre alphabétique', () {
      final taches = [tache('Zèbre'), tache('Abeille'), tache('Mouton')];
      expect(titres(aFaire(taches)), ['Abeille', 'Mouton', 'Zèbre']);
    });

    test(
      'la collection reçue reste intacte et une nouvelle liste est rendue',
      () {
        final entree = exemple();
        final copie = List.of(entree);
        final resultat = aFaire(entree);
        expect(entree, copie); // même contenu, même ordre
        expect(identical(resultat, entree), isFalse);
      },
    );

    test('une collection vide donne une liste vide', () {
      expect(aFaire(const []), isEmpty);
    });
  });

  group('immuabilité (copyWith)', () {
    final originale = Tache(
      id: 't1',
      titre: 'Lire',
      priorite: Priorite.basse,
      note: 'chapitre 3',
    );

    test("cocher donne une nouvelle tâche, l'originale reste inchangée", () {
      final cochee = originale.copyWith(faite: true);
      expect(cochee.faite, isTrue);
      expect(cochee.id, originale.id);
      expect(originale.faite, isFalse);
      expect(identical(cochee, originale), isFalse);
    });

    test('seuls les éléments demandés changent', () {
      final modifiee = originale.copyWith(
        titre: 'Relire',
        priorite: Priorite.haute,
        echeance: EcheanceHebdo(DateTime.friday),
        note: 'chapitre 4',
      );
      expect(modifiee.id, 't1');
      expect(modifiee.titre, 'Relire');
      expect(modifiee.priorite, Priorite.haute);
      expect(modifiee.echeance, EcheanceHebdo(DateTime.friday));
      expect(modifiee.note, 'chapitre 4');
      expect(modifiee.faite, isFalse);
      expect(originale.titre, 'Lire');
      expect(originale.note, 'chapitre 3');
    });

    test("sansNote retire la note, l'originale la garde", () {
      final sansNote = originale.copyWith(sansNote: true);
      expect(sansNote.note, isNull);
      expect(originale.note, 'chapitre 3');
    });

    test('copyWith sans argument donne une tâche égale', () {
      expect(originale.copyWith(), originale);
    });
  });
}
