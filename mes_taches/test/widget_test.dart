// Un premier test de widget qui vérifie que l'application démarre.
// Gardez-le (adaptez-le si votre écran change de titre)
// et écrivez vos propres tests dans ce dossier
// (partie F du sujet, fiche « Tests » de l'annexe).
import 'package:flutter_test/flutter_test.dart';
import 'package:mes_taches/main.dart';

void main() {
  testWidgets("l'application démarre et affiche son titre", (tester) async {
    await tester.pumpWidget(const MesTachesApp());

    expect(find.text('Mes tâches'), findsOneWidget);
  });
}
