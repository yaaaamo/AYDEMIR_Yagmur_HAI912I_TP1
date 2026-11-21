import 'package:flutter_test/flutter_test.dart';
import 'package:mes_taches/donnees/exemples.dart';
import 'package:mes_taches/donnees/lecture_taches.dart';

void main() {
  group('tachesDepuisJsonTexte', () {
    test('lit les six tâches des données d\'exemple', () {
      final taches = tachesDepuisJsonTexte(tachesExempleJson);
      expect(taches, hasLength(6));
      expect(taches.first.titre, 'Installer Flutter');
    });

    test('un tableau vide donne une liste vide', () {
      expect(tachesDepuisJsonTexte('[]'), isEmpty);
    });

    test('un texte qui n\'est pas du JSON : FormatException', () {
      expect(() => tachesDepuisJsonTexte('pas du json'), throwsFormatException);
    });

    test('un document qui n\'est pas un tableau : FormatException', () {
      expect(() => tachesDepuisJsonTexte('{}'), throwsFormatException);
    });

    test('un élément qui n\'est pas un objet : FormatException', () {
      expect(() => tachesDepuisJsonTexte('[1]'), throwsFormatException);
    });
  });
}
