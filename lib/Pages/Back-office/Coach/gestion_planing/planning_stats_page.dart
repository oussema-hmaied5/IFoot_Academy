// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/Pages/Back-office/backend_template.dart';

class PlanningStatsPage extends StatefulWidget {
  const PlanningStatsPage({Key? key}) : super(key: key);

  @override
  _PlanningStatsPageState createState() => _PlanningStatsPageState();
}

class _PlanningStatsPageState extends State<PlanningStatsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  /// **Fetch all necessary stats**
  Future<void> _fetchStats() async {
    try {
      final groupSnapshot = await _firestore.collection('groups').get();
      final cancelSnapshot = await _firestore.collection('cancellations').get();
      final championshipSnapshot =
          await _firestore.collection('championships').get(); // ✅ FIXED
      final friendlySnapshot =
          await _firestore.collection('friendlyMatches').get();
      final tournamentSnapshot =
          await _firestore.collection('tournaments').get();
      final playerSnapshot = await _firestore.collection('children').get();


      final stats = {
        '📌 Groupes Loisirs': 0,
        '📌 Groupes Perfectionnement': 0,
        '👥 Joueurs': playerSnapshot.docs.length,
        '⚽ Matches Amicaux': friendlySnapshot.docs.length,
        '🥇 Tournois': tournamentSnapshot.docs.length,
        '🏆 Championnats': championshipSnapshot.docs.length, // ✅ FIXED
        '❌ Annulations': cancelSnapshot.docs.length,
      };

      for (var doc in groupSnapshot.docs) {
        final data = doc.data();
        final type = data['type'] ?? 'Loisirs';
        if (type.toLowerCase() == 'loisirs') {
          stats['📌 Groupes Loisirs'] = (stats['📌 Groupes Loisirs'] ?? 0) + 1;
        } else if (type.toLowerCase() == 'perfectionnement') {
          stats['📌 Groupes Perfectionnement'] =
              (stats['📌 Groupes Perfectionnement'] ?? 0) + 1;
        }
      }

      setState(() {
        _stats = stats;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la récupération des stats : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isWideScreen = MediaQuery.of(context).size.width > 600;

    return TemplatePageBack(
      title: 'Statistiques des Plannings',
      footerIndex: 3,
      isCoach: true,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📊 Statistiques Générales',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent),
              ),
              const SizedBox(height: 20),
              isWideScreen ? _buildStatsChart() : _buildPieChart(),
              const SizedBox(height: 20),
              _buildSummarySection(),
            ],
          ),
        ),
      ),
    );
  }

 /// **Interactive Pie Chart**
  Widget _buildPieChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "📊 Répartition des Statistiques",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: _stats.entries.map((entry) {
                    return PieChartSectionData(
                      color: _getColorForCategory(entry.key),
                      value: entry.value.toDouble(),
                      title: "${entry.value}",
                      radius: 50,
                      titleStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    );
                  }).toList(),
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      if (event is FlTapUpEvent && pieTouchResponse?.touchedSection != null) {
                        final index = pieTouchResponse!.touchedSection!.touchedSectionIndex;
                        if (index >= 0 && index < _stats.length) {
                          final String category = _stats.keys.elementAt(index);
                          final int value = _stats[category] ?? 0;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("$category : $value"), duration: const Duration(seconds: 2)),
                          );
                        }
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// **Interactive Bar Chart**
  Widget _buildStatsChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceBetween,
              maxY: (_stats.values.reduce((a, b) => a > b ? a : b) * 1.2).toDouble(),
              barTouchData: BarTouchData(
                touchCallback: (FlTouchEvent event, barTouchResponse) {
                  if (event is FlTapUpEvent && barTouchResponse?.spot != null) {
                    final index = barTouchResponse!.spot!.touchedBarGroupIndex;
                    if (index >= 0 && index < _stats.length) {
                      final String category = _stats.keys.elementAt(index);
                      final int value = _stats[category] ?? 0;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("$category : $value"), duration: const Duration(seconds: 2)),
                      );
                    }
                  }
                },
              ),
              titlesData: FlTitlesData(leftTitles: SideTitles(showTitles: true)),
              barGroups: List.generate(_stats.length, (index) {
                return BarChartGroupData(x: index, barRods: [
                  BarChartRodData(
                    y: _stats.values.elementAt(index).toDouble(),
                    colors: [_getColorForCategory(_stats.keys.elementAt(index))],
                    width: 22,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ]);
              }),
              gridData: FlGridData(show: false),
            ),
          ),
        ),
      ),
    );
  }

  /// **Summary Section with Cards**
  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategoryTitle("📌 Groupes & Joueurs"),
        _buildSummaryRow('📌 Groupes Loisirs', _stats['📌 Groupes Loisirs'] ?? 0),
        _buildSummaryRow('📌 Groupes Perfectionnement',
            _stats['📌 Groupes Perfectionnement'] ?? 0),
        _buildSummaryRow('👥 Joueurs', _stats['👥 Joueurs'] ?? 0),

        const SizedBox(height: 15),

        _buildCategoryTitle("⚽ Entraînements & Compétitions"),
        _buildSummaryRow('⚽ Matches Amicaux', _stats['⚽ Matches Amicaux'] ?? 0),
        _buildSummaryRow('🥇 Tournois', _stats['🥇 Tournois'] ?? 0),
        _buildSummaryRow('🏆 Championnats', _stats['🏆 Championnats'] ?? 0),

        const SizedBox(height: 15),

        _buildCategoryTitle("❌ Annulations & Problèmes"),
        _buildSummaryRow('❌ Annulations', _stats['❌ Annulations'] ?? 0),
      ],
    );
  }

  Widget _buildCategoryTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 5),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, int value) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(
          value.toString(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

   /// **Color Mapping for Each Category**
 Color _getColorForCategory(String category) {
  switch (category) {
    case '📌 Groupes Loisirs':
      return Colors.blue;
    case '📌 Groupes Perfectionnement':
      return Colors.green;
    case '👥 Joueurs':
      return Colors.teal;

    case '🏆 Matches Amicaux':
      return Colors.purple;
    case '🥇 Tournois':
      return Colors.red;
    case '🏅 Championnats':
      return Colors.deepPurple;

    case '❌ Annulations':
      return Colors.grey;
    default:
      return Colors.black;
  }
}

}
