import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/models/group.dart';

import '../../Style/Backend_template.dart';
import 'add_groupe_page.dart';
import 'edit_groupe.dart';

class ManageGroupsPage extends StatefulWidget {
  const ManageGroupsPage({Key? key}) : super(key: key);

  @override
  _ManageGroupsPageState createState() => _ManageGroupsPageState();
}

class _ManageGroupsPageState extends State<ManageGroupsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _deleteGroup(String groupId, List<String> playerIds) async {
    try {
      for (String playerId in playerIds) {
        await _firestore.collection('users').doc(playerId).update({
          'assignedGroups': FieldValue.arrayRemove([groupId]),
        });
      }

      QuerySnapshot trainingSessionsSnapshot = await _firestore
          .collection('training_sessions')
          .where('groupId', isEqualTo: groupId)
          .get();

      for (QueryDocumentSnapshot session in trainingSessionsSnapshot.docs) {
        await _firestore.collection('training_sessions').doc(session.id).delete();
      }

      await _firestore.collection('groups').doc(groupId).delete();

      var groupCount = (await _firestore.collection('groups').get()).docs.length;
      await _firestore.collection('stats').doc('academyStats').update({
        'groupCount': groupCount,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group and training sessions deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error deleting group: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting group: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openScheduleForm(String groupId, String groupName) async {
    String? selectedDay;
    TimeOfDay? selectedStartTime;
    TimeOfDay? selectedEndTime;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Planifier une date $groupName'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    hint: const Text('Choisie un Jour'),
                    value: selectedDay,
                    items: ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche']
                        .map((day) => DropdownMenuItem(
                              value: day,
                              child: Text(day),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDay = value;
                      });
                    },
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        setState(() {
                          selectedStartTime = pickedTime;
                        });
                      }
                    },
                    child: const Text('Select Start Time'),
                  ),
                  if (selectedStartTime != null)
                    Text('Start Time: ${selectedStartTime!.format(context)}'),
                  ElevatedButton(
                    onPressed: () async {
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        setState(() {
                          selectedEndTime = pickedTime;
                        });
                      }
                    },
                    child: const Text('Select End Time'),
                  ),
                  if (selectedEndTime != null)
                    Text('End Time: ${selectedEndTime!.format(context)}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedDay != null &&
                        selectedStartTime != null &&
                        selectedEndTime != null) {
                      await _saveRecurringTrainingSessionsToFirestore(
                          groupId, selectedDay!, selectedStartTime!, selectedEndTime!);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveRecurringTrainingSessionsToFirestore(
    String groupId, String day, TimeOfDay startTime, TimeOfDay endTime) async {
      
    try {
      String groupName = '';
      DocumentSnapshot groupSnapshot = await _firestore.collection('groups').doc(groupId).get();
      if (groupSnapshot.exists) {
        groupName = groupSnapshot.get('name') ?? 'Unnamed Group';
      }

      DateTime now = DateTime.now();
      DateTime firstOccurrence = _getDateFromDay(day, now);

      // Generate sessions for the next 52 weeks
      for (int i = 0; i < 52; i++) {
        DateTime sessionDate = firstOccurrence.add(Duration(days: i * 7));

        DateTime startDateTime = DateTime(
          sessionDate.year,
          sessionDate.month,
          sessionDate.day,
          startTime.hour,
          startTime.minute,
        );
        DateTime endDateTime = DateTime(
          sessionDate.year,
          sessionDate.month,
          sessionDate.day,
          endTime.hour,
          endTime.minute,
        );

        await _firestore.collection('training_sessions').add({
          'groupId': groupId,
          'groupName': groupName,
          'day': day,
          'startTime': startDateTime.toIso8601String(),
          'endTime': endDateTime.toIso8601String(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessions d\'entraînement récurrentes planifiées avec succès !')),

      );
    } catch (e) {
      print('Erreur lors de l\'enregistrement des sessions récurrentes : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la planification des sessions récurrentes : $e')),
      );
    }
  }

 DateTime _getDateFromDay(String day, DateTime referenceDate) {
  Map<String, int> daysOfWeek = {
    'Lundi': 1,
    'Mardi': 2,
    'Mercredi': 3,
    'Jeudi': 4,
    'Vendredi': 5,
    'Samedi': 6,
    'Dimanche': 7, 
  };

  int targetDay = daysOfWeek[day]!; // Get the target day as an integer
  int currentDay = referenceDate.weekday; // Get current weekday

  // Calculate the difference
  int difference = targetDay - currentDay;
  if (difference < 0) difference += 7; // Wrap around to the next week if necessary

  return referenceDate.add(Duration(days: difference));
}


  @override
  Widget build(BuildContext context) {
    return TemplatePageBack(
      title: 'Gestion des Groupes',
      footerIndex: 2,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('groups').snapshots(),
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Quelque chose s\'est mal passé'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final List<DocumentSnapshot> documents = snapshot.data!.docs;

            return ListView.builder(
              itemCount: documents.length,
              itemBuilder: (BuildContext context, int index) {
                final group = Group.fromFirestore(documents[index]);

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text(
                            group.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          subtitle: Text(
                            'Joueurs : ${group.players.length}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.schedule, color: Colors.green, size: 28),
                                onPressed: () {
                                  _openScheduleForm(group.id, group.name);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 28),
                                onPressed: () async {
                                  await _deleteGroup(group.id, group.players);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue, size: 28),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => EditGroupPage(group: group),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const Divider(),
                        StreamBuilder<QuerySnapshot>(
                          stream: _firestore
                              .collection('training_sessions')
                              .where('groupId', isEqualTo: group.id)
                              .snapshots(),
                          builder: (context, sessionSnapshot) {
                            if (!sessionSnapshot.hasData) {
                              return const CircularProgressIndicator();
                            }
                            final sessions = sessionSnapshot.data!.docs;

                            if (sessions.isNotEmpty) {
                              final groupedSessions = <String, Map<String, String>>{};
                              for (var session in sessions) {
                                final data = session.data() as Map<String, dynamic>?;
                                final day = data?.containsKey('day') == true ? data!['day'] : 'Unknown Day';
                                final startTime = data?.containsKey('startTime') == true ? data!['startTime'] : 'Unknown Start Time';
                                final endTime = data?.containsKey('endTime') == true ? data!['endTime'] : 'Unknown End Time';

                                final formattedStartTime = DateTime.tryParse(startTime)?.toLocal();
                                final formattedEndTime = DateTime.tryParse(endTime)?.toLocal();

                                if (!groupedSessions.containsKey(day)) {
                                  groupedSessions[day] = {
                                    'startTime': formattedStartTime != null ? "${formattedStartTime.hour}:${formattedStartTime.minute.toString().padLeft(2, '0')}" : 'Invalid Time',
                                    'endTime': formattedEndTime != null ? "${formattedEndTime.hour}:${formattedEndTime.minute.toString().padLeft(2, '0')}" : 'Invalid Time',
                                  };
                                }
                              }

                              return Column(
                                children: groupedSessions.entries.map((entry) {
                                  final day = entry.key;
                                  final times = entry.value;

                                  final startTime = times['startTime'];
                                  final endTime = times['endTime'];

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        day,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text('De $startTime à $endTime'),
                                    ],
                                  );
                                }).toList(),
                              );
                            } else {
                              return const Text('Aucune session d\'entraînement planifiée.');
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddGroupPage(),
            ),
          );
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
