// coach_planning_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CoachPlanningPage extends StatelessWidget {
  final String coachId;
  const CoachPlanningPage({Key? key, required this.coachId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planning du Coach'),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: firestore.collection('trainings').where('coaches', arrayContains: coachId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Erreur lors du chargement.'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Aucune séance trouvée pour ce coach.'));
          }

          final sessions = snapshot.data!.docs;
          
          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final data = sessions[index].data() as Map<String, dynamic>;
              final date = DateTime.parse(data['date']);
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text('${data['groupName']} - ${data['type']}'),
                  subtitle: Text(
                    '${DateFormat('EEEE, dd MMM yyyy', 'fr_FR').format(date)}\nDe ${data['startTime']} à ${data['endTime']}',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
