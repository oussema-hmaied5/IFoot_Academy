import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../Style/Frontend_template.dart';
import 'user_repository.dart';

class UserHomePage extends StatefulWidget {
  final String userId;
  const UserHomePage({Key? key, required this.userId}) : super(key: key);

  @override
  _UserHomePageState createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final UserRepository _userRepository = UserRepository();
  Map<String, dynamic>? nextTrainingSession;
  List<Map<String, dynamic>> eventsAndNews = [];
  List<Map<String, dynamic>> teamPlayers = [];
  Map<String, dynamic>? userData;
  bool isLoading = true;
  

  final List<String> userDetails = [];
  int currentDetailIndex = 0;
  bool isAnimating = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final userDoc = await _userRepository.getUserData(widget.userId);
      final session = await _userRepository.getNextTrainingSession(widget.userId);
      final events = await _userRepository.getEventsAndNews();
      final teamData = await _userRepository.getTeamAndPlayers(widget.userId);

      setState(() {
        userData = userDoc;
        nextTrainingSession = session;
        eventsAndNews = events;
        teamPlayers = teamData['players'];

        userDetails.clear();
        userDetails.add('Nom : ${userData!['childName'] ?? 'Inconnu'}');

        _startAnimation();
      });
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _startAnimation() {
    if (isAnimating || userDetails.isEmpty) return;

    isAnimating = true;

    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (currentDetailIndex < userDetails.length) {
        setState(() {
          currentDetailIndex++;
        });
      } else {
        timer.cancel();
        setState(() {
          isAnimating = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FrontendTemplate(
      title: 'Accueil ',
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(context),
      footerIndex: 0, // Highlight the 'Home' section in the footer
    );
  }

  Widget _buildBody(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        _buildUserDetailsSection(),
        const SizedBox(height: 20),
        _buildDateAndWeatherSection(),
        const SizedBox(height: 20),
        _buildNextTrainingCard(),
        const SizedBox(height: 20),
        _buildTeamSection(),
        const SizedBox(height: 20),
        _buildEventsSection(),
      ],
    );
  }

  Widget _buildUserDetailsSection() {
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: currentDetailIndex < userDetails.length
            ? Card(
                key: ValueKey<int>(currentDetailIndex),
                elevation: 5,
                color: Colors.teal.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    userDetails[currentDetailIndex],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ),
              )
            : const SizedBox(),
      ),
    );
  }

  Widget _buildDateAndWeatherSection() {
    final today = DateTime.now();
    return Card(
      elevation: 5,
      color: Colors.lightBlue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aujourd\'hui : ${today.day}/${today.month}/${today.year}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Météo : Ensoleillé',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            const Icon(
              Icons.wb_sunny,
              color: Colors.orange,
              size: 40,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextTrainingCard() {
    if (nextTrainingSession == null || nextTrainingSession!.isEmpty) {
      return Card(
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: const Text(
            'Aucun entraînement à venir.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    final session = nextTrainingSession!;
    DateTime? startTime;
    DateTime? endTime;

    try {
      startTime = session['startTime'] is Timestamp
          ? (session['startTime'] as Timestamp).toDate()
          : DateTime.tryParse(session['startTime'] as String);
      endTime = session['endTime'] is Timestamp
          ? (session['endTime'] as Timestamp).toDate()
          : DateTime.tryParse(session['endTime'] as String);

      if (startTime == null || endTime == null) {
        throw Exception('Invalid date format in session data.');
      }
    } catch (e) {
      print('Error parsing startTime or endTime: $e');
      return Card(
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: const Text(
            'Erreur dans les données de la session.',
            style: TextStyle(fontSize: 16, color: Colors.red),
          ),
        ),
      );
    }

    return Card(
      elevation: 5,
      child: ListTile(
        leading: const Icon(Icons.schedule, color: Colors.teal),
        title: Text('Prochaine séance : ${session['groupName']}'),
        subtitle: Text(
          'De ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')} '
          'à ${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }

  Widget _buildTeamSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mon Équipe',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (teamPlayers.isEmpty)
          const Text('Aucun joueur trouvé.')
        else
          ...teamPlayers.map((player) {
            return Card(
              child: ListTile(
                leading: const Icon(Icons.person, color: Colors.teal),
                title: Text(player['name'] ?? 'Nom indisponible'),
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildEventsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Événements et Actualités',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (eventsAndNews.isEmpty)
          const Text('Aucun événement pour le moment.')
        else
          ...eventsAndNews.map((event) {
            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 5),
              child: ListTile(
                leading: const Icon(Icons.event, color: Colors.teal),
                title: Text(event['title'] ?? 'Événement sans titre'),
                subtitle: Text(
                  'Date : ${(event['date'] as Timestamp).toDate()}'),
              ),
            );
          }).toList(),
      ],
    );
  }
}
