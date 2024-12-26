import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../Style/Backend_template.dart';
import 'add_event_page.dart'; // Import AddEventPage to navigate to it

class ManageEventsPage extends StatefulWidget {
  const ManageEventsPage({Key? key}) : super(key: key);

  @override
  _ManageActivitiesPageState createState() => _ManageActivitiesPageState();
}

class _ManageActivitiesPageState extends State<ManageEventsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Annuler un entraînement
  void _cancelTraining(String groupId, String cause) async {
    try {
      await _firestore.collection('training_cancellations').add({
        'groupId': groupId,
        'cause': cause,
        'timestamp': DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entraînement annulé avec succès !')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'annulation')),
      );
    }
  }

  // Créer un sondage
  void _createPoll(String question, List<String> options) async {
    try {
      await _firestore.collection('polls').add({
        'question': question,
        'options': options,
        'votes': List.filled(options.length, 0),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sondage créé avec succès !')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la création du sondage')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePageBack(
      title: 'Gestion des Activités',
      footerIndex: 0,  // Set the footer index for this page
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Annuler un Entraînement'),
            _buildCancelTrainingForm(),
            const SizedBox(height: 20),
            _buildSectionTitle('Gérer les Événements'),
            _buildEventManagement(),
            const SizedBox(height: 20),
            _buildSectionTitle('Créer un Sondage'),
            _buildPollForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCancelTrainingForm() {
    final TextEditingController causeController = TextEditingController();
    String selectedGroup = 'Group 1'; // Example selected group

    return Column(
      children: [
        DropdownButton<String>(
          value: selectedGroup,
          items: ['Group 1', 'Group 2', 'Group 3']
              .map((group) => DropdownMenuItem(value: group, child: Text(group)))
              .toList(),
          onChanged: (value) {
            setState(() {
              selectedGroup = value!;
            });
          },
        ),
        TextField(
          controller: causeController,
          decoration: const InputDecoration(hintText: 'Motif de l\'annulation'),
        ),
        ElevatedButton(
          onPressed: () {
            _cancelTraining(selectedGroup, causeController.text);
          },
          child: const Text('Annuler'),
        ),
      ],
    );
  }

  Widget _buildEventManagement() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            // Navigate to AddEventPage
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) =>  AddEventPage()),
            );
          },
          child: const Text('Ajouter un Événement'),
        ),
      ],
    );
  }

  Widget _buildPollForm() {
    final TextEditingController questionController = TextEditingController();
    final TextEditingController optionController = TextEditingController();
    List<String> options = [];

    return Column(
      children: [
        TextField(
          controller: questionController,
          decoration: const InputDecoration(hintText: 'Question du sondage'),
        ),
        TextField(
          controller: optionController,
          decoration: const InputDecoration(hintText: 'Ajouter une option'),
          onSubmitted: (value) {
            setState(() {
              options.add(value);
              optionController.clear();
            });
          },
        ),
        Wrap(
          spacing: 8.0,
          children: options.map((option) => Chip(label: Text(option))).toList(),
        ),
        ElevatedButton(
          onPressed: () {
            _createPoll(questionController.text, options);
          },
          child: const Text('Créer Sondage'),
        ),
      ],
    );
  }
}
