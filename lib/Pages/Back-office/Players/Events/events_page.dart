import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/Pages/Back-office/Players/Events/friendly_match_form.dart';
import 'package:ifoot_academy/Pages/Back-office/Players/Events/tournament_form.dart';
import 'package:ifoot_academy/Pages/Back-office/backend_template.dart';
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
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      return ListView.builder(
        itemCount: snapshot.data!.docs.length,
        itemBuilder: (context, index) =>
            eventTile(snapshot.data!.docs[index], collection, context),
      );
    },
  );
}

Widget eventTile(
    DocumentSnapshot event, String collection, BuildContext context) {
  final eventData = event.data() as Map<String, dynamic>;
  final List<dynamic> matchDays = eventData['matchDays'] ?? [];

  // 🔹 Obtenir les dernières journées
  List<dynamic> latestMatchDays = matchDays.reversed.take(3).toList();

  // ✅ Extraire tous les coachs assignés aux journées
  List<String> allCoachIds = [];
  for (var day in latestMatchDays) {
    List<String> coachIds = List<String>.from(day['coaches'] ?? []);
    allCoachIds.addAll(coachIds);
  }
  allCoachIds = allCoachIds.toSet().toList(); // ✅ Supprime les doublons

  return Card(
    margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 8),
    child: Column(
      children: [
        ListTile(
          leading: Icon(_getEventIcon(collection), color: Colors.blue),
          title: Text(
            eventData['name'] ?? "Match Amical",
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 22, color: Colors.blue),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // ✅ Détails toujours visibles
        _buildExpandedEventDetails(
            event, eventData, collection, latestMatchDays, context),
      ],
    ),
  );
}

Widget _buildExpandedEventDetails(
    DocumentSnapshot event,
    Map<String, dynamic> eventData,
    String collection,
    List<dynamic> latestMatchDays,
    BuildContext context) {

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ CHAMPIONNATS : Affiche uniquement pour les "championships"
        if (collection == "championships") ...[
          _buildEventDetailRow(
              Icons.groups,
              "Groupes: ${(eventData['selectedGroups'] as List<dynamic>?)?.join(", ") ?? 'Aucun groupe'}",
              Colors.green),
          _buildEventDetailRow(Icons.location_on,
              "Lieu: ${eventData['locationType'] ?? 'N/A'}", Colors.red),
          _buildEventDetailRow(
              Icons.euro, "Frais: ${eventData['fee']} TND", Colors.teal),

               _buildEventDetailRow(Icons.location_on,
            "Lieu: ${eventData['locationType'] ?? 'N/A'}", Colors.red),

        const SizedBox(height: 10),

        // 🔹 Journées récentes (Affiché pour tous les événements)
        if (latestMatchDays.isNotEmpty) ...[
          const Text("📆 Dernières Journées :",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ...latestMatchDays.asMap().entries.map((entry) {
            Map<String, dynamic> day = entry.value;
            int journeeNumber = eventData['matchDays'].indexOf(day) + 1;

            List<String> coachIds = List<String>.from(day['coaches'] ?? []);

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 5),
              child: ListTile(
                title: Text(
                    "📅 Journée $journeeNumber - ${_formatDate(day['date'])}"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEventDetailRow(
                        Icons.directions_bus,
                        "Transport: ${day['transportMode'] ?? 'Non défini'}",
                        Colors.blue),

                    // ✅ FutureBuilder pour récupérer et afficher les coachs
                    FutureBuilder<List<String>>(
                      future: _fetchCoachNames(
                          coachIds), // 🔥 Récupérer les noms des coachs
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return _buildEventDetailRow(
                              Icons.error,
                              "Erreur lors du chargement des coachs",
                              Colors.red);
                        }

                        String coachNames = snapshot.data!.isNotEmpty
                            ? snapshot.data!.join(", ")
                            : "Aucun coach assigné";

                        return _buildEventDetailRow(
                            Icons.person, "Coaches: $coachNames", Colors.green);
                      },
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _navigateToEditJournee(context, event.id,
                      eventData['matchDays'].indexOf(day), day),
                ),
              ),
            );
          }),
        ],

        ],

        // ✅ TOURNOIS : Affiche uniquement pour "tournaments"
        if (collection == "tournaments") ...[
          _buildEventDetailRow(
              Icons.groups,
              "Groupes: ${(eventData['selectedGroups'] as List<dynamic>?)?.join(", ") ?? 'Aucun groupe'}",
              Colors.green),
          _buildEventDetailRow(
              Icons.date_range,
              "Date: ${_formatEventDates(eventData['dates'])}",
              const Color.fromARGB(255, 27, 13, 149)),
          _buildEventDetailRow(Icons.location_on,
              "Lieu: ${eventData['locationType'] ?? 'N/A'}", Colors.red),
          _buildEventDetailRow(
              Icons.money, "Frais: ${eventData['fee']} TND", Colors.teal),
        ],

        // ✅ MATCHS AMICAUX : Affiche uniquement pour "friendlyMatches"
        if (collection == "friendlyMatches") ...[
          _buildEventDetailRow(
              Icons.sports_soccer,
              "Type de match: ${eventData['matchType'] ?? 'Non défini'}",
              Colors.green),

          // ✅ Afficher les détails si le match est contre une académie
          if (eventData['matchType'] == "Contre une académie") ...[
            _buildEventDetailRow(
                Icons.school,
                "Académie: ${eventData['matchName'] ?? 'Non définie'}",
                Colors.blue),
            _buildEventDetailRow(
                Icons.groups,
                "Groupes: ${(eventData['selectedGroups'] as List<dynamic>?)?.join(", ") ?? 'Aucun groupe'}",
                Colors.green),
          ],

          // ✅ Afficher les détails si le match est contre un groupe Ifoot
          if (eventData['matchType'] == "Contre un groupe Ifoot") ...[
            _buildEventDetailRow(
                Icons.groups,
                "Groupes: ${(eventData['selectedGroups'] as List<dynamic>?)?.join(", ") ?? 'Aucun groupe'}",
                Colors.green),
            if (eventData['uniforms'] is Map<String, dynamic>)
              ..._buildUniformWidgets(eventData['uniforms']),
          ],
        ],
        const SizedBox(height: 10),

        // 🔹 Actions: Modifier / Supprimer (Affiché pour tous les événements)
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _navigateToEditEvent(context, event, collection),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () =>
                  _confirmDeleteEvent(event.id, collection, context),
            ),
          ],
        ),
      ],
    ),
  );
}

List<Widget> _buildUniformWidgets(Map<String, dynamic> uniforms) {
  List<Widget> uniformWidgets = [];
  for (var entry in uniforms.entries) {
    uniformWidgets.add(
      _buildEventDetailRow(
        Icons.checkroom,
        "Tenue pour ${entry.key}: ${entry.value}",
        Colors.purple,
      ),
    );
  }
  return uniformWidgets;
}

String _formatEventDates(dynamic dates) {
  if (dates is List) {
    return dates.map((date) {
      if (date is Timestamp) {
        return DateFormat("dd/MM/yyyy").format(date.toDate());
      } else if (date is String) {
        try {
          return DateFormat("dd/MM/yyyy").format(DateTime.parse(date));
        } catch (e) {
          return date; // Return the original string if parsing fails
        }
      }
      return "Inconnue";
    }).join(", ");
  }
  return "N/A";
}

void _navigateToEditJournee(BuildContext context, String eventId,
    int journeeIndex, Map<String, dynamic> journeeData) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => JourneeDetails(
        championshipId: eventId,
        journeeIndex: journeeIndex, // ✅ Passer l'index correct de la journée
        journeeData: journeeData,
      ),
    ),
  );
}

Future<List<String>> _fetchCoachNames(List<String> coachIds) async {
  if (coachIds.isEmpty) {
    return []; // ✅ Retourner une liste vide si aucun coach n'est assigné
  }

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('coaches')
        .where(FieldPath.documentId, whereIn: coachIds)
        .get();

    return snapshot.docs
        .map((doc) =>
            doc['name'] as String? ??
            "Inconnu") // Sécurité en cas de champ manquant
        .toList();
  
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

IconData _getEventIcon(String collection) =>
    {
      'championships': Icons.emoji_events,
      'tournaments': Icons.emoji_events_outlined,
      'friendlyMatches': Icons.sports_soccer,
    }[collection] ??
    Icons.event;

String _formatDate(dynamic dateField) {
  if (dateField is Timestamp) {
    return DateFormat("dd/MM/yyyy").format(dateField.toDate());
  }
  if (dateField is String) return dateField;
  return "Inconnue";
}

void _confirmDeleteEvent(
    String eventId, String collection, BuildContext context) {
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
              FirebaseFirestore.instance
                  .collection(collection)
                  .doc(eventId)
                  .delete();
              Navigator.of(context).pop();
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  );
}

void _navigateToEditEvent(
    BuildContext context, DocumentSnapshot eventDoc, String collection) {
  Map<String, dynamic> eventData = eventDoc.data() as Map<String, dynamic>;
  eventData['id'] = eventDoc.id; // ✅ Ajoutez l'ID au `eventData`

  Widget page = switch (collection) {
    'championships' =>
      ChampionshipDetails(championship: eventDoc, groups: const []),
    'tournaments' => TournamentForm(
        tournament: eventDoc,
        groups: List<String>.from(eventData['selectedGroups'] ?? [])),
    _ => FriendlyMatchForm(
        groups: List<String>.from(eventData['selectedGroups'] ?? []),
        eventData: eventData, // ✅ Pass eventData with ID
      ),
  };

  Navigator.push(context, MaterialPageRoute(builder: (context) => page));
}
