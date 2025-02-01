import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/Pages/Back-office/Backend_template.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
// ignore: depend_on_referenced_packages
import 'package:table_calendar/table_calendar.dart';

class TrainingCalendarPage extends StatefulWidget {
  const TrainingCalendarPage({Key? key}) : super(key: key);

  @override
  _TrainingCalendarState createState() => _TrainingCalendarState();
}

class _TrainingCalendarState extends State<TrainingCalendarPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Map<DateTime, List<Map<String, dynamic>>> _trainings;
  DateTime _selectedDay = DateTime.now();

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('fr_FR', null);
  }

  @override
  void initState() {
    super.initState();
    _trainings = {};
    _fetchTrainings();
  }

  Future<void> _fetchTrainings() async {
    final snapshot = await _firestore.collection('trainings').get();
    final events = <DateTime, List<Map<String, dynamic>>>{};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data.containsKey('date')) {
        final date = DateTime.parse(data['date']).toLocal();
        final localDate = DateTime(date.year, date.month, date.day);

        if (!events.containsKey(localDate)) {
          events[localDate] = [];
        }

        List<String> coachNames = [];
        if (data['coaches'] != null && data['coaches'] is List) {
          for (String coachId in List<String>.from(data['coaches'])) {
            final coachDoc =
                await _firestore.collection('coaches').doc(coachId).get();
            if (coachDoc.exists) {
              coachNames.add(coachDoc.data()!['name']);
            }
          }
        }
        events[localDate]!.add({
          'id': doc.id,
          'groupName': data['groupName'],
          'startTime': data['startTime'],
          'endTime': data['endTime'],
          'coaches': coachNames.isEmpty ? ["Aucun coach assigné"] : coachNames,
        });
      }
    }

    setState(() {
      _trainings = events;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeLocale(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erreur lors de l\'initialisation : ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        } else {
          return _buildPageContent();
        }
      },
    );
  }

  Widget _buildPageContent() {
    return TemplatePageBack(
      title: 'Calendrier des Entraînements',
      footerIndex: 0,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TableCalendar(
            locale: 'fr_FR',
            firstDay: DateTime(DateTime.now().year, 1, 1),
            lastDay: DateTime(DateTime.now().year, 12, 31),
            focusedDay: _selectedDay,
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {CalendarFormat.month: 'Month'},
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            eventLoader: (day) => _getTrainingsForDay(day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
              });
            },
            calendarStyle: const CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Les entraînements planifiés pour le\n${DateFormat('EEEE, d MMMM y', 'fr_FR').format(_selectedDay)} :',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _buildTrainingList(),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getTrainingsForDay(DateTime day) {
    final trainings = _trainings[DateTime(day.year, day.month, day.day)] ?? [];
    return trainings;
  }

  Widget _buildTrainingList() {
    final trainings = _getTrainingsForDay(_selectedDay);

    if (trainings.isEmpty) {
      return const Center(
        child: Text(
          'Aucun entraînement prévu pour cette date.',
          style: TextStyle(
            fontSize: 18,
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: trainings.length,
      itemBuilder: (context, index) {
        final training = trainings[index];
        final coaches =
            (training['coaches'] != null && training['coaches'] is List)
                ? (training['coaches'] as List).join(', ')
                : 'Aucun coach assigné';
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.sports_soccer, color: Colors.blueAccent),
            title: Text(
              training['groupName'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'De ${training['startTime']} à ${training['endTime']}\nCoach(s) : $coaches',
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () => _showCancelDialog(training['id']),
            ),
          ),
        );
      },
    );
  }

  Future<void> _cancelTraining(String trainingId, String reason) async {
    await _firestore.collection('trainings').doc(trainingId).delete();
    _fetchTrainings();
  }

  void _showCancelDialog(String trainingId) {
    showDialog(
      context: context,
      builder: (context) {
        String selectedReason = "Mauvais temps";
        String otherReason = "";
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Annuler l'entraînement"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Choisissez une raison pour l'annulation :"),
                  DropdownButton<String>(
                    value: selectedReason,
                    onChanged: (value) {
                      setState(() {
                        selectedReason = value!;
                        if (selectedReason != "Autre") {
                          otherReason = "";
                        }
                      });
                    },
                    items: [
                      "Mauvais temps",
                      "Repos",
                      "Autre",
                    ].map((reason) {
                      return DropdownMenuItem(
                        value: reason,
                        child: Text(reason),
                      );
                    }).toList(),
                  ),
                  if (selectedReason == "Autre")
                    TextField(
                      onChanged: (value) {
                        otherReason = value;
                      },
                      decoration: const InputDecoration(
                        labelText: "Description du motif",
                        hintText:
                            "Expliquez pourquoi l'entraînement est annulé",
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Annuler"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final reasonToSave = selectedReason == "Autre"
                        ? otherReason
                        : selectedReason;
                    _cancelTraining(trainingId, reasonToSave);
                    Navigator.of(context).pop();
                  },
                  child: const Text("Confirmer"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
