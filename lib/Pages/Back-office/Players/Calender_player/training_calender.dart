// ignore_for_file: depend_on_referenced_packages, empty_catches

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ifoot_academy/Pages/Back-office/backend_template.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';

class TrainingCalendarPage extends StatefulWidget {
  const TrainingCalendarPage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _TrainingCalendarState createState() => _TrainingCalendarState();
}

class _TrainingCalendarState extends State<TrainingCalendarPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  DateTime _selectedDay = DateTime.now();

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('fr_FR', null);
  }

  @override
  void initState() {
    super.initState();
    _events = {};
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    final events = <DateTime, List<Map<String, dynamic>>>{};
    
    await _fetchTrainings(events);
    await _fetchMatches(events);
    await _fetchTournaments(events);
    await _fetchChampionships(events);
    await _fetchFriendlyMatches(events);
    
    setState(() {
      _events = events;
    });
  }

  Future<void> _fetchTournaments(Map<DateTime, List<Map<String, dynamic>>> events) async {
    final snapshot = await _firestore.collection('tournaments').get();
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data.containsKey('dates') && data['dates'] is List && data['dates'].isNotEmpty) {
        final localDate = (data['dates'][0] as Timestamp).toDate();
        events.putIfAbsent(localDate, () => []);
        events[localDate]!.add({
          'id': doc.id,
          'type': 'Tournoi',
          'name': data['name'],
          'date': data['dates'] ?? 'Heure non définie',
          'location': data['locationType'],
        });
      }
    }
  }

  Future<void> _fetchMatches(Map<DateTime, List<Map<String, dynamic>>> events) async {
    final snapshot = await _firestore.collection('matches').get();
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data.containsKey('date')) {
        final localDate = DateTime.parse(data['date']).toLocal();
        events.putIfAbsent(localDate, () => []);
        events[localDate]!.add({
          'id': doc.id,
          'type': 'Match Amical',
          'team1': data['team1'],
          'team2': data['team2'],
          'time': data['time'],
        });
      }
    }
  }

  Future<void> _fetchChampionships(Map<DateTime, List<Map<String, dynamic>>> events) async {
    final snapshot = await _firestore.collection('championships').get();
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data.containsKey('matchDays') && data['matchDays'] is List) {
        for (var matchDay in data['matchDays']) {
          if (matchDay is Map<String, dynamic> && matchDay.containsKey('date')) {
            try {
              final localDate = DateTime.parse(matchDay['date']);
              events.putIfAbsent(localDate, () => []);
              events[localDate]!.add({
                'id': doc.id,
                'type': 'Championnat',
                'name': data['name'] ?? 'Match Inconnu',
                'time': matchDay['time'] ?? 'Heure non définie',
                'transportMode': matchDay['transportMode'] ?? 'Non précisé',
                'location': data['locationType'] ?? 'Lieu inconnu',
              });
            } catch (e) {
            }
          }
        }
      }
    }
  }

  Future<void> _fetchTrainings(Map<DateTime, List<Map<String, dynamic>>> events) async {
    final snapshot = await _firestore.collection('trainings').get();
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data.containsKey('date')) {
        final localDate = DateTime.parse(data['date']).toLocal();
        events.putIfAbsent(localDate, () => []);
        events[localDate]!.add({
          'id': doc.id,
          'type': 'Entraînement',
          'groupName': data['groupName'],
          'startTime': data['startTime'],
          'endTime': data['endTime'],
          'coaches': data['coaches'] ?? ['Aucun coach'],
        });
      }
    }
  }

  Future<void> _fetchFriendlyMatches(Map<DateTime, List<Map<String, dynamic>>> events) async {
    final snapshot = await _firestore.collection('friendlyMatches').get();
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data.containsKey('date')) {
        final localDate = DateTime.parse(data['date']).toLocal();
        events.putIfAbsent(localDate, () => []);
        events[localDate]!.add({
          'id': doc.id,
          'type': 'Match Amical',
          'team1': data['team1'],
          'team2': data['team2'],
          'time': data['time'],
        });
      }
    }
  }

  Icon _getEventIcon(String type) {
    switch (type) {
      case 'Entraînement':
        return const Icon(FontAwesomeIcons.futbol, color: Colors.orange);
      case 'Match Amical':
        return const Icon(FontAwesomeIcons.futbol, color: Colors.blue);
      case 'Tournoi':
        return const Icon(FontAwesomeIcons.medal, color: Color.fromARGB(255, 194, 15, 131));
      case 'Championnat':
        return const Icon(FontAwesomeIcons.trophy, color: Colors.red);
      default:
        return const Icon(Icons.event, color: Colors.blueAccent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeLocale(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        } else {
          return _buildPageContent();
        }
      },
    );
  }

  Widget _buildPageContent() {
    return TemplatePageBack(
      title: 'Calendrier des Événements',
      footerIndex: 0,
      body: Column(
        children: [
          TableCalendar(
            calendarStyle:const CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.orangeAccent,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1,
              markerDecoration: BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.blueAccent),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.blueAccent),
            ),
            locale: 'fr_FR',
            firstDay: DateTime(DateTime.now().year, 1, 1),
            lastDay: DateTime(DateTime.now().year, 12, 31),
            focusedDay: _selectedDay,
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {CalendarFormat.month: 'Mois'}, 
            eventLoader: (day) => _events[DateTime(day.year, day.month, day.day)] ?? [],
            onDaySelected: (selectedDay, focusedDay) {
              setState(() => _selectedDay = selectedDay);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Jour sélectionné: ${selectedDay.day}/${selectedDay.month}/${selectedDay.year}'),
                  duration: const Duration(seconds: 2),
                ),
              );
              setState(() => _selectedDay = selectedDay);
            },
          ),
          Expanded(child: _buildEventList()),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Date sélectionnée : ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
          ),
        ),
        Expanded(child: _buildEventListContent()),
      ],
    );
  }

  Widget _buildEventListContent() {
    final events = _events[DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day)] ?? [];
    
    if (events.isEmpty) {
      return const Center(
        child: Text(
          'Aucun événement prévu.',
          style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      separatorBuilder: (context, index) => Divider(color: Colors.grey.shade400),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              child: _getEventIcon(event['type']),
            ),
            title: Text('${event['type']}: ${event['groupName'] ?? event['match'] ?? event['name'] ?? ''}'),
            subtitle: Text(event['time'] ?? event['startTime'] ?? event['endTime'] ?? event['location'] ?? ''),
           
          ),
        );
      },
    );
  }
}
