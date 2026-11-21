// Formulaire de création d'une tâche (parties E1 et E2).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../modele/taches.dart';
import '../modele/validation.dart';

/// Crée une tâche. Comme le détail, l'écran RENVOIE son résultat en se
/// fermant : la nouvelle tâche si « Enregistrer » réussit, null si
/// l'utilisateur revient en arrière.
class EcranFormulaire extends StatefulWidget {
  const EcranFormulaire({
    super.key,
    required this.identifiant,
    required this.aujourdhui,
  });

  /// Identifiant unique choisi par la liste, qui connaît toutes les tâches.
  final String identifiant;

  /// Date du jour : borne inférieure de l'échéance (fixée dans les tests).
  final DateTime aujourdhui;

  @override
  State<EcranFormulaire> createState() => _EcranFormulaireState();
}

class _EcranFormulaireState extends State<EcranFormulaire> {
  // La clé donne accès à l'état du Form : validate().
  final _cle = GlobalKey<FormState>();

  // Les contrôleurs gardent le texte des champs. Ils appartiennent à ce State,
  // qui doit les libérer dans dispose().
  final _titre = TextEditingController();
  final _note = TextEditingController();

  Priorite _priorite = Priorite.normale;
  DateTime? _date; // null : pas d'échéance

  @override
  void dispose() {
    _titre.dispose();
    _note.dispose();
    super.dispose();
  }

  DateTime get _premierJour => DateTime(
    widget.aujourdhui.year,
    widget.aujourdhui.month,
    widget.aujourdhui.day,
  );

  Future<void> _choisirDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: _premierJour, // le passé n'est pas proposé
      lastDate: DateTime(_premierJour.year + 5),
      initialDate: _date ?? _premierJour,
      currentDate: _premierJour,
    );
    // Après un await, l'écran a pu disparaître ; null : boîte fermée.
    if (!mounted || date == null) return;
    setState(() => _date = date);
  }

  void _enregistrer() {
    // validate() appelle tous les validateurs et affiche leurs messages ;
    // il renvoie false si l'un d'eux a renvoyé un texte : on reste ouvert.
    if (!_cle.currentState!.validate()) return;
    final date = _date;
    Navigator.of(context).pop(
      Tache(
        id: widget.identifiant,
        titre: _titre.text.trim(),
        priorite: _priorite,
        echeance: date == null ? const SansEcheance() : EcheanceDate(date),
        note: noteNettoyee(_note.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle tâche')),
      body: Form(
        key: _cle,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titre,
              decoration: const InputDecoration(labelText: 'Titre'),
              validator: validerTitre,
              // Le compteur s'affiche, mais la saisie n'est pas bloquée : un
              // titre trop long est refusé par le validateur, avec un message.
              maxLength: titreMax,
              maxLengthEnforcement: MaxLengthEnforcement.none,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Priorite>(
              initialValue: _priorite,
              decoration: const InputDecoration(labelText: 'Priorité'),
              items: [
                for (final p in Priorite.values)
                  DropdownMenuItem(value: p, child: Text(p.libelle)),
              ],
              onChanged: (p) => setState(() => _priorite = p ?? _priorite),
            ),
            const SizedBox(height: 16),
            // L'échéance n'est pas un champ texte : un FormField générique
            // lui donne un validateur et un message sous le champ.
            FormField<DateTime>(
              validator: (_) =>
                  validerEcheance(_date, aujourdhui: widget.aujourdhui),
              builder: (champ) => InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Échéance',
                  errorText: champ.errorText,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(switch (_date) {
                        null => 'Aucune',
                        DateTime date => libelleEcheance(EcheanceDate(date)),
                      }),
                    ),
                    if (_date != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: "Retirer l'échéance",
                        onPressed: () => setState(() => _date = null),
                      ),
                    IconButton(
                      icon: const Icon(Icons.calendar_month),
                      tooltip: 'Choisir une date',
                      onPressed: _choisirDate,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _note,
              decoration: const InputDecoration(
                labelText: 'Note (facultative)',
                alignLabelWithHint: true,
              ),
              validator: validerNote,
              minLines: 3,
              maxLines: 6,
              maxLength: noteMax,
              maxLengthEnforcement: MaxLengthEnforcement.none,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _enregistrer,
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}
