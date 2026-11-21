import 'package:flutter_test/flutter_test.dart';
import 'package:mes_taches/modele/filtre.dart';
import 'package:mes_taches/modele/taches.dart';

void main() {
  final aFaire = Tache(id: 'a', titre: 'Lire');
  final faite = Tache(id: 'b', titre: 'Écrire', faite: true);

  test('« Toutes » retient toutes les tâches', () {
    expect(Filtre.toutes.retient(aFaire), isTrue);
    expect(Filtre.toutes.retient(faite), isTrue);
  });

  test('« À faire » ne retient que les tâches non faites', () {
    expect(Filtre.aFaire.retient(aFaire), isTrue);
    expect(Filtre.aFaire.retient(faite), isFalse);
  });

  test('« Faites » ne retient que les tâches faites', () {
    expect(Filtre.faites.retient(aFaire), isFalse);
    expect(Filtre.faites.retient(faite), isTrue);
  });

  test('filtrer ne modifie pas la tâche', () {
    final avant = aFaire.copyWith();
    Filtre.faites.retient(aFaire);
    expect(aFaire, avant);
  });
}
