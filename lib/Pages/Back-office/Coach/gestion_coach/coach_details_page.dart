// ignore_for_file: unused_element, duplicate_ignore

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/Pages/Back-office/backend_template.dart';
import 'package:intl/intl.dart';

class CoachDetailsPage extends StatefulWidget {
  final String coachId;

  const CoachDetailsPage({Key? key, required this.coachId}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _CoachDetailsPageState createState() => _CoachDetailsPageState();
}

class _CoachDetailsPageState extends State<CoachDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTimeRange? _selectedRange;
  bool _showLoisirGroups = false;
  bool _showPerfectionnementGroups = false;

  @override
  void initState() {
    super.initState();
    _selectedRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 7)),
      end: DateTime.now(),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      initialDateRange: _selectedRange,
    );
    if (picked != null) {
      setState(() {
        _selectedRange = picked;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return TemplatePageBack(
      title: ('Détails du Coach'),
      footerIndex: 2,
      isCoach: true,
      body: FutureBuilder<DocumentSnapshot>(
        future: _firestore.collection('coaches').doc(widget.coachId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Coach introuvable.'));
          }

          final Map<String, dynamic> coach =
              snapshot.data!.data() as Map<String, dynamic>;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildHeaderSection(coach),
              _buildDateRangeSelector(context),
              _buildGroupTypeDistribution(),
              _buildGeneralStats(),
              _buildDetailsSection('Informations Personnelles', [
                _buildDetailRow('Nom', coach['name'] ?? 'Non spécifié'),
                _buildDetailRow('Email', coach['email'] ?? 'Non spécifié'),
                _buildDetailRow('Téléphone', coach['phone'] ?? 'Non spécifié'),
                _buildDetailRow('Adresse', coach['address'] ?? 'Non spécifié'),
              ]),
              _buildDetailsSection('Informations Professionnelles', [
                _buildDetailRow(
                    'Salaire', '${coach['salary'] ?? 'Non spécifié'} Dinars'),
                _buildDetailRow('Max Séances/Jour',
                    coach['maxSessionsPerDay']?.toString() ?? '0'),
                _buildDetailRow('Max Séances/Semaine',
                    coach['maxSessionsPerWeek']?.toString() ?? '0'),
                _buildDetailRow('Niveau', coach['coachLevel'] ?? 'Non spécifié'),

              ]),
            ],
          );
        },
      ),
    );
  }

  /// ✅ **Build Expandable Sections for Loisir & Perfectionnement**
  Widget _buildGroupTypeDistribution() {
  return FutureBuilder<Map<String, Map<String, dynamic>>>(
    future: _fetchGroupTrainingStats(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
        return const Center(child: Text('Aucune donnée disponible.'));
      }

      final stats = snapshot.data!;

      // ✅ Ensure the keys exist before accessing them
      final loisirStats = stats.containsKey('Loisirs') ? stats['Loisirs']! : {'total': 0, 'groups': <String, int>{}};
      final perfectionnementStats = stats.containsKey('Perfectionnement')
          ? stats['Perfectionnement']!
          : {'total': 0, 'groups': <String, int>{}};

      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🏆 Section Title with Icon
           const  Row(
                children: [
                  Icon(Icons.bar_chart, color: Colors.blueAccent, size: 28),
                  SizedBox(width: 10),
                  Text(
                    "📊 Répartition des Entraînements",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 🏖️ Loisir & 🏅 Perfectionnement Sections
              _buildCategoryExpansion("🏖️ Loisirs", loisirStats, _showLoisirGroups, () {
                setState(() {
                  _showLoisirGroups = !_showLoisirGroups;
                });
              }),

              _buildCategoryExpansion("🏅 Perfectionnement", perfectionnementStats, _showPerfectionnementGroups, () {
                setState(() {
                  _showPerfectionnementGroups = !_showPerfectionnementGroups;
                });
              }),
            ],
          ),
        ),
      );
    },
  );
}
/// ✅ **Creates Expandable Sections for Loisir & Perfectionnement**
Widget _buildCategoryExpansion(String title, Map<String, dynamic> data, bool isExpanded, VoidCallback onToggle) {
  return Column(
    children: [
      ListTile(
        title: Text(
          "$title (${data['total']})",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        trailing: IconButton(
          icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.blueAccent),
          onPressed: onToggle,
        ),
      ),
      if (isExpanded)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            children: (data['groups'] as Map<String, int>).entries.map((entry) {
              return _buildDetailRow(entry.key, entry.value.toString());
            }).toList(),
          ),
        ),
      const Divider(),
    ],
  );
}


  /// ✅ **Fetch Group Type Statistics with Coach Training Counts**
 /// ✅ Fetch Training Stats for ALL Groups (Even with 0 Trainings)
Future<Map<String, Map<String, dynamic>>> _fetchGroupTrainingStats() async {
  try {
    if (_selectedRange == null) {
      return {
        'Loisirs': {'total': 0, 'groups': <String, int>{}},
        'Perfectionnement': {'total': 0, 'groups': <String, int>{}},
      };
    }

    // 🔥 Step 1: Fetch all groups (Loisir & Perfectionnement)
    final allGroupsSnapshot = await _firestore.collection('groups').get();
    Map<String, Map<String, dynamic>> groupStats = {
      'Loisirs': {'total': 0, 'groups': <String, int>{}},
      'Perfectionnement': {'total': 0, 'groups': <String, int>{}},
    };

    for (var doc in allGroupsSnapshot.docs) {
      final groupData = doc.data();
      String groupName = groupData['name'] ?? 'Inconnu';
      String groupType = groupData['type'] ?? 'Inconnu';

      if (groupStats.containsKey(groupType)) {
        groupStats[groupType]!['groups'][groupName] = 0; // 🔥 Default: 0 trainings
      }
    }

    // 🔥 Step 2: Fetch only trainings within the selected date range
    final trainingSnapshot = await _firestore
        .collection('trainings')
        .where('coaches', arrayContains: widget.coachId)
        .where('date', isGreaterThanOrEqualTo: _selectedRange!.start.toIso8601String())
        .where('date', isLessThanOrEqualTo: _selectedRange!.end.toIso8601String())
        .get();

    // 🔥 Step 3: Update training counts for groups that were trained
    for (var doc in trainingSnapshot.docs) {
      final trainingData = doc.data();
      String groupId = trainingData['groupId'] ?? '';

      DocumentSnapshot groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (groupDoc.exists && groupDoc.data() != null) {
        String groupName = (groupDoc.data() as Map<String, dynamic>)['name'] ?? 'Inconnu';
        String groupType = (groupDoc.data() as Map<String, dynamic>)['type'] ?? 'Inconnu';

        if (groupStats.containsKey(groupType)) {
          groupStats[groupType]!['groups'][groupName] =
              (groupStats[groupType]!['groups'][groupName] ?? 0) + 1;
          groupStats[groupType]!['total'] =
              (groupStats[groupType]!['total'] ?? 0) + 1;
        }
      }
    }

    return groupStats;
  } catch (e) {
    return {
      'Loisirs': {'total': 0, 'groups': <String, int>{}},
      'Perfectionnement': {'total': 0, 'groups': <String, int>{}},
    };
  }
}


  /// ✅ **Builds the Expandable Section**
  // ignore: unused_element
  Widget _buildExpandableSection(String title, Map<String, dynamic> data,
      bool isExpanded, VoidCallback onToggle) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Column(
        children: [
          ListTile(
            title: Text('$title (${data['total']})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            trailing: IconButton(
              icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.blueAccent),
              onPressed: onToggle,
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children:
                    (data['groups'] as Map<String, int>).entries.map((entry) {
                  return _buildDetailRow(entry.key, entry.value.toString());
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }



  Widget _buildHeaderSection(Map<String, dynamic> coach) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: coach.containsKey('imageUrl') && coach['imageUrl'] != null
              ? Image.network(
                  coach['imageUrl'],
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
        ),
        const SizedBox(height: 10),
        Text(
          coach['name'] ?? 'Non spécifié',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeSelector(BuildContext context) {
    return Card(
      elevation: 3,
      child: ListTile(
        title: Text(
          "Période: ${DateFormat('dd/MM/yyyy').format(_selectedRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedRange!.end)}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.date_range),
        onTap: () => _selectDateRange(context),
      ),
    );
  }

  Future<Map<String, int>> _fetchMatchTournamentStats() async {
    final snapshot = await _firestore
        .collection('trainings') // Collection des entraînements et compétitions
        .where('coaches', arrayContains: widget.coachId)
        .get();

    int trainingCount = 0;
    int tournamentCount = 0;
    int championshipCount = 0;
    int friendlyMatchCount = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      switch (data['type']) {
        case 'Training':
          trainingCount++;
          break;
        case 'Tournament':
          tournamentCount++;
          break;
        case 'Championship':
          championshipCount++;
          break;
        case 'FriendlyMatch':
          friendlyMatchCount++;
          break;
      }
    }

    return {
      'Training': trainingCount,
      'Tournament': tournamentCount,
      'Championship': championshipCount,
      'FriendlyMatch': friendlyMatchCount,
    };
  }

Future<Map<int, int>> _fetchTrainingEvolutionData() async {
  try {
    final snapshot = await _firestore
        .collection('trainings')
        .where('coaches', arrayContains: widget.coachId) // Sessions du coach
        .orderBy('date', descending: false)
        .get();

    Map<int, int> monthlyData = {}; // Clé: Mois (1=Jan, 2=Fév), Valeur: Nb de sessions

    for (var doc in snapshot.docs) {
      final data = doc.data();

      if (data.containsKey('date') && data['date'] != null) {
        DateTime date;

        if (data['date'] is Timestamp) {
          // ✅ Si c'est un Timestamp, convertir normalement
          date = (data['date'] as Timestamp).toDate();
        } else if (data['date'] is String) {
          try {
            // ✅ Essayer de convertir depuis une String
            date = DateTime.parse(data['date']);
          } catch (e) {
            continue; // ⏭️ Ignorer cette entrée si erreur
          }
        } else {
          continue; // ⏭️ Passer si format non reconnu
        }

        int month = date.month; // Récupérer le mois
        monthlyData[month] = (monthlyData[month] ?? 0) + 1; // Compter les sessions
      }
    }

    return monthlyData;
  } catch (e) {
    return {};
  }
}


 

  Widget _buildDetailsSection(String title, List<Widget> details) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            ...details,
          ],
        ),
      ),
    );
  }

  Future<Map<String, int>> _fetchGeneralStats() async {
    int trainingCount = 0;
    int tournamentCount = 0;
    int championshipCount = 0;
    int friendlyMatchCount = 0;

    // 📌 Récupération des trainings du coach
    final trainingSnapshot = await _firestore
        .collection('trainings')
        .where('coaches', arrayContains: widget.coachId)
        .get();

    trainingCount = trainingSnapshot.docs.length;

    // 📌 Comptabilisation des championnats où le coach est assigné via les match days
    final championshipSnapshot =
        await _firestore.collection('championships').get();
    championshipCount = 0; // ✅ Reset du compteur

    for (var doc in championshipSnapshot.docs) {
      final championshipData = doc.data();

      if (championshipData.containsKey('matchDays') &&
          championshipData['matchDays'] is List) {
        for (var journee in championshipData['matchDays']) {
          if (journee is Map<String, dynamic> &&
              journee.containsKey('coaches') &&
              journee['coaches'] is List) {
            if (journee['coaches'].contains(widget.coachId)) {
              championshipCount++; // ✅ Chaque matchDay compte comme 1 championnat
            }
          }
        }
      }
    }

    // 📌 Récupération des tournois
    final tournamentSnapshot = await _firestore
        .collection('tournaments')
        .where('coaches', arrayContains: widget.coachId)
        .get();
    tournamentCount = tournamentSnapshot.docs.length;

    // 📌 Récupération des matchs amicaux
    final friendlyMatchSnapshot = await _firestore
        .collection('friendlyMatches')
        .where('coaches', arrayContains: widget.coachId)
        .get();
    friendlyMatchCount = friendlyMatchSnapshot.docs.length;

    return {
      'Training': trainingCount,
      'Tournament': tournamentCount,
      'Championship':
          championshipCount, // ✅ Maintenant ça représente bien les matchDays
      'FriendlyMatch': friendlyMatchCount,
    };
  }

  Widget _buildGeneralStats() {
    return FutureBuilder<Map<String, int>>(
      future: _fetchGeneralStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Aucune donnée disponible.'));
        }

        final stats = snapshot.data!;

        final trainingCount = stats['Training'] ?? 0;
        final tournamentCount = stats['Tournament'] ?? 0;
        final championshipCount = stats['Championship'] ?? 0;
        final friendlyMatchCount = stats['FriendlyMatch'] ?? 0;
        final matchDaysCount = stats['MatchDays'] ??
            0; // ✅ Nombre de journées où le coach est affecté

        final maxY = (trainingCount +
                tournamentCount +
                championshipCount +
                friendlyMatchCount +
                matchDaysCount)
            .toDouble();
        final adjustedMaxY = maxY == 0 ? 1 : maxY;

        return Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📊 Statistiques Générales',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 250,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceBetween,
                      maxY: adjustedMaxY.toDouble(),
                      barGroups: [
                        _buildBar(
                            1, trainingCount, Colors.blue, "🏋️‍♂️\nTrainings"),
                        _buildBar(
                            2, tournamentCount, Colors.green, "🏆\nTournois"),
                        _buildBar(3, championshipCount, Colors.purple,
                            "📅\nMatch Days"), // ✅ Correction ici
                        _buildBar(4, friendlyMatchCount, Colors.orange,
                            "🤝\nAmicaux"),
                      ],
                      titlesData: FlTitlesData(
                        leftTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          reservedSize: 30,
                          getTitles: (value) => value.toInt().toString(),
                        ),
                        bottomTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitles: (value) {
                            switch (value.toInt()) {
                              case 1:
                                return "🏋️‍♂️\nTrain";

                              case 2:
                                return "🥇\nTour";
                              case 3:
                                return "🏆\nChamp";

                              case 4:
                                return "🤝\nAmic";

                              default:
                                return "";
                            }
                          },
                          getTextStyles: (context, value) => const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        checkToShowHorizontalLine: (value) => value % 1 == 0,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: const Color.fromARGB(255, 213, 27, 27),
                          strokeWidth: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// ✅ Fonction pour générer une barre
  BarChartGroupData _buildBar(int x, int value, Color color, String label) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          y: value.toDouble(),
          colors: [color],
          width: 22, // ✅ Barre plus fine pour éviter le chevauchement
          borderRadius: BorderRadius.circular(6),
        ),
      ],
      showingTooltipIndicators: [0],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
