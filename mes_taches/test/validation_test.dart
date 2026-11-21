// Tests unitaires des règles de saisie (partie E2).
import 'package:flutter_test/flutter_test.dart';
import 'package:mes_taches/modele/validation.dart';

void main() {
  group('validerTitre', () {
    test('vide ou fait d\'espaces : obligatoire', () {
      expect(validerTitre(null), 'Le titre est obligatoire');
      expect(validerTitre(''), 'Le titre est obligatoire');
      expect(validerTitre('   '), 'Le titre est obligatoire');
    });

    test('60 caractères acceptés, 61 refusés', () {
      expect(validerTitre('a' * 60), isNull);
      expect(validerTitre('a' * 61), '60 caractères au plus');
    });

    test('les espaces de bord ne comptent pas dans la longueur', () {
      expect(validerTitre('  ${'a' * 60}  '), isNull);
    });
  });

  group('validerNote', () {
    test('note vide acceptée', () {
      expect(validerNote(''), isNull);
      expect(validerNote(null), isNull);
    });

    test('200 caractères acceptés, 201 refusés', () {
      expect(validerNote('a' * 200), isNull);
      expect(validerNote('a' * 201), '200 caractères au plus');
    });
  });

  group('validerEcheance', () {
    final aujourdhui = DateTime(2026, 11, 21, 15);

    test('pas d\'échéance : correct', () {
      expect(validerEcheance(null, aujourdhui: aujourdhui), isNull);
    });

    test(
      'aujourd\'hui (même plus tôt dans la journée) ou plus tard : correct',
      () {
        expect(
          validerEcheance(DateTime(2026, 11, 21, 8), aujourdhui: aujourdhui),
          isNull,
        );
        expect(
          validerEcheance(DateTime(2026, 12, 1), aujourdhui: aujourdhui),
          isNull,
        );
      },
    );

    test('la veille : refusée', () {
      expect(
        validerEcheance(DateTime(2026, 11, 20), aujourdhui: aujourdhui),
        "L'échéance ne peut pas être antérieure à aujourd'hui",
      );
    });
  });

  group('noteNettoyee', () {
    test('retire les espaces de bord', () {
      expect(noteNettoyee('  pain, lait  '), 'pain, lait');
    });

    test('une note vide ou faite d\'espaces devient « pas de note »', () {
      expect(noteNettoyee(''), isNull);
      expect(noteNettoyee('   '), isNull);
    });
  });
}
