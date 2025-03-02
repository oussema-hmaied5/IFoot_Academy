// ignore_for_file: library_private_types_in_public_api, unused_element, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/Pages/Back-office/backend_template.dart';
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
  late String _startTime;
  late String _endTime;
    final _dateController = TextEditingController();

  late DateTime _date;
  List<Map<String, dynamic>> _coaches = [];
  List<String> _selectedCoaches = [];
  final Map<String, int> _coachCurrentSessions = {}; // Current session count

  @override
  void initState() {
    super.initState();
    _groupName = widget.session?['groupName'] ?? '';
    _startTime = widget.session?['startTime'] ?? '';
    _endTime = widget.session?['endTime'] ?? '';
    _date = widget.session?['date'] != null
        ? DateTime.parse(widget.session!['date'])
        : DateTime.now();
    _selectedCoaches = List<String>.from(widget.session?['coaches'] ?? []);

    _fetchCoaches().then((_) {
       _fetchCoachSessionCountsForDate(_date); // ✅ Appel immédiat avec _date

      setState(() {});
    });
  }

  /// ✅ **Fetch all coaches and their session counts**
Future<void> _fetchCoaches() async {
    final snapshot = await _firestore.collection('coaches').get();
    final allCoaches = snapshot.docs.map((doc) => {
      'id': doc.id,
      'name': doc.data()['name'],
      'maxSessionsPerDay': doc.data().containsKey('maxSessionsPerDay') ? doc.data()['maxSessionsPerDay'] : 2,
      'maxSessionsPerWeek': doc.data().containsKey('maxSessionsPerWeek') ? doc.data()['maxSessionsPerWeek'] : 10,
      'dailySessions': 0,
      'weeklySessions': 0,
    }).toList();

    setState(() {
      _coaches = allCoaches;
    });

    // ✅ Charger les séances en fonction de la date actuelle (ou date sélectionnée)
    if (_dateController.text.isNotEmpty) {
      DateTime selectedDate = DateFormat('dd/MM/yyyy').parse(_dateController.text);
      await _fetchCoachSessionCountsForDate(selectedDate);
    }
  
}


Future<void> _fetchCoachSessionCountsForDate(DateTime selectedDate) async {
  // ✅ Déterminer la semaine (du lundi au dimanche)
  DateTime startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
  DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

  Map<String, int> dailySessions = {};
  Map<String, int> weeklySessions = {};

  // ✅ Liste des collections à vérifier
  List<String> collections = ['trainings', 'championships', 'friendlyMatches', 'tournaments'];

  for (String collection in collections) {
    final snapshot = await _firestore.collection(collection).get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (!data.containsKey('coaches')) continue;

      List<dynamic> assignedCoaches = data['coaches'];

      DateTime sessionDate = DateTime.now();
      if (data.containsKey('date')) {
        // ✅ Convertir la date correctement
        if (data['date'] is Timestamp) {
          sessionDate = (data['date'] as Timestamp).toDate();
        } else if (data['date'] is String) {
          try {
            sessionDate = DateTime.parse(data['date']);
          } catch (e) {
            continue;
          }
        } else {
          continue;
        }
      } else if (collection == "championships" && data.containsKey('matchDays')) {
        // ✅ Extraire les dates des matchs dans un championnat
        for (var matchDay in data['matchDays']) {
          if (matchDay is Map<String, dynamic> && matchDay.containsKey('date')) {
            try {
              sessionDate = DateTime.parse(matchDay['date']);
            } catch (e) {
              continue;
            }
          } else {
            continue;
          }
        }
      } else {
        continue;
      }

      for (var coachId in assignedCoaches) {
        if (coachId == null) continue;

        // ✅ Vérifier si la session est aujourd'hui
        if (sessionDate.isAtSameMomentAs(selectedDate)) {
          dailySessions[coachId] = (dailySessions[coachId] ?? 0) + 1;
        }

        // ✅ Vérifier si la session est cette semaine (entre lundi et dimanche)
        if (sessionDate.isAfter(startOfWeek) && sessionDate.isBefore(endOfWeek.add(const Duration(days: 1)))) {
          weeklySessions[coachId] = (weeklySessions[coachId] ?? 0) + 1;
        }
      }
    }
  }

  // ✅ Mettre à jour les coachs avec les sessions comptées
  setState(() {
    for (var coach in _coaches) {
      String coachId = coach['id'];
      coach['dailySessions'] = dailySessions[coachId] ?? 0;
      coach['weeklySessions'] = weeklySessions[coachId] ?? 0;
    }
  });
}



/// ✅ **UI for selecting available coaches with session count**
Widget _buildCoachSelection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text("Coachs disponibles", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: _coaches.map((coach) {
          final isSelected = _selectedCoaches.contains(coach['id']);
          final maxPerDay = coach['maxSessionsPerDay'];
          final maxPerWeek = coach['maxSessionsPerWeek'];
          final dailySessions = coach['dailySessions'];
          final weeklySessions = coach['weeklySessions'];

          final remainingDaily = maxPerDay - dailySessions;
          final remainingWeekly = maxPerWeek - weeklySessions;

          return ChoiceChip(
            label: Text("${coach['name']} 📅$remainingDaily/$maxPerDay 🗓️$remainingWeekly/$maxPerWeek"),
            selected: isSelected,
            selectedColor: Colors.blueAccent,
            backgroundColor: Colors.grey[200],
            onSelected: (bool selected) {
              setState(() {
                if (selected) {
                  _selectedCoaches.add(coach['id']);
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


  /// ✅ **Show warning when coach limit is reached**
 /// ✅ **Show warning when coach limit is reached**
void _showLimitWarning(Map<String, dynamic> coach) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("⚠️ Limite atteinte"),
        content: Text(
            "Le coach ${coach['name']} a déjà atteint ${coach['currentSessions']} sessions.\n\n"
            "Voulez-vous l'assigner quand même ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedCoaches.add(coach['id']);

                // ✅ Incrémenter manuellement les sessions affichées
                int index = _coaches.indexWhere((c) => c['id'] == coach['id']);
                if (index != -1) {
                  _coaches[index]['currentSessions'] += 1;
                }
              });

              Navigator.pop(context);
            },
            child: const Text("Forcer l'affectation", style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  );
}

  Future<void> _saveSessionToFirestore(List<String> allowedCoaches) async {
    final data = {
      'groupName': _groupName,
      'startTime': _startTime,
      'endTime': _endTime,
      'date': _date.toIso8601String(),
      'coaches': allowedCoaches,
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
      for (String coachId in allowedCoaches) {
        final statsRef = _firestore.collection('coachStatistics').doc(coachId);
        final statsDoc = await statsRef.get();

        if (statsDoc.exists) {
          await statsRef.update({
            'trainingCount': FieldValue.increment(1),
            'lastSession': _date.toIso8601String(),
          });
        } else {
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

 
Widget _buildTimePicker({
  required String label,
  required String selectedTime,
  required Function(String) onTimeSelected,
}) {
  return Expanded(
    child: InkWell(
      onTap: () async {
        // Ensure the format is HH:mm before parsing
        String sanitizedTime = selectedTime.replaceAll("h", ":");

        TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: sanitizedTime.isNotEmpty
              ? TimeOfDay(
                  hour: int.parse(sanitizedTime.split(':')[0]),  // ✅ Safe parsing
                  minute: int.parse(sanitizedTime.split(':')[1]), // ✅ Safe parsing
                )
              : const TimeOfDay(hour: 12, minute: 0), // Default value
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
              child: child!,
            );
          },
        );

        if (pickedTime != null) {
          String formattedTime =
              "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}"; 

          onTimeSelected(formattedTime);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        ),
        child: Text(
          selectedTime.isNotEmpty ? selectedTime : "Sélectionnez l'heure",
          style: const TextStyle(fontSize: 16),
        ),
      ),
    ),
  );
}

Widget _buildGroupNameField() {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10.0),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: 'Nom du groupe',
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none, // No border
        ),
        filled: true,
        fillColor: Colors.grey[200], // Light grey background
        contentPadding:const  EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
      child: Center(
        child: Text(
          _groupName.toUpperCase(), // Uppercase for better visibility
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color.fromARGB(221, 244, 16, 16),
          ),
        ),
      ),
    ),
  );
}



  @override
  Widget build(BuildContext context) {
    return TemplatePageBack(
      title:
          widget.session == null ? 'Ajouter une séance' : 'Modifier la séance',
      footerIndex: 2,
      isCoach: true,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildGroupNameField(),

              const SizedBox(height: 16),
              
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
                          await _fetchCoachSessionCountsForDate(selectedDate);

                  }
                },
              ),

              const SizedBox(height: 16),

              // 🔥 Row for Start and End Time Inputs
              Row(
                children: [
                  _buildTimePicker(
                    label: "Heure de début",
                    selectedTime: _startTime,
                    onTimeSelected: (newTime) =>
                        setState(() => _startTime = newTime),
                  ),
                  const SizedBox(width: 10),
                  _buildTimePicker(
                    label: "Heure de fin",
                    selectedTime: _endTime,
                    onTimeSelected: (newTime) =>
                        setState(() => _endTime = newTime),
                  ),
                ],
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

 void _showCoachLimitWarning(List<Map<String, dynamic>> blockedCoaches) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("⚠️ Limite de séances atteinte"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Certains coachs ont atteint leur limite de séances. Voulez-vous continuer ?",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: blockedCoaches.map((coach) {
                return Text(
                  "🛑 ${coach['name']} (Séances aujourd'hui: ${coach['todaySessions']}/${coach['maxPerDay']} | Cette semaine: ${coach['weekSessions']}/${coach['maxPerWeek']})",
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // ❌ Cancel
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _proceedWithAssignment(); // ✅ Continue assigning coach
            },
            child: const Text("Forcer l'affectation"),
          ),
        ],
      );
    },
  );
}


void _proceedWithAssignment() {
  // ✅ Continue saving or assigning coaches despite the limits
  _saveSession(); // Or your function to save the assignment
}




  

  Future<void> _saveSession() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    final data = {
      'groupName': _groupName,
      'startTime': _startTime,
      'endTime': _endTime,
      'date': _date.toIso8601String(),
      'coaches': _selectedCoaches,
    };

    try {
      // ✅ Fetch all sessions for today and this week
      DateTime startOfWeek = _date.subtract(Duration(days: _date.weekday - 1));
      DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

      QuerySnapshot todaySessionsSnapshot = await _firestore
          .collection('trainings')
          .where('date', isEqualTo: _date.toIso8601String()) // Sessions today
          .get();

      QuerySnapshot weeklySessionsSnapshot = await _firestore
          .collection('trainings')
          .where('date',
              isGreaterThanOrEqualTo: startOfWeek.toIso8601String(),
              isLessThanOrEqualTo:
                  endOfWeek.toIso8601String()) // Sessions this week
          .get();

      // ✅ Check each coach's max allowed sessions
      List<Map<String, dynamic>> blockedCoaches = [];
      for (String coachId in _selectedCoaches) {
        final coachDoc =
            await _firestore.collection('coaches').doc(coachId).get();

        if (!coachDoc.exists) continue;

        final coachData = coachDoc.data();
        final coachName = coachData?['name'] ?? "Coach inconnu";
        final maxPerDay = coachData?['maxSessionsPerDay'] ?? 0;
        final maxPerWeek = coachData?['maxSessionsPerWeek'] ?? 0;

        int sessionsToday = todaySessionsSnapshot.docs
            .where((doc) =>
                doc.data() != null &&
                (doc.data() as Map<String, dynamic>).containsKey('coaches') &&
                (doc['coaches'] as List).contains(coachId))
            .length;

        int sessionsThisWeek = weeklySessionsSnapshot.docs
            .where((doc) =>
                doc.data() != null &&
                (doc.data() as Map<String, dynamic>).containsKey('coaches') &&
                (doc['coaches'] as List).contains(coachId))
            .length;

        // 🔥 If the coach exceeds their limit, add them to blocked list
        if (sessionsToday >= maxPerDay || sessionsThisWeek >= maxPerWeek) {
          blockedCoaches.add({
            'id': coachId,
            'name': coachName,
            'todaySessions': sessionsToday,
            'weekSessions': sessionsThisWeek,
            'maxPerDay': maxPerDay,
            'maxPerWeek': maxPerWeek,
          });
        }
      }

      // ✅ If any coach is over the limit, show warning before proceeding
      if (blockedCoaches.isNotEmpty) {
        _showCoachLimitWarning(blockedCoaches);
        return;
      }

      // ✅ Save the session
      if (widget.session == null ||
          (widget.session?.containsKey('id') ?? false) == false) {
        // If session doesn't exist, create a new one
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Séance ajoutée avec succès !')),
        );
      } else {
        // If session exists, update it
        final existingDoc = await _firestore
            .collection('trainings')
            .doc(widget.session!['id'])
            .get();

        if (existingDoc.exists) {
          await _firestore
              .collection('trainings')
              .doc(widget.session!['id'])
              .update(data);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Séance mise à jour avec succès !')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur: La séance n\'existe pas!')),
          );
          return;
        }
      }

      // ✅ Update statistics for each assigned coach
      for (String coachId in _selectedCoaches) {
        final statsRef = _firestore.collection('coachStatistics').doc(coachId);
        final statsDoc = await statsRef.get();

        if (statsDoc.exists) {
          await statsRef.update({
            'trainingCount': FieldValue.increment(1),
            'lastSession': _date.toIso8601String(),
          });
        } else {
          await statsRef.set({
            'coachId': coachId,
            'trainingCount': 1,
            'lastSession': _date.toIso8601String(),
          });
        }
      }

      // ✅ **Update `_coachCurrentSessions` in UI Immediately**
      for (String coachId in _selectedCoaches) {
        setState(() {
          _coachCurrentSessions[coachId] =
              (_coachCurrentSessions[coachId] ?? 0) + 1;
        });
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sauvegarde : $e')),
      );
    }
  }
}
