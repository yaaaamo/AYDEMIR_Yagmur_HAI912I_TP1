// Formulaire de création (parties E1, E2) et de modification (bonus G1).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../modele/taches.dart';
import '../modele/validation.dart';

/// Crée ou modifie une tâche. Comme le détail, l'écran RENVOIE son résultat
/// en se fermant : la tâche enregistrée, ou null si l'utilisateur revient en
/// arrière.
class EcranFormulaire extends StatefulWidget {
  /// Création : une nouvelle tâche, avec l'[identifiant] unique choisi par la
  /// liste (qui connaît toutes les tâches).
  const EcranFormulaire.creation({
    super.key,
    required String this.identifiant,
    required this.aujourdhui,
  }) : tacheInitiale = null;

  /// Modification (G1) : le formulaire est pré-rempli avec [tacheInitiale] ;
  /// l'enregistrement renvoie une tâche de MÊME identifiant (et même état).
  const EcranFormulaire.modification({
    super.key,
    required Tache this.tacheInitiale,
    required this.aujourdhui,
  }) : identifiant = null;

  final String? identifiant;
  final Tache? tacheInitiale;

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
  late final TextEditingController _titre;
  late final TextEditingController _note;

  late Priorite _priorite;
  late Echeance _echeance;

  bool get _enModification => widget.tacheInitiale != null;

  @override
  void initState() {
    super.initState();
    // Pré-remplissage en modification ; valeurs par défaut en création.
    final initiale = widget.tacheInitiale;
    _titre = TextEditingController(text: initiale?.titre);
    _note = TextEditingController(text: initiale?.note);
    _priorite = initiale?.priorite ?? Priorite.normale;
    _echeance = initiale?.echeance ?? const SansEcheance();
  }

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
    // Le date picker exige une date initiale dans ses bornes : une échéance
    // déjà passée (en modification) ouvre donc sur aujourd'hui.
    final initiale = switch (_echeance) {
      EcheanceDate(:final date) when !date.isBefore(_premierJour) => date,
      _ => _premierJour,
    };
    final date = await showDatePicker(
      context: context,
      firstDate: _premierJour, // le passé n'est pas proposé
      lastDate: DateTime(_premierJour.year + 5),
      initialDate: initiale,
      currentDate: _premierJour,
    );
    // Après un await, l'écran a pu disparaître ; null : boîte fermée.
    if (!mounted || date == null) return;
    setState(() => _echeance = EcheanceDate(date));
  }

  /// La règle E2 s'applique à une échéance datée CHOISIE dans ce formulaire.
  /// En modification, une échéance déjà passée et laissée telle quelle reste
  /// acceptée : sinon, corriger le titre d'une tâche en retard serait
  /// impossible sans changer sa date.
  String? _validerEcheance() {
    if (_enModification && _echeance == widget.tacheInitiale?.echeance) {
      return null;
    }
    return switch (_echeance) {
      EcheanceDate(:final date) => validerEcheance(
        date,
        aujourdhui: widget.aujourdhui,
      ),
      SansEcheance() || EcheanceHebdo() => null,
    };
  }

  void _enregistrer() {
    // validate() appelle tous les validateurs et affiche leurs messages ;
    // il renvoie false si l'un d'eux a renvoyé un texte : on reste ouvert.
    if (!_cle.currentState!.validate()) return;
    final titre = _titre.text.trim();
    final note = noteNettoyee(_note.text);
    final initiale = widget.tacheInitiale;

    final Tache resultat;
    if (initiale != null) {
      // G1 : une NOUVELLE tâche, de même identifiant et de même état ;
      // sansNote permet de retirer une note existante.
      resultat = initiale.copyWith(
        titre: titre,
        priorite: _priorite,
        echeance: _echeance,
        note: note,
        sansNote: note == null,
      );
    } else {
      resultat = Tache(
        // Non null : garanti par le constructeur EcranFormulaire.creation.
        id: widget.identifiant!,
        titre: titre,
        priorite: _priorite,
        echeance: _echeance,
        note: note,
      );
    }
    Navigator.of(context).pop(resultat);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_enModification ? 'Modifier la tâche' : 'Nouvelle tâche'),
      ),
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
            FormField<Echeance>(
              validator: (_) => _validerEcheance(),
              builder: (champ) => InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Échéance',
                  errorText: champ.errorText,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(switch (_echeance) {
                        SansEcheance() => 'Aucune',
                        final autre => libelleEcheance(autre),
                      }),
                    ),
                    if (_echeance is! SansEcheance)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: "Retirer l'échéance",
                        onPressed: () =>
                            setState(() => _echeance = const SansEcheance()),
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
