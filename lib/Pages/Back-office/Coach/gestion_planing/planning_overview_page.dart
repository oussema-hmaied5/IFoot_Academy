import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/Pages/Back-office/Backend_template.dart';

import 'planning_form_page.dart';

class PlanningOverviewPage extends StatefulWidget {
  const PlanningOverviewPage({Key? key}) : super(key: key);

  @override
  _PlanningOverviewPageState createState() => _PlanningOverviewPageState();
}

class _PlanningOverviewPageState extends State<PlanningOverviewPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Map<String, List<Map<String, dynamic>>> _weeklyPlannings;
  final List<String> _weekDays = [
    "Lundi",
    "Mardi",
    "Mercredi",
    "Jeudi",
    "Vendredi",
    "Samedi",
    "Dimanche"
  ];
  int _selectedDayIndex = 0; // Index du jour actuellement sélectionné

  @override
  void initState() {
    super.initState();
    _weeklyPlannings = {};
    _fetchWeeklyPlannings();
  }

  Future<void> _fetchWeeklyPlannings() async {
  try {
    final snapshot = await _firestore.collection('trainings').get();
    final weekPlannings = <String, List<Map<String, dynamic>>>{};

    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1)); // Début de la semaine (lundi)
    final endOfWeek = startOfWeek.add(const Duration(days: 6)); // Fin de la semaine (dimanche)

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data.containsKey('date')) {
        final date = DateTime.parse(data['date']).toLocal();

        // Filtrer uniquement les séances entre le début et la fin de la semaine courante
        if ((date.isAtSameMomentAs(startOfWeek) || date.isAfter(startOfWeek)) &&
            (date.isBefore(endOfWeek) || date.isAtSameMomentAs(endOfWeek))) {
          final day = _weekDays[date.weekday - 1]; // Récupérer le jour correspondant

          if (!weekPlannings.containsKey(day)) {
            weekPlannings[day] = [];
          }

          // Fetching group type
          final groupType = await _fetchGroupType(data['groupId']);

          // Fetching coach names
          final coachNames = await _fetchCoachNames(data['coaches']);

          // Adding to weekly plannings
          weekPlannings[day]!.add({
            'id': doc.id,
            'groupName': data['groupName'],
            'groupType': groupType, // Ajoutez le type de groupe ici
            'type': data['type'] ?? 'Training',
            'startTime': data['startTime'],
            'endTime': data['endTime'],
            'date': data['date'],
            'coaches': coachNames,
          });
        }
      }
    }

    setState(() {
      _weeklyPlannings = weekPlannings;
    });
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur lors de la récupération des plannings : $e'),
      ),
    );
  }
}

Future<String> _fetchGroupType(String groupId) async {
  try {
    final groupDoc = await _firestore.collection('groups').doc(groupId).get();
    if (groupDoc.exists && groupDoc.data() != null) {
      return groupDoc.data()!['type'] ?? 'Inconnu';
    }
  } catch (e) {
    print('Erreur lors de la récupération du type de groupe : $e');
  }
  return 'Inconnu';
}


  Future<List<String>> _fetchCoachNames(List<dynamic>? coachIds) async {
    if (coachIds == null || coachIds.isEmpty) return [];

    try {
      return await Future.wait(
        coachIds.map((id) async {
          final coachDoc = await _firestore.collection('coaches').doc(id).get();
          return coachDoc.exists && coachDoc.data() != null
              ? coachDoc.data()!['name']
              : 'Inconnu';
        }),
      );
    } catch (e) {
      print('Erreur lors de la récupération des noms des coachs : $e');
      return [];
    }
  }

  Widget _buildDayTabs() {
    return Container(
      color: Colors.blueAccent,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // Permet le défilement horizontal
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(
            _weekDays.length,
            (index) => GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDayIndex = index;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 12.0, horizontal: 16.0),
                child: Text(
                  _weekDays[index],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _selectedDayIndex == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

 Widget _buildTrainingList(String day) {
  final plannings = _weeklyPlannings[day] ?? [];
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
            planning['type'] == 'Match' ? Icons.sports_soccer : Icons.fitness_center,
            color: planning['type'] == 'Match' ? Colors.green : Colors.blue,
          ),
          title: Text(
            planning['groupName'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Type: ${planning['type']}', style: const TextStyle(color: Colors.black87)),
              Text('Type du groupe: ${planning['groupType']}',
                  style: const TextStyle(color: Colors.black87)), // Affiche le type du groupe
              Text('Heure: ${planning['startTime']} - ${planning['endTime']}',
                  style: const TextStyle(color: Colors.black87)),
              if (planning['coaches'] != null)
                Text(
                  'Coach(s): ${List<String>.from(planning['coaches']).join(", ")}',
                  style: const TextStyle(color: Colors.black87),
                ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit, color: Colors.orange),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlanningFormPage(session: planning),
                ),
              ).then((_) => _fetchWeeklyPlannings());
            },
          ),
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return TemplatePageBack(
      title: 'Aperçu du Planning',
      footerIndex: 2,
      isCoach: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'Ajouter une séance',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PlanningFormPage()),
            ).then((_) => _fetchWeeklyPlannings()); // Rafraîchir après ajout
          },
        ),
      ],
      body: Column(
        children: [
          _buildDayTabs(), // Onglets en haut
          Expanded(
            child: _buildTrainingList(_weekDays[_selectedDayIndex]),
          ),
        ],
      ),
    );
  }
}
