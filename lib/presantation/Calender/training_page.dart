import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../Admin/Menu/footer.dart';

class TrainingCalendarPage extends StatefulWidget {
  const TrainingCalendarPage({Key? key}) : super(key: key);

  @override
  _TrainingCalendarPageState createState() => _TrainingCalendarPageState();
}

class _TrainingCalendarPageState extends State<TrainingCalendarPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late List<TrainingSession> _trainingSessions;
  CalendarView _calendarView = CalendarView.week; // Default view is day

  @override
  void initState() {
    super.initState();
    _trainingSessions = [];
    _fetchTrainingSessions();
  }

  // Fetch training sessions from Firestore
Future<void> _fetchTrainingSessions() async {
  try {
    final snapshot = await _firestore.collection('training_sessions').get();
    final List<TrainingSession> sessions = snapshot.docs.map((doc) {
      final data = doc.data();

      // Log the fetched data to see what Firestore is returning
      print('Fetched Data: $data');

      // Fetch data and ensure default values are used if null
      String groupName = data['groupName'] ?? 'Unnamed Group'; // Default to 'Unnamed Group' if null
      String startTimeStr = data['startTime'] ?? ''; // Default empty if null
      String endTimeStr = data['endTime'] ?? ''; // Default empty if null

      // Ensure the date parsing happens safely
      DateTime startTime;
      DateTime endTime;

      // Try parsing the date strings and provide fallback dates if parsing fails
      try {
        startTime = DateTime.parse(startTimeStr);
      } catch (e) {
        startTime = DateTime.now(); // Fallback to current time if invalid date
      }

      try {
        endTime = DateTime.parse(endTimeStr);
      } catch (e) {
        endTime = DateTime.now().add(Duration(hours: 1)); // Fallback to 1 hour after current time
      }

      // Format the time to be more user-friendly (optional)
      String formattedStartTime = '${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}';
      String formattedEndTime = '${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}';

      // Combine group name and time in event name
      String eventName = '$groupName ($formattedStartTime - $formattedEndTime)';

      return TrainingSession(eventName, startTime, endTime);
    }).toList();

    // Ensure the UI updates with the fetched sessions
    setState(() {
      _trainingSessions = sessions;
    });

    print("Training sessions fetched successfully.");
  } catch (e) {
    print('Error fetching training sessions: $e');
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Schedule'),
        backgroundColor: Colors.blueGrey, // Updated AppBar color
        actions: [
          DropdownButton<CalendarView>(
            value: _calendarView,
            dropdownColor: Colors.white,
            icon: const Icon(Icons.view_agenda, color: Colors.white),
            underline: Container(),
            onChanged: (CalendarView? newView) {
              setState(() {
                _calendarView = newView ?? CalendarView.day; // Ensure view changes
                print('Calendar view changed to: $_calendarView');
              });
            },
            items: [
              DropdownMenuItem(
                value: CalendarView.day,
                child: Text('Day View'),
              ),
              DropdownMenuItem(
                value: CalendarView.week,
                child: Text('Week View'),
              ),
              DropdownMenuItem(
                value: CalendarView.month,
                child: Text('Month View'),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0), // Adds padding around the calendar
        child: _buildCalendar(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTrainingSession,
        child: const Icon(Icons.add),
        backgroundColor: Colors.blueGrey, // Updated floating button color
      ),
      bottomNavigationBar: Footer(currentIndex: 4),
    );
  }

  // Build the SfCalendar as a separate method
  Widget _buildCalendar() {
    return SfCalendar(
      key: UniqueKey(), // Add this to force rebuild when view changes
      view: _calendarView, // Calendar view dynamically changes based on user selection
      dataSource: TrainingDataSource(_trainingSessions),
      timeSlotViewSettings: const TimeSlotViewSettings(
        startHour: 8, // Show from 8 AM
        endHour: 23, // Show until 11 PM
        timeIntervalHeight: 50,
        timeTextStyle: TextStyle(
          color: Colors.black54,
          fontSize: 14,
        ),
        timeRulerSize: 60, // Adjust time ruler width
      ),
      todayHighlightColor: Colors.orangeAccent, // Updated highlight color
      appointmentTextStyle: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      headerStyle: const CalendarHeaderStyle(
        textAlign: TextAlign.center,
        textStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey, // Header color
        ),
      ),
      viewHeaderStyle: const ViewHeaderStyle(
        backgroundColor: Colors.blueGrey,
        dayTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        dateTextStyle: TextStyle(
          color: Colors.white,
        ),
      ),
      monthViewSettings: const MonthViewSettings(
        showAgenda: true, // Show agenda view in month mode
        agendaStyle: AgendaStyle(
          backgroundColor: Colors.white,
          appointmentTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 14,
          ),
          dateTextStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey, // Date text color for the month view
          ),
        ),
      ),
    );
  }

  // Method to add a training session
  Future<void> _addTrainingSession() async {
    String? selectedGroup;
    DateTime? selectedStartTime;
    DateTime? selectedEndTime;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Training Session'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FutureBuilder<QuerySnapshot>(
                    future: _firestore.collection('groups').get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator();
                      final groups = snapshot.data!.docs.map((doc) {
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text(doc['name']),
                        );
                      }).toList();

                      return DropdownButton<String>(
                        hint: const Text('Select Group'),
                        items: groups,
                        value: selectedGroup,
                        onChanged: (value) {
                          setState(() {
                            selectedGroup = value;
                          });
                        },
                      );
                    },
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      DateTime? picked = await _selectDateTime(context);
                      if (picked != null) {
                        setState(() {
                          selectedStartTime = picked;
                        });
                      }
                    },
                    child: const Text('Select Start Time'),
                  ),
                  if (selectedStartTime != null)
                    Text('Start Time: ${selectedStartTime.toString()}'),
                  ElevatedButton(
                    onPressed: () async {
                      DateTime? picked = await _selectDateTime(context);
                      if (picked != null) {
                        setState(() {
                          selectedEndTime = picked;
                        });
                      }
                    },
                    child: const Text('Select End Time'),
                  ),
                  if (selectedEndTime != null)
                    Text('End Time: ${selectedEndTime.toString()}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedGroup != null && selectedStartTime != null && selectedEndTime != null) {
                      await _addTrainingToFirestore(selectedGroup!, selectedStartTime!, selectedEndTime!);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Helper method to select date and time
  Future<DateTime?> _selectDateTime(BuildContext context) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2021),
      lastDate: DateTime(2030),
    );

    if (selectedDate == null) return null;

    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selectedTime == null) return selectedDate;

    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
  }

// Helper method to add the training session to Firestore
Future<void> _addTrainingToFirestore(String groupId, DateTime startTime, DateTime endTime) async {
  try {
    // Add the training session to Firestore
    await _firestore.collection('training_sessions').add({
      'groupId': groupId,
      'groupName': await _getGroupName(groupId),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
    });

    // After adding the training session, update the statistics
    await _updateTrainingStats();

    // Fetch updated training sessions to refresh the UI
    _fetchTrainingSessions();
  } catch (e) {
    print('Error adding training session: $e');
  }
}
// Helper method to update the training stats in Firestore
Future<void> _updateTrainingStats() async {
  try {
    // Reference to the stats document (you can adjust the path as needed)
    final statsDocRef = _firestore.collection('stats').doc('academyStats');

    // Get the current stats document
    final statsSnapshot = await statsDocRef.get();

    if (statsSnapshot.exists) {
      // Increment the trainingsCount field by 1 if the document exists
      await statsDocRef.update({
        'trainingsCount': FieldValue.increment(1),
      });
    } else {
      // If the stats document doesn't exist, create it with trainingsCount set to 1
      await statsDocRef.set({
        'trainingsCount': 1,
      });
    }

    print('Training statistics updated successfully.');
  } catch (e) {
    print('Error updating training stats: $e');
  }
}

  // Helper method to fetch the group name from Firestore
  Future<String> _getGroupName(String groupId) async {
    final groupSnapshot = await _firestore.collection('groups').doc(groupId).get();
    return groupSnapshot.data()!['name'] as String;
  }
}

// TrainingSession class to hold event data
class TrainingSession {
  TrainingSession(this.eventName, this.from, this.to);

  final String eventName;
  final DateTime from;
  final DateTime to;
}

// TrainingDataSource class for handling calendar events
class TrainingDataSource extends CalendarDataSource {
  TrainingDataSource(List<TrainingSession> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return appointments![index].from;
  }

  @override
  DateTime getEndTime(int index) {
    return appointments![index].to;
  }

  @override
  String getSubject(int index) {
    return appointments![index].eventName; // Ensure this is correct
  }
}

