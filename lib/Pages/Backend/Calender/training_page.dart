import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../Menu/footer.dart';

class TrainingCalendarPage extends StatefulWidget {
  const TrainingCalendarPage({Key? key}) : super(key: key);

  @override
  _TrainingCalendarPageState createState() => _TrainingCalendarPageState();
}

class _TrainingCalendarPageState extends State<TrainingCalendarPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late List<TrainingSession> _trainingSessions;
  CalendarView _calendarView = CalendarView.week; // Default view is Week View

  @override
  void initState() {
    super.initState();
    _trainingSessions = [];
    _fetchTrainingSessions();
  }

  Future<void> _fetchTrainingSessions() async {
    try {
      final snapshot = await _firestore.collection('training_sessions').get();
      final List<TrainingSession> sessions = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        try {
          final DateTime startTime = DateTime.parse(data['startTime']);
          final DateTime endTime = DateTime.parse(data['endTime']);
          final String groupName = data['groupName'] ?? 'Unnamed Group';

          return TrainingSession(groupName, startTime, endTime);
        } catch (e) {
          print('Invalid session data: ${data['startTime']}, ${data['endTime']} - Error: $e');
          return null;
        }
      }).where((session) => session != null).cast<TrainingSession>().toList();

      setState(() {
        _trainingSessions = sessions;
        print('Training sessions fetched: ${_trainingSessions.length}');
      });
    } catch (e) {
      print('Error fetching training sessions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Schedule'),
        backgroundColor: Colors.blueGrey,
        actions: [
          DropdownButton<CalendarView>(
            value: _calendarView,
            dropdownColor: Colors.white,
            icon: const Icon(Icons.view_agenda, color: Colors.white),
            underline: Container(),
            onChanged: (CalendarView? newView) {
              if (newView != null && newView != _calendarView) {
                setState(() {
                  _calendarView = newView;
                });
              }
            },
            items: const [
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
      body: Column(
        children: [
          Expanded(
            child: SfCalendar(
              key: ValueKey(_calendarView), // Ensures the widget rebuilds properly
              view: _calendarView,
              dataSource: TrainingDataSource(_trainingSessions),
              initialDisplayDate: DateTime.now(),
              todayHighlightColor: Colors.orangeAccent,
              timeSlotViewSettings: const TimeSlotViewSettings(
                startHour: 8,
                endHour: 23,
                timeIntervalHeight: 50,
              ),
              monthViewSettings: const MonthViewSettings(
                appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
              ),
              appointmentTextStyle: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              onViewChanged: (ViewChangedDetails details) {
              },
            ),
          ),
          Footer(currentIndex: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTrainingSession,
        child: const Icon(Icons.add),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }

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

  Future<void> _addTrainingToFirestore(String groupId, DateTime startTime, DateTime endTime) async {
    try {
      await _firestore.collection('training_sessions').add({
        'groupId': groupId,
        'groupName': await _getGroupName(groupId),
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
      });

      _fetchTrainingSessions();
    } catch (e) {
      print('Error adding training session: $e');
    }
  }

  Future<String> _getGroupName(String groupId) async {
    final groupSnapshot = await _firestore.collection('groups').doc(groupId).get();
    return groupSnapshot.data()!['name'] as String;
  }
}

class TrainingSession {
  TrainingSession(this.eventName, this.from, this.to);

  final String eventName;
  final DateTime from;
  final DateTime to;
}

class TrainingDataSource extends CalendarDataSource {
  TrainingDataSource(List<TrainingSession> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) => appointments![index].from;

  @override
  DateTime getEndTime(int index) => appointments![index].to;

  @override
  String getSubject(int index) => appointments![index].eventName;
}
