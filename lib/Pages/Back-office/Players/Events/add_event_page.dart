import 'package:flutter/material.dart';
import 'package:ifoot_academy/Pages/Back-office/Backend_template.dart';
import 'package:ifoot_academy/Pages/Back-office/Players/Events/tournament_form.dart';

import 'championship_form.dart';
import 'friendly_match_form.dart';

class AddEventForm extends StatelessWidget {
  final String eventType;
  final List<String> groups;  // Pass available groups as a parameter

  AddEventForm({Key? key, required this.eventType, required this.groups}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget childForm;

    switch (eventType) {
      case 'Tournoi':
        childForm = TournamentForm(groups: groups); // Pass groups
        break;
      case 'Championnat':
        childForm = ChampionshipForm(groups: groups); // Pass groups
        break;
      case 'Match amical':
        childForm = FriendlyMatchForm(groups: groups); // Pass groups
        break;
      default:
        childForm = FriendlyMatchForm(groups: groups); // Default to FriendlyMatchForm
    }

    // Retourner la page template avec le body contenant le form
    return TemplatePageBack(
      title: 'Gestion des événements',  // Titre de la page
      footerIndex: 3,                
      body: childForm,               
    );
  }
}
