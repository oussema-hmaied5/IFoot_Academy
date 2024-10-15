import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/models/group.dart';

import '../Menu/footer.dart';
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
    // Update players to remove the group
    for (String playerId in playerIds) {
      await _firestore.collection('users').doc(playerId).update({
        'assignedGroups': FieldValue.arrayRemove([groupId]), // Remove groupId from assignedGroups
      });
    }

    // Delete the group's training sessions from Firestore
    QuerySnapshot trainingSessionsSnapshot = await _firestore
        .collection('training_sessions')
        .where('groupId', isEqualTo: groupId)
        .get();

    for (QueryDocumentSnapshot session in trainingSessionsSnapshot.docs) {
      await _firestore.collection('training_sessions').doc(session.id).delete();
    }

    // Delete the group from Firestore
    await _firestore.collection('groups').doc(groupId).delete();

    // Update the total group count
    var groupCount = (await _firestore.collection('groups').get()).docs.length;
    await _firestore.collection('stats').doc('academyStats').update({
      'groupCount': groupCount,
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Group and training sessions deleted successfully!'),
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
              title: Text('Plan Training for $groupName'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    hint: const Text('Select Day'),
                    value: selectedDay,
                    items: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
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
                    child: Text('Select Start Time'),
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
                    child: Text('Select End Time'),
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
                    if (selectedDay != null && selectedStartTime != null && selectedEndTime != null) {
                      await _saveTrainingSessionToFirestore(groupId, selectedDay!, selectedStartTime!, selectedEndTime!);
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

 Future<void> _saveTrainingSessionToFirestore(
    String groupId, String day, TimeOfDay startTime, TimeOfDay endTime) async {
  try {
    // Determine the current date
    DateTime now = DateTime.now();

    // Calculate the starting date for the selected day of the week
    int selectedDayOfWeek = _dayOfWeekToInt(day);
    DateTime firstTrainingDate = _getNextTrainingDate(now, selectedDayOfWeek);

    // Loop to generate training sessions for the next 9 months (36 weeks)
    for (int i = 0; i < 36; i++) {
      DateTime sessionStartDateTime = DateTime(
        firstTrainingDate.year,
        firstTrainingDate.month,
        firstTrainingDate.day,
        startTime.hour,
        startTime.minute,
      );

      DateTime sessionEndDateTime = DateTime(
        firstTrainingDate.year,
        firstTrainingDate.month,
        firstTrainingDate.day,
        endTime.hour,
        endTime.minute,
      );

      // Fetch the group name from Firestore
      String groupName = '';
      DocumentSnapshot groupSnapshot = await _firestore.collection('groups').doc(groupId).get();
      if (groupSnapshot.exists) {
        groupName = groupSnapshot.get('name') ?? 'Unnamed Group';
      }

      // Save the training session to Firestore
      await _firestore.collection('training_sessions').add({
        'groupId': groupId,
        'groupName': groupName,
        'day': day,
        'startTime': sessionStartDateTime.toIso8601String(),
        'endTime': sessionEndDateTime.toIso8601String(),
      });

      // Calculate the date for the next session (next week)
      firstTrainingDate = firstTrainingDate.add(const Duration(days: 7));
    }

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Training sessions for 9 months scheduled successfully!')),
    );
  } catch (e) {
    print('Error saving training sessions: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error scheduling training sessions: $e')),
    );
  }
}

// Helper function to get the next date for the selected day of the week
int _dayOfWeekToInt(String day) {
  switch (day) {
    case 'Monday':
      return DateTime.monday;
    case 'Tuesday':
      return DateTime.tuesday;
    case 'Wednesday':
      return DateTime.wednesday;
    case 'Thursday':
      return DateTime.thursday;
    case 'Friday':
      return DateTime.friday;
    default:
      return DateTime.monday; // Default to Monday if no valid day is selected
  }
}

// Helper function to get the next training date
DateTime _getNextTrainingDate(DateTime now, int selectedDayOfWeek) {
  // Calculate the next occurrence of the selected day of the week
  int daysToAdd = (selectedDayOfWeek - now.weekday) % 7;
  if (daysToAdd < 0) {
    daysToAdd += 7;
  }
  return now.add(Duration(days: daysToAdd));
}


  Future<void> _openEditTrainingSessionForm(
      String sessionId, String groupName, DateTime currentStartTime, DateTime currentEndTime) async {
    TimeOfDay? selectedStartTime = TimeOfDay.fromDateTime(currentStartTime);
    TimeOfDay? selectedEndTime = TimeOfDay.fromDateTime(currentEndTime);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Training for $groupName'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: selectedStartTime ?? TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        setState(() {
                          selectedStartTime = pickedTime;
                        });
                      }
                    },
                    child: Text('Select Start Time'),
                  ),
                  if (selectedStartTime != null)
                    Text('Start Time: ${selectedStartTime!.format(context)}'),
                  ElevatedButton(
                    onPressed: () async {
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: selectedEndTime ?? TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        setState(() {
                          selectedEndTime = pickedTime;
                        });
                      }
                    },
                    child: Text('Select End Time'),
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
                    if (selectedStartTime != null && selectedEndTime != null) {
                      await _updateTrainingSessionInFirestore(sessionId, selectedStartTime!, selectedEndTime!);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateTrainingSessionInFirestore(
      String sessionId, TimeOfDay startTime, TimeOfDay endTime) async {
    DateTime now = DateTime.now();
    DateTime newStartDateTime =
        DateTime(now.year, now.month, now.day, startTime.hour, startTime.minute);
    DateTime newEndDateTime =
        DateTime(now.year, now.month, now.day, endTime.hour, endTime.minute);

    try {
      await _firestore.collection('training_sessions').doc(sessionId).update({
        'startTime': newStartDateTime.toIso8601String(),
        'endTime': newEndDateTime.toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Training session updated successfully!')),
      );
    } catch (e) {
      print('Error updating session: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating session: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Manage Groups'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const AddGroupPage(),
              ));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('groups').snapshots(),
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Something went wrong'));
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
                            'Players: ${group.players.length}',
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
                        FutureBuilder<QuerySnapshot>(
                          future: _firestore.collection('training_sessions').where('groupId', isEqualTo: group.id).get(),
                          builder: (context, sessionSnapshot) {
                            if (!sessionSnapshot.hasData) return CircularProgressIndicator();
                            final sessions = sessionSnapshot.data!.docs;

                            return ListView.builder(
                              shrinkWrap: true,
                              itemCount: sessions.length,
                              itemBuilder: (context, sessionIndex) {
                                final session = sessions[sessionIndex];
                                final startTime = DateTime.parse(session['startTime']);
                                final endTime = DateTime.parse(session['endTime']);

                                return ListTile(
                                  title: Text(
                                      '${startTime.hour}:${startTime.minute} - ${endTime.hour}:${endTime.minute}'),
                                  subtitle: Text(session['groupName']),
                                  trailing: IconButton(
                                    icon: Icon(Icons.edit),
                                    onPressed: () {
                                      _openEditTrainingSessionForm(session.id, session['groupName'], startTime, endTime);
                                    },
                                  ),
                                );
                              },
                            );
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
      bottomNavigationBar: Footer(currentIndex: 2),
    );
  }
}
