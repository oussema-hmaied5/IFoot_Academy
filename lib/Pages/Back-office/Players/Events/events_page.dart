import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/Pages/Back-office/Backend_template.dart';
import 'package:ifoot_academy/Pages/Back-office/Players/Events/championship_form.dart';
import 'package:ifoot_academy/Pages/Back-office/Players/Events/friendly_match_form.dart';
import 'package:ifoot_academy/Pages/Back-office/Players/Events/tournament_form.dart';
import 'package:intl/intl.dart';

class EventManager extends StatefulWidget {
  const EventManager({super.key});

  @override
  _EventManagerState createState() => _EventManagerState();
}

class _EventManagerState extends State<EventManager> with SingleTickerProviderStateMixin {
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
      0 => const ChampionshipForm(groups: []),
      1 => const TournamentForm(groups: []),
      2 => const FriendlyMatchForm(groups: []),
      _ => const ChampionshipForm(groups: []),
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
  Widget build(BuildContext context) => _buildEventList('championships', context);
}

class TournamentsTab extends StatelessWidget {
  const TournamentsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => _buildEventList('tournaments', context);
}

class FriendlyMatchesTab extends StatelessWidget {
  const FriendlyMatchesTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => _buildEventList('friendlyMatches', context);
}

Widget _buildEventList(String collection, BuildContext context) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection(collection).snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      return ListView.builder(
        itemCount: snapshot.data!.docs.length,
        itemBuilder: (context, index) => eventTile(snapshot.data!.docs[index], collection, context),
      );
    },
  );
}
Widget eventTile(DocumentSnapshot event, String collection, BuildContext context) {
  final eventData = event.data() as Map<String, dynamic>;

  // 🔹 Vérifier et extraire la dernière journée pour les championnats
  final List<dynamic> matchDays = eventData['matchDays'] ?? [];
  final Map<String, dynamic>? lastMatchDay = matchDays.isNotEmpty
      ? matchDays.last as Map<String, dynamic>
      : null;

  return Card(
    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Titre avec l'icône
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

          // 🔹 Lieu du tournoi ou match amical
          _buildEventDetailRow(
              Icons.location_on, "Lieu: ${eventData['locationType'] ?? 'N/A'}", Colors.red),

          // 🔹 Affichage de la date pour les Tournois et Matchs Amicaux
          if (collection == 'tournaments' || collection == 'friendlyMatches') ...[
            _buildEventDetailRow(
              Icons.calendar_today,
              "Date: ${_formatDate(eventData['dates'])}",
              Colors.purple,
            ),
          ],

          // 🔹 Groupes participants
          _buildEventDetailRow(
              Icons.groups,
              "Groupes: ${(eventData['selectedGroups'] as List<dynamic>?)?.join(", ") ?? 'Aucun groupe'}",
              Colors.green),

          // 🔹 Affichage des détails de la dernière journée pour les championnats
          if (collection == 'championships' && lastMatchDay != null) ...[
            const SizedBox(height: 8),
            const Divider(),
            const Text(
              "📅 Dernière Journée",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange),
            ),

            _buildEventDetailRow(
                Icons.calendar_today,
                "Date: ${_formatDate(lastMatchDay['date'])}",
                Colors.orange),

            _buildEventDetailRow(
                Icons.access_time,
                "Heure: ${lastMatchDay['time'] ?? 'Non spécifiée'}",
                Colors.blue),

            _buildEventDetailRow(
                Icons.directions_bus,
                "Transport: ${lastMatchDay['transportMode'] ?? 'Non spécifié'}",
                Colors.teal),

            _buildEventDetailRow(
                Icons.person,
                "Coach(s): ${(lastMatchDay['coaches'] as List<dynamic>?)?.join(", ") ?? 'Aucun'}",
                Colors.deepPurple),
          ],

          const SizedBox(height: 8),

          // 🔹 Boutons d'action (Modifier / Supprimer)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _navigateToEditEvent(context, eventData, collection)),
              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteEvent(event.id, collection, context)),
            ],
          ),
        ],
      ),
    ),
  );
}


String _getEventTitle(String collection) => {
  'championships': 'Championnat',
  'tournaments': 'Tournoi',
  'friendlyMatches': 'Match Amical',
}[collection] ?? 'Événement';

IconData _getEventIcon(String collection) => {
  'championships': Icons.emoji_events,
  'tournaments': Icons.emoji_events_outlined,
  'friendlyMatches': Icons.sports_soccer,
}[collection] ?? Icons.event;

String _formatDate(dynamic dateField) {
  if (dateField is Timestamp) return DateFormat("dd/MM/yyyy").format(dateField.toDate());
  if (dateField is String) return dateField;
  return "Inconnue";
}

Widget _buildEventDetailRow(IconData icon, String text, Color iconColor) {
  return Row(
    children: [
      Icon(icon, color: iconColor, size: 18),
      const SizedBox(width: 4),
      Expanded(child: Text(text, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14))),
    ],
  );
}

void _deleteEvent(String eventId, String collection, BuildContext context) {
  FirebaseFirestore.instance.collection(collection).doc(eventId).delete();
}

void _navigateToEditEvent(BuildContext context, Map<String, dynamic> eventData, String collection) {
  Widget page = switch (collection) {
    'championships' => ChampionshipForm(groups: List<String>.from(eventData['selectedGroups']), eventData: eventData),
    'tournaments' => TournamentForm(groups: List<String>.from(eventData['selectedGroups']), eventData: eventData),
    _ => FriendlyMatchForm(groups: List<String>.from(eventData['selectedGroups']), eventData: eventData),
  };

  Navigator.push(context, MaterialPageRoute(builder: (context) => page));
}
