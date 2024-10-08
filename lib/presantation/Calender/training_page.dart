import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/models/group.dart';
import 'package:table_calendar/table_calendar.dart';

class TrainingCalendarPage extends StatefulWidget {
  const TrainingCalendarPage({Key? key}) : super(key: key);

  @override
  _TrainingCalendarPageState createState() => _TrainingCalendarPageState();
}

class _TrainingCalendarPageState extends State<TrainingCalendarPage> {
  late final ValueNotifier<List<Group>> _selectedGroups;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<DateTime, List<Group>> _events = {};

  @override
  void initState() {
    super.initState();

    _selectedDay = _focusedDay;
    _selectedGroups = ValueNotifier([]);
    _loadEventsForMonth(_focusedDay);
  }

  @override
  void dispose() {
    _selectedGroups.dispose();
    super.dispose();
  }

  Future<void> _loadEventsForMonth(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);

    final groups = await _firestore.collection('groups').get();
    final events = <DateTime, List<Group>>{};

    for (final doc in groups.docs) {
      final group = Group.fromJson(doc.data() as Map<String, dynamic>);
      group.trainingSchedule.forEach((date, time) {
        final eventDate = DateTime.parse(date);
        if (eventDate.isAfter(start.subtract(const Duration(days: 1))) && eventDate.isBefore(end.add(const Duration(days: 1)))) {
          if (events[eventDate] == null) {
            events[eventDate] = [];
          }
          events[eventDate]!.add(group);
        }
      });
    }

    setState(() {
      _events = events;
      _selectedGroups.value = _events[_selectedDay!] ?? [];
    });
  }

  List<Group> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });

      _selectedGroups.value = _getEventsForDay(selectedDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Calendar'),
      ),
      body: Column(
        children: [
          TableCalendar<Group>(
            firstDay: DateTime.utc(2021, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
            ),
            onDaySelected: _onDaySelected,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              _loadEventsForMonth(focusedDay);
            },
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ValueListenableBuilder<List<Group>>(
              valueListenable: _selectedGroups,
              builder: (context, value, _) {
                return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: ListTile(
                        title: Text('${value[index].name} - ${value[index].trainingSchedule[_selectedDay!.toIso8601String().split('T').first]}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
