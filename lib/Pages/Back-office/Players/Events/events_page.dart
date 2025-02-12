import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/Pages/Back-office/Backend_template.dart';
import 'package:ifoot_academy/Pages/Back-office/Players/Events/championship_form.dart';
import 'package:ifoot_academy/Pages/Back-office/Players/Events/friendly_match_form.dart';
import 'package:ifoot_academy/Pages/Back-office/Players/Events/tournament_form.dart';

class EventManager extends StatefulWidget {
  const EventManager({super.key});

  @override
  _EventManagerState createState() => _EventManagerState();
}

class _EventManagerState extends State<EventManager> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: TemplatePageBack(
        title: 'Gestion des Événements',
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                _navigateToAddEvent(context);
              },
            ),
          ),
        ],
        body: const Column(
          children: [
            TabBar(
              tabs: [
                Tab(icon: Icon(Icons.emoji_events), text: 'Championnats'),
                Tab(icon: Icon(Icons.emoji_events_outlined), text: 'Tournois'),
                Tab(icon: Icon(Icons.sports_soccer), text: 'Matchs Amicaux'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
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

  void _navigateToAddEvent(BuildContext context) {
    final tabIndex = DefaultTabController.of(context).index;
    Widget page;
    switch (tabIndex) {
      case 0:
        page = const ChampionshipForm(groups: []);
        break;
      case 1:
        page = const TournamentForm(groups: []);
        break;
      case 2:
        page = const FriendlyMatchForm(groups: []);
        break;
      default:
        page = const ChampionshipForm(groups: []);
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }
}

class ChampionshipsTab extends StatelessWidget {
  const ChampionshipsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildEventList('championships', context);
  }
}

class TournamentsTab extends StatelessWidget {
  const TournamentsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildEventList('tournaments', context);
  }
}

class FriendlyMatchesTab extends StatelessWidget {
  const FriendlyMatchesTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildEventList('friendly_matches', context);
  }
}

Widget _buildEventList(String collection, BuildContext context) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection(collection).snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final events = snapshot.data!.docs;
      return ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          return eventTile(events[index], collection, context);
        },
      );
    },
  );
}

// ✅ Common Event Tile with Icons & Actions
Widget eventTile(
    DocumentSnapshot event, String collection, BuildContext context) {
  final eventData = event.data() as Map<String, dynamic>;

  return Card(
    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
    child: ListTile(
      leading: Icon(
        collection == 'championships'
            ? Icons.emoji_events
            : collection == 'tournaments'
                ? Icons.emoji_events_outlined
                : Icons.sports_soccer,
        color: Colors.blueAccent,
      ),
      title: Text(eventData['name'] ?? 'Nom indisponible'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("📍 Lieu: ${eventData['locationType'] ?? 'Indisponible'}"),
          if (eventData.containsKey('selectedGroups'))
            Text("👥 Groupes: ${eventData['selectedGroups'].join(", ")}"),
          if (eventData.containsKey('selectedChildren'))
            Text(
                "👦 Joueurs: ${eventData['selectedChildren'].length} participants"),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () {
               // edit event
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              _deleteEvent(event.id, collection, context);
            },
          ),
        ],
      ),
      onTap: () {
        // Handle event details navigation
      },
    ),
  );
}

// ✅ Delete Function with Confirmation
void _deleteEvent(String eventId, String collection, BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Supprimer l'événement?"),
      content: const Text(
          "Voulez-vous vraiment supprimer cet événement? Cette action est irréversible."),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Annuler"),
        ),
        TextButton(
          onPressed: () async {
            try {
              await FirebaseFirestore.instance
                  .collection(collection)
                  .doc(eventId)
                  .delete();
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("Événement supprimé avec succès.")),
              );
              // ignore: use_build_context_synchronously
              Navigator.pop(context);
            } catch (e) {
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Erreur lors de la suppression.")),
              );
            }
          },
          child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}

