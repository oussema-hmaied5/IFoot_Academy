// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../backend_template.dart';
import 'planning_form_page.dart';

class PlanningOverviewPage extends StatefulWidget {
  const PlanningOverviewPage({Key? key}) : super(key: key);

  @override
  _PlanningOverviewPageState createState() => _PlanningOverviewPageState();
}

class _PlanningOverviewPageState extends State<PlanningOverviewPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Map<String, List<Map<String, dynamic>>> _dailyPlannings;
  int _selectedDayIndex = 10; // Toujours centré sur aujourd’hui
  late List<DateTime> _dateRange; // Liste des 21 jours affichés
  final ScrollController _scrollController =
      ScrollController(); // 🔹 Auto-scroll control

  @override
  void initState() {
    super.initState();
    _dailyPlannings = {};
    _generateDateRange();
    _fetchDailyPlannings();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollToSelectedDate()); // 🔹 Auto-scroll
  }

  /// 📅 **Générer les 21 jours (10 avant, aujourd’hui, 10 après)**
  void _generateDateRange() {
    DateTime today = DateTime.now();
    _dateRange = List.generate(21, (index) {
      return today
          .subtract(Duration(days: 10 - index)); // Centré sur aujourd’hui
    });
  }

  /// 🔹 **Auto-scroll to today's date**
  void _scrollToSelectedDate() {
    double screenWidth = MediaQuery.of(context).size.width;
    double scrollPosition =
        (_selectedDayIndex * 60) - (screenWidth / 2) + 30; // Center it
    _scrollController.jumpTo(
        scrollPosition.clamp(0.0, _scrollController.position.maxScrollExtent));
  }

  /// 🔥 **Récupérer les plannings pour 21 jours**
  Future<void> _fetchDailyPlannings() async {
    try {
      final snapshot = await _firestore.collection('trainings').get();
      final dailyPlannings = <String, List<Map<String, dynamic>>>{};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey('date')) {
          final date = DateTime.parse(data['date']).toLocal();
          final formattedDate =
              DateFormat('dd.MM EEE', 'fr_FR').format(date); // "22.02 DIM"

          if (!dailyPlannings.containsKey(formattedDate)) {
            dailyPlannings[formattedDate] = [];
          }

          // 🆕 Récupérer les numéros des coachs (et pas l'ID)
          final coachNumbers = await _fetchCoachName(data['coaches']);

          dailyPlannings[formattedDate]!.add({
            'id': doc.id,
            'groupName': data['groupName'],
            'type': data['type'] ?? 'Entrainement',
            'startTime': data['startTime'],
            'endTime': data['endTime'],
            'date': data['date'],
            'coaches': coachNumbers,
          });
        }
      }

      setState(() {
        _dailyPlannings = dailyPlannings;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur lors de la récupération des plannings : $e')),
      );
    }
  }

  /// 🔢 **Récupérer les numéros des coachs au lieu des IDs**
  Future<List<String>> _fetchCoachName(List<dynamic>? coachIds) async {
    if (coachIds == null || coachIds.isEmpty) return [];

    try {
      return await Future.wait(
        coachIds.map((id) async {
          final coachDoc = await _firestore.collection('coaches').doc(id).get();
          return coachDoc.exists && coachDoc.data() != null
              ? coachDoc
                  .data()!['name']
                  .toString() // 🔹 Récupérer le numéro du coach
              : 'Inconnu';
        }),
      );
    } catch (e) {
      return [];
    }
  }

  /// **Affichage des onglets des jours (style demandé)**
  Widget _buildDayTabs() {
    return Container(
      color: const Color.fromARGB(255, 5, 197, 159),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _scrollController, // 🔹 Attach here

        child: Row(
          children: List.generate(
            _dateRange.length,
            (index) => GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDayIndex = index;
                });
                _scrollToSelectedDate(); // 🔹 Update scroll when tapped
              },
              child: Container(
                width: 60,
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedDayIndex == index
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('MMM', 'fr_FR')
                          .format(_dateRange[index])
                          .toUpperCase(), // "FEV"
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _selectedDayIndex == index
                            ? Colors.blueAccent
                            : Colors.white,
                      ),
                    ),
                    Text(
                      DateFormat('dd').format(_dateRange[index]), // "22"
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _selectedDayIndex == index
                            ? Colors.blueAccent
                            : Colors.white,
                      ),
                    ),
                    Text(
                      DateFormat('EEE', 'fr_FR')
                          .format(_dateRange[index])
                          .toUpperCase(), // "DIM"
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _selectedDayIndex == index
                            ? Colors.blueAccent
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// **Afficher la liste des entraînements pour un jour sélectionné**
  Widget _buildTrainingList(String day) {
    final plannings = _dailyPlannings[day] ?? [];
    if (plannings.isEmpty) {
      return const Center(
        child: Text(
          'Aucun entraînement pour ce jour',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    return ListView.builder(
      itemCount: plannings.length,
      itemBuilder: (context, index) {
        final planning = plannings[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          elevation: 4,
          child: ListTile(
            leading: Icon(
              planning['type'] == 'Match'
                  ? Icons.sports_soccer
                  : Icons.sports_soccer,
              color: planning['type'] == 'Match' ? Colors.green : Colors.blue,
            ),
            title: Text(planning['groupName'],
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Type: ${planning['type']}',
                    style: const TextStyle(color: Colors.black87)),
                Text('Heure: ${planning['startTime']} - ${planning['endTime']}',
                    style: const TextStyle(color: Colors.black87)),
                if (planning['coaches'].isNotEmpty)
                  Text(
                      'Coach(s): ${List<String>.from(planning['coaches']).join(", ")}',
                      style: const TextStyle(color: Colors.black87)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 📝 Edit Button
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.black87),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PlanningFormPage(session: planning),
                      ),
                    ).then((updatedDate) {
                      if (updatedDate != null && updatedDate is DateTime) {
                        _updateSelectedDay(updatedDate);
                      }
                      _fetchDailyPlannings();
                    });
                  },
                ),
                // ❌ Cancel Button
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  onPressed: () => _showCancelDialog(planning['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _updateSelectedDay(DateTime updatedDate) {
    int newIndex = _dateRange.indexWhere(
      (date) =>
          DateFormat('dd.MM.yyyy').format(date) ==
          DateFormat('dd.MM.yyyy').format(updatedDate),
    );

    if (newIndex != -1) {
      setState(() {
        _selectedDayIndex = newIndex;
      });
      _scrollToSelectedDate();
    }
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
                      "Manque de joueurs",
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

  Future<void> _cancelTraining(String trainingId, String reason) async {
    try {
      final trainingDoc =
          await _firestore.collection('trainings').doc(trainingId).get();

      if (trainingDoc.exists) {
        final trainingData = trainingDoc.data();
        final groupId = trainingData?['groupId'] ?? 'unknown';

        await _firestore.collection('cancellations').add({
          'trainingId': trainingId,
          'groupName': trainingData?['groupName'] ?? 'Inconnu',
          'date': trainingData?['date'] ?? DateTime.now().toIso8601String(),
          'startTime': trainingData?['startTime'] ?? 'Non spécifié',
          'endTime': trainingData?['endTime'] ?? 'Non spécifié',
          'coaches': trainingData?['coaches'] ?? [],
          'reason': reason,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // ✅ Delete the training session
        await _firestore.collection('trainings').doc(trainingId).delete();

        // ✅ Send notification
        await _sendNotificationToUsers(groupId, reason);

        // ✅ Refresh UI
        _fetchDailyPlannings();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Séance annulée et enregistrée !")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de l'annulation : $e")),
      );
    }
  }

  Future<void> _sendNotificationToUsers(String groupId, String reason) async {
    try {
      await _firestore.collection('notifications').add({
        'groupId': groupId,
        'message': "L'entraînement du groupe a été annulé. Motif: $reason",
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Notification envoyée aux utilisateurs !")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur envoi de notification : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePageBack(
      title: 'Aperçu du Planning',
      footerIndex: 2,
      isCoach: true,
      body: Column(
        children: [
          _buildDayTabs(), // 📅 Onglets avec dates formatées
          Expanded(
            child: _buildTrainingList(DateFormat('dd.MM EEE', 'fr_FR')
                .format(_dateRange[_selectedDayIndex])),
          ),
        ],
      ),
    );
  }
}
