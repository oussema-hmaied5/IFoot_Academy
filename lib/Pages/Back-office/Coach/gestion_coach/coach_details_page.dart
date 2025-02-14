import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/Pages/Back-office/Backend_template.dart';
import 'package:intl/intl.dart';

class CoachDetailsPage extends StatefulWidget {
  final String coachId;

  const CoachDetailsPage({Key? key, required this.coachId}) : super(key: key);

  @override
  _CoachDetailsPageState createState() => _CoachDetailsPageState();
}

class _CoachDetailsPageState extends State<CoachDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTimeRange? _selectedRange;

  @override
  void initState() {
    super.initState();
    _selectedRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
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
      title: 'Détails du Coach',
      footerIndex: 1,
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
              _buildStatsSection(),
              _buildMatchTournamentStats(),
              _buildGroupTypeDistribution(),
              _buildTrainingEvolutionGraph(),
              _buildDetailsSection('Informations Personnelles', [
                _buildDetailRow('Nom', coach['name'] ?? 'Non spécifié'),
                _buildDetailRow('Email', coach['email'] ?? 'Non spécifié'),
                _buildDetailRow('Téléphone', coach['phone'] ?? 'Non spécifié'),
                _buildDetailRow('Adresse', coach['address'] ?? 'Non spécifié'),
                _buildDetailRow(
                  'Date de Naissance',
                  coach['birthDate'] != null
                      ? DateFormat('dd/MM/yyyy').format(
                          (coach['birthDate'] as Timestamp).toDate(),
                        )
                      : 'Non spécifiée',
                ),
                _buildDetailRow('Situation Familiale',
                    coach['maritalStatus'] ?? 'Non spécifiée'),
                _buildDetailRow(
                    'Nombre d’Enfants',
                    coach['children']?.toString() ?? 'Non spécifié'),
              ]),
              _buildDetailsSection('Informations Professionnelles', [
                _buildDetailRow(
                    'Salaire', '${coach['salary'] ?? 'Non spécifié'} Dinars'),
                _buildDetailRow('Max Séances/Jour',
                    coach['maxSessionsPerDay']?.toString() ?? '0'),
                _buildDetailRow('Max Séances/Semaine',
                    coach['maxSessionsPerWeek']?.toString() ?? '0'),
                _buildDetailRow(
                  'Diplôme',
                  coach['diploma'] == 'Oui'
                      ? coach['diplomaType'] ?? 'Non spécifié'
                      : 'Aucun',
                ),
                _buildDetailRow('Niveau du Coach',
                    coach['coachLevel'] ?? 'Non spécifié'),
                const SizedBox(height: 10),
                const Text(
                  'Objectifs :',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...List<String>.from(coach['objectives'] ?? [])
                    .map((objective) => Text('- $objective'))
                    .toList(),
              ]),
            ],
          );
        },
      ),
    );
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

  Widget _buildHeaderSection(Map<String, dynamic> coach) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(50), // Circular image
          child: coach.containsKey('imageUrl') &&
                  coach['imageUrl'] != null &&
                  coach['imageUrl'].isNotEmpty
              ? Image.network(
                  coach['imageUrl'],
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.person, size: 100, color: Colors.grey),
                )
              : Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300], // Light grey background
                  ),
                  child: const Icon(
                    Icons.person, // Default user icon
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
        Text(
          coach['email'] ?? 'Email non spécifié',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }


  /// 📊 **Histogramme: Nombre de Matchs, Tournois, Championnats**
  Widget _buildMatchTournamentStats() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('trainings')
          .where('coaches', arrayContains: widget.coachId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Aucune donnée pour cette période.'));
        }

        int matchCount = 0;
        int tournamentCount = 0;
        int championshipCount = 0;

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          switch (data['type']) {
            case 'Match':
              matchCount++;
              break;
            case 'Tournament':
              tournamentCount++;
              break;
            case 'Championship':
              championshipCount++;
              break;
          }
        }

        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statistiques des Compétitions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (matchCount + tournamentCount + championshipCount)
                          .toDouble(),
                      barGroups: [
                        BarChartGroupData(
                          x: 1,
                          barRods: [
                            BarChartRodData(
                              y: matchCount.toDouble(),
                              colors: [Colors.blue],
                              width: 20,
                            ),
                          ],
                        ),
                        BarChartGroupData(
                          x: 2,
                          barRods: [
                            BarChartRodData(
                              y: tournamentCount.toDouble(),
                              colors: [Colors.green],
                              width: 20,
                            ),
                          ],
                        ),
                        BarChartGroupData(
                          x: 3,
                          barRods: [
                            BarChartRodData(
                              y: championshipCount.toDouble(),
                              colors: [Colors.red],
                              width: 20,
                            ),
                          ],
                        ),
                      ],
                      titlesData: FlTitlesData(
                        leftTitles: SideTitles(
                          showTitles: true,
                          getTitles: (value) => '${value.toInt()}',
                        ),
                        bottomTitles: SideTitles(
                          showTitles: true,
                          getTitles: (value) {
                            switch (value.toInt()) {
                              case 1:
                                return 'Matchs';
                              case 2:
                                return 'Tournois';
                              case 3:
                                return 'Championnats';
                              default:
                                return '';
                            }
                          },
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(show: false),
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

  /// 🥧 **Pie Chart: Distribution des types de groupes (Loisir vs Perfectionnement)**
  Widget _buildGroupTypeDistribution() {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore
          .collection('trainings')
          .where('coaches', arrayContains: widget.coachId)
          .where('date',
              isGreaterThanOrEqualTo: _selectedRange!.start.toIso8601String())
          .where('date',
              isLessThanOrEqualTo: _selectedRange!.end.toIso8601String())
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Aucune donnée pour cette période.'));
        }

        int loisirCount = 0;
        int perfectionnementCount = 0;

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['groupType'] == "Loisir") {
            loisirCount++;
          } else if (data['groupType'] == "Perfectionnement") {
            perfectionnementCount++;
          }
        }

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Répartition des Types de Groupes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: loisirCount.toDouble(),
                          title: 'Loisir (${loisirCount})',
                          color: Colors.blueAccent,
                          radius: 50,
                        ),
                        PieChartSectionData(
                          value: perfectionnementCount.toDouble(),
                          title: 'Perfectionnement (${perfectionnementCount})',
                          color: Colors.green,
                          radius: 50,
                        ),
                      ],
                      sectionsSpace: 5,
                      centerSpaceRadius: 40,
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


  /// ✅ **Sélecteur de période pour filtrer les statistiques**
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

  /// 📊 **Statistiques générales (Nombre de séances, matchs, tournois)**
  Widget _buildStatsSection() {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore
          .collection('trainings')
          .where('coaches', arrayContains: widget.coachId)
          .where('date',
              isGreaterThanOrEqualTo: _selectedRange!.start.toIso8601String())
          .where('date',
              isLessThanOrEqualTo: _selectedRange!.end.toIso8601String())
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Aucune donnée disponible.'));
        }

        int trainingCount = 0;
        int matchCount = 0;
        int tournamentCount = 0;

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          switch (data['type']) {
            case 'Training':
              trainingCount++;
              break;
            case 'Match':
              matchCount++;
              break;
            case 'Tournament':
              tournamentCount++;
              break;
          }
        }

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statistiques Générales',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildDetailRow('Total Séances', trainingCount.toString()),
                _buildDetailRow('Nombre de Matchs', matchCount.toString()),
                _buildDetailRow(
                    'Nombre de Tournois', tournamentCount.toString()),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 📈 **Évolution des séances sous forme de courbe**
  Widget _buildTrainingEvolutionGraph() {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore
          .collection('trainings')
          .where('coaches', arrayContains: widget.coachId)
          .where('date',
              isGreaterThanOrEqualTo: _selectedRange!.start.toIso8601String())
          .where('date',
              isLessThanOrEqualTo: _selectedRange!.end.toIso8601String())
          .orderBy('date', descending: true)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Aucune donnée pour cette période.'));
        }

        List<FlSpot> spots = [];
        List<QueryDocumentSnapshot> docs =
            snapshot.data!.docs.reversed.toList();
        for (int i = 0; i < docs.length; i++) {
          final data = docs[i].data() as Map<String, dynamic>;
          final DateTime date = DateTime.parse(data['date']);
          spots.add(FlSpot(i.toDouble(), i.toDouble()));
        }

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Évolution des Séances',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: SideTitles(
                          showTitles: true,
                          getTitles: (value) => '${value.toInt()}',
                        ),
                        bottomTitles: SideTitles(
                          showTitles: true,
                          getTitles: (value) {
                            switch (value.toInt()) {
                              case 1:
                                return 'Matchs';
                              case 2:
                                return 'Tournois';
                              case 3:
                                return 'Championnats';
                              default:
                                return '';
                            }
                          },
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          barWidth: 4,
                          colors: [Colors.blue],
                          belowBarData: BarAreaData(
                              show: true,
                              colors: [Colors.blue.withOpacity(0.3)]),
                        ),
                      ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text('$label:',
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text(value)),
        ],
      ),
    );
  }
}
