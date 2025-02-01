import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/Pages/Back-office/Backend_template.dart';
import 'package:intl/intl.dart';

class CoachDetailsPage extends StatelessWidget {
  final String coachId;

  const CoachDetailsPage({Key? key, required this.coachId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    return TemplatePageBack(
      title: 'Détails du Coach',
       footerIndex: 1,
      isCoach: true,
      body: FutureBuilder<DocumentSnapshot>(
        future: _firestore.collection('coaches').doc(coachId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Erreur lors du chargement.'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Coach introuvable.'));
          }

          final Map<String, dynamic> coach =
              snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                // Header Section
                _buildHeaderSection(coach),

                const SizedBox(height: 20),

                // Section Statistiques
                _buildStatsSection(),

                const SizedBox(height: 20),

                // Section Détails
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
                  _buildDetailRow(
                      'Situation Familiale',
                      coach['maritalStatus'] ?? 'Non spécifiée'),
                  _buildDetailRow(
                      'Nombre d’Enfants',
                      coach['numberOfChildren']?.toString() ?? 'Non spécifié'),
                ]),

                const SizedBox(height: 20),

                // Section Professionnelle
                _buildDetailsSection('Informations Professionnelles', [
                  _buildDetailRow(
                      'Salaire', '${coach['salary'] ?? 'Non spécifié'} Dinars'),
                  _buildDetailRow(
                      'Max Séances/Jour',
                      coach['maxSessionsPerDay']?.toString() ?? '0'),
                  _buildDetailRow(
                      'Max Séances/Semaine',
                      coach['maxSessionsPerWeek']?.toString() ?? '0'),
                  _buildDetailRow(
                    'Diplôme',
                    coach['diploma'] == 'Oui'
                        ? coach['diplomaType'] ?? 'Non spécifié'
                        : 'Aucun',
                  ),
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(Map<String, dynamic> coach) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.blueAccent,
          child: Text(
            coach['name'] != null && coach['name'].isNotEmpty
                ? coach['name'][0].toUpperCase()
                : '?',
            style: const TextStyle(fontSize: 24, color: Colors.white),
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

Widget _buildStatsSection() {
  return Card(
    elevation: 4,
    margin: const EdgeInsets.only(bottom: 16.0),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistiques',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('coachStatistics') // Example Firestore collection
                  .where('coachId', isEqualTo: coachId) // Filter by coachId
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucune donnée disponible.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final stats = snapshot.data!.docs;

                // Example: Parse Firestore data into a list of group statistics
                final barGroups = stats.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return BarChartGroupData(x: data['xAxisValue'], barRods: [
                    BarChartRodData(
                      y: data['loisirCount'] * 1.0, // Height of "Loisir" bar
                      colors: [Colors.blue],
                    ),
                    BarChartRodData(
                      y: data['perfectionnementCount'] * 1.0, // Height of "Perfectionnement" bar
                      colors: [Colors.green],
                    ),
                  ]);
                }).toList();

                return BarChart(
                  BarChartData(
                    barGroups: barGroups,
                    titlesData: FlTitlesData(
                      leftTitles: SideTitles(
                        showTitles: true,
                        getTitles: (value) => value.toString(),
                      ),
                      bottomTitles: SideTitles(
                        showTitles: true,
                        getTitles: (value) {
                          // Customize x-axis titles (e.g., Day, Week)
                          switch (value.toInt()) {
                            case 1:
                              return 'Day 1';
                            case 2:
                              return 'Day 2';
                            default:
                              return '';
                          }
                        },
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: true),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Graphique des séances (Loisir vs Perfectionnement)',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
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
                color: Colors.red
              ),
            ),
            const SizedBox(height: 10),
            ...details,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
