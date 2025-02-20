import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/Pages/Back-office/Backend_template.dart';
import 'package:ifoot_academy/Pages/Back-office/Players/Events/friendly_match_form.dart';
import 'package:ifoot_academy/Pages/Back-office/Players/Events/tournament_form.dart';
import 'package:intl/intl.dart';

import 'Championship/championship_details.dart';
import 'Championship/journee_details.dart';

class EventManager extends StatefulWidget {
  const EventManager({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _EventManagerState createState() => _EventManagerState();
}

class _EventManagerState extends State<EventManager>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToAddEvent(BuildContext context) {
    int tabIndex = _tabController.index;
    Widget page = switch (tabIndex) {
      0 => const ChampionshipDetails(championship: null, groups: []),
      1 => const TournamentForm(groups: []),
      2 => const FriendlyMatchForm(groups: []),
      _ => const ChampionshipDetails(championship: null, groups: []),
    };

    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: TemplatePageBack(
        title: 'Gestion des Événements',
        footerIndex: 3,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAddEvent(context),
          ),
        ],
        body: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.emoji_events), text: 'Championnats'),
                Tab(icon: Icon(Icons.emoji_events_outlined), text: 'Tournois'),
                Tab(icon: Icon(Icons.sports_soccer), text: 'Matchs Amicaux'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  ChampionshipsTab(),
                  TournamentsTab(),
                  FriendlyMatchesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChampionshipsTab extends StatelessWidget {
  const ChampionshipsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      _buildEventList('championships', context);
}

class TournamentsTab extends StatelessWidget {
  const TournamentsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => _buildEventList('tournaments', context);
}

class FriendlyMatchesTab extends StatelessWidget {
  const FriendlyMatchesTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      _buildEventList('friendlyMatches', context);
}

Widget _buildEventList(String collection, BuildContext context) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection(collection).snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      return ListView.builder(
        itemCount: snapshot.data!.docs.length,
        itemBuilder: (context, index) =>
            eventTile(snapshot.data!.docs[index], collection, context),
      );
    },
  );
}


Widget eventTile(DocumentSnapshot event, String collection, BuildContext context) {
  final eventData = event.data() as Map<String, dynamic>;
  final List<dynamic> matchDays = eventData['matchDays'] ?? [];

  // 🔹 Reverse the list to get the latest Journées first
  List<dynamic> sortedMatchDays = List.from(matchDays.reversed);

  // 🔹 Get only the latest 3 Journées
  List<dynamic> latestMatchDays = sortedMatchDays.take(3).toList();

  return Card(
    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getEventIcon(collection), color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getEventTitle(collection),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildEventDetailRow(Icons.location_on, "Lieu: ${eventData['locationType'] ?? 'N/A'}", Colors.red),
          _buildEventDetailRow(Icons.groups, "Groupes: ${(eventData['selectedGroups'] as List<dynamic>?)?.join(", ") ?? 'Aucun groupe'}", Colors.green),

          if (latestMatchDays.isNotEmpty) ...[
            ...latestMatchDays.asMap().entries.map((entry) {
              int actualIndex = matchDays.length - (entry.key + 1); // Fix index calculation
              Map<String, dynamic> day = entry.value;

              return ListTile(
                title: Text("🗓️ Journée ${actualIndex + 1}"), // Display the correct number
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEventDetailRow(Icons.calendar_today, "Date: ${_formatDate(day['date'])}", Colors.orange),
                    _buildEventDetailRow(Icons.person, "Coach(s): ${(day['coaches'] as List<dynamic>?)?.join(", ") ?? 'Aucun'}", Colors.deepPurple),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.blue),
                onTap: () => _navigateToJourneeDetails(context, event.id, actualIndex, day),
              );
            }),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _navigateToEditEvent(context, event, collection),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _confirmDeleteEvent(event.id, collection, context),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}



Widget _buildEventDetailRow(IconData icon, String text, Color iconColor) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

void _navigateToJourneeDetails(BuildContext context, String championshipId,
    int index, Map<String, dynamic> day) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => JourneeDetails(
        championshipId: championshipId,
        journeeIndex: index,
        journeeData: day,
      ),
    ),
  );
}

DateTime _parseDate(dynamic dateField) {
  if (dateField is Timestamp) return dateField.toDate();
  if (dateField is String && dateField.isNotEmpty) return DateTime.parse(dateField);
  return DateTime(2000, 1, 1);
}

String _getEventTitle(String collection) =>
    {
      'championships': 'Championnat',
      'tournaments': 'Tournoi',
      'friendlyMatches': 'Match Amical',
    }[collection] ?? 'Événement';

IconData _getEventIcon(String collection) =>
    {
      'championships': Icons.emoji_events,
      'tournaments': Icons.emoji_events_outlined,
      'friendlyMatches': Icons.sports_soccer,
    }[collection] ?? Icons.event;

String _formatDate(dynamic dateField) {
  if (dateField is Timestamp) return DateFormat("dd/MM/yyyy").format(dateField.toDate());
  if (dateField is String) return dateField;
  return "Inconnue";
}


void _confirmDeleteEvent(String eventId, String collection, BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: const Text("Voulez-vous vraiment supprimer cet événement ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Annuler", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection(collection).doc(eventId).delete();
              Navigator.of(context).pop();
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  );
}

void _navigateToEditEvent(BuildContext context, DocumentSnapshot eventDoc, String collection) {
  Widget page = switch (collection) {
    'championships' => ChampionshipDetails(championship: eventDoc, groups: []),
    'tournaments' => TournamentForm(
        tournament: eventDoc,
        groups: List<String>.from(eventDoc['selectedGroups'] ?? [])),
    _ => FriendlyMatchForm(
        groups: List<String>.from(eventDoc['selectedGroups'] ?? [])),
  };

  Navigator.push(context, MaterialPageRoute(builder: (context) => page));
}
