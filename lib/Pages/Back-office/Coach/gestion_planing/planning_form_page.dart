import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/Pages/Back-office/Backend_template.dart';
import 'package:intl/intl.dart';

class PlanningFormPage extends StatefulWidget {
  final Map<String, dynamic>? session;

  const PlanningFormPage({Key? key, this.session}) : super(key: key);

  @override
  _PlanningFormPageState createState() => _PlanningFormPageState();
}

class _PlanningFormPageState extends State<PlanningFormPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  late String _groupName;
  late String _type;
  late String _startTime;
  late String _endTime;
  late DateTime _date;
  List<Map<String, dynamic>> _coaches = [];
  List<String> _selectedCoaches = [];

  @override
  void initState() {
    super.initState();
    _groupName = widget.session?['groupName'] ?? '';
    _type = widget.session?['type'] ?? 'Training';
    _startTime = widget.session?['startTime'] ?? '';
    _endTime = widget.session?['endTime'] ?? '';
    _date = widget.session?['date'] != null
        ? DateTime.parse(widget.session!['date'])
        : DateTime.now();
    _selectedCoaches = List<String>.from(widget.session?['coaches'] ?? []);
    _fetchCoaches();
  }

  Future<void> _fetchCoaches() async {
    try {
      final snapshot = await _firestore.collection('coaches').get();
      final allCoaches = snapshot.docs
          .map((doc) => {'id': doc.id, 'name': doc.data()['name']})
          .toList();

      setState(() {
        _coaches = allCoaches;

        if (widget.session != null && widget.session!['coaches'] != null) {
          final sessionCoaches = List<String>.from(widget.session!['coaches']);
          _selectedCoaches = sessionCoaches.map((coachInfo) {
            // Match coach by ID or fallback to name matching
            final coach = _coaches.firstWhere(
              (c) => c['id'] == coachInfo || c['name'] == coachInfo,
              orElse: () => {'id': null},
            );
            return coach['id'];
          }).whereType<String>().toList();
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur lors de la récupération des coaches : $e')),
      );
    }
  }

 Future<void> _saveSession() async {
  if (!_formKey.currentState!.validate()) return;

  _formKey.currentState!.save();

  final data = {
    'groupName': _groupName,
    'type': _type,
    'startTime': _startTime,
    'endTime': _endTime,
    'date': _date.toIso8601String(),
    'coaches': _selectedCoaches,
  };

  try {
    DocumentReference docRef;
    if (widget.session == null || !widget.session!.containsKey('id')) {
      docRef = await _firestore.collection('trainings').add(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Séance ajoutée avec succès !')),
      );
    } else {
      docRef = _firestore.collection('trainings').doc(widget.session!['id']);
      await docRef.update(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Séance mise à jour avec succès !')),
      );
    }

    // ✅ Update statistics for each assigned coach
    for (String coachId in _selectedCoaches) {
      final statsRef =
          _firestore.collection('coachStatistics').doc(coachId);

      final statsDoc = await statsRef.get();
      if (statsDoc.exists) {
        // Update existing stats
        await statsRef.update({
          'trainingCount': FieldValue.increment(1),
          'lastSession': _date.toIso8601String(),
        });
      } else {
        // Create new stats record
        await statsRef.set({
          'coachId': coachId,
          'trainingCount': 1,
          'lastSession': _date.toIso8601String(),
        });
      }
    }

    Navigator.pop(context);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur lors de la sauvegarde : $e')),
    );
  }
}


  Widget _buildCoachSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Coachs disponibles",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: _coaches.map((coach) {
            final isSelected = _selectedCoaches.contains(coach['id']);
            return ChoiceChip(
              label: Text(coach['name']),
              selected: isSelected,
              selectedColor: Colors.blueAccent,
              backgroundColor: Colors.grey[200],
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    if (!_selectedCoaches.contains(coach['id'])) {
                      _selectedCoaches.add(coach['id']);
                    }
                  } else {
                    _selectedCoaches.remove(coach['id']);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePageBack(
      title: widget.session == null
          ? 'Ajouter une séance'
          : 'Modifier la séance',
      footerIndex: 2,
      isCoach: true,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _groupName,
                decoration: const InputDecoration(labelText: 'Nom du groupe'),
                onSaved: (value) => _groupName = value!,
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
              DropdownButtonFormField<String>(
                value: _type,
                items: const [
                  DropdownMenuItem(
                      value: 'Training', child: Text('Entraînement')),
                  DropdownMenuItem(value: 'Match', child: Text('Match')),
                  DropdownMenuItem(value: 'Match', child: Text('Championnat')),
                  DropdownMenuItem(value: 'Match', child: Text('Tournoi')),
                ],
                onChanged: (value) => setState(() => _type = value!),
                decoration: const InputDecoration(labelText: 'Type de séance'),
              ),
              TextFormField(
                initialValue: _startTime,
                decoration: const InputDecoration(
                    labelText: 'Heure de début (ex: 17:00)'),
                onSaved: (value) => _startTime = value!,
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                initialValue: _endTime,
                decoration: const InputDecoration(
                    labelText: 'Heure de fin (ex: 18:30)'),
                onSaved: (value) => _endTime = value!,
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
              ListTile(
                title: const Text('Date de la séance'),
                subtitle: Text(
                    DateFormat('EEEE, dd MMM yyyy', 'fr_FR').format(_date)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2022),
                    lastDate: DateTime(2100),
                  );
                  if (selectedDate != null) {
                    setState(() {
                      _date = selectedDate;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildCoachSelection(),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveSession,
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
