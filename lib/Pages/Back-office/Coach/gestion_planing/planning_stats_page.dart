import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/Pages/Back-office/Backend_template.dart';

class PlanningStatsPage extends StatefulWidget {
  const PlanningStatsPage({Key? key}) : super(key: key);

  @override
  _PlanningStatsPageState createState() => _PlanningStatsPageState();
}

class _PlanningStatsPageState extends State<PlanningStatsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Map<String, int> _stats = {
    'Loisirs': 0,
    'Perfectionnement': 0,
    'Matches': 0,
    'Tournois': 0,
  };

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final snapshot = await _firestore.collection('groups').get();
      final stats = {
        'Loisirs': 0,
        'Perfectionnement': 0,
        'Matches': 0,
        'Tournois': 0,
      };

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final type = data['type'] ?? 'Loisirs';
        if (stats.containsKey(type)) {
          stats[type] = (stats[type] ?? 0) + 1;
        }
      }

      setState(() {
        _stats = stats;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur lors de la récupération des stats : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePageBack(
      title: 'Statistiques des Plannings',
      footerIndex: 3,
      isCoach: true,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiques Générales',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _buildStatsChart(),
            ),
            const SizedBox(height: 20),
            _buildSummarySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: (_stats.values.reduce((a, b) => a > b ? a : b) * 1.2)
                .toDouble(),
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              leftTitles: SideTitles(showTitles: true),
              bottomTitles: SideTitles(
                showTitles: true,
                margin: 10,
                getTitles: (double value) {
                  switch (value.toInt()) {
                    case 0:
                      return 'Lois';
                    case 1:
                      return 'Perfec';
                    case 2:
                      return 'Matches';
                    case 3:
                      return 'Tournois';
                    default:
                      return '';
                  }
                },
              ),
            ),
            barGroups: [
              BarChartGroupData(x: 0, barRods: [
                BarChartRodData(
                  y: _stats['Loisirs']?.toDouble() ?? 0,
                  colors: [Colors.blue],
                ),
              ]),
              BarChartGroupData(x: 1, barRods: [
                BarChartRodData(
                  y: _stats['Perfectionnement']?.toDouble() ?? 0,
                  colors: [Colors.green],
                ),
              ]),
              BarChartGroupData(x: 2, barRods: [
                BarChartRodData(
                  y: _stats['Matches']?.toDouble() ?? 0,
                  colors: [Colors.orange],
                ),
              ]),
              BarChartGroupData(x: 3, barRods: [
                BarChartRodData(
                  y: _stats['Tournois']?.toDouble() ?? 0,
                  colors: [Colors.red],
                ),
              ]),
            ],
            gridData: FlGridData(show: false),
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Résumé',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent),
            ),
            const SizedBox(height: 10),
            _buildSummaryRow('Total Séances Loisirs', '${_stats['Loisirs']}'),
            _buildSummaryRow('Total Séances Perfectionnement',
                '${_stats['Perfectionnement']}'),
            _buildSummaryRow('Total Matches', '${_stats['Matches']}'),
            _buildSummaryRow('Total Tournois', '${_stats['Tournois']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent),
          ),
        ],
      ),
    );
  }
}
