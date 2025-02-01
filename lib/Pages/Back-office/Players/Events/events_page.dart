import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/Pages/Back-office/Backend_template.dart';

import 'add_event_page.dart';

class ManageEventsPage extends StatefulWidget {
  const ManageEventsPage({Key? key}) : super(key: key);

  @override
  _ManageEventsPageState createState() => _ManageEventsPageState();
}

class _ManageEventsPageState extends State<ManageEventsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> events = [];
  List<String> groups = []; // Liste des groupes récupérés depuis Firestore

  @override
  void initState() {
    super.initState();
    _fetchEvents();
    _fetchGroups(); // Récupérer les groupes au démarrage
  }

  // Récupérer les événements depuis Firestore
  Future<void> _fetchEvents() async {
    try {
      final snapshot = await _firestore.collection('championships').get();
      setState(() {
        events = snapshot.docs;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Erreur lors de la récupération des événements : $e')),
      );
    }
  }

  // Récupérer les groupes depuis Firestore
  Future<void> _fetchGroups() async {
    try {
      final snapshot = await _firestore.collection('groups').get();
      setState(() {
        groups = snapshot.docs.map((doc) => doc['name'] as String).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur lors de la récupération des groupes : $e')),
      );
    }
  }

  // Fonction pour supprimer un événement
  Future<void> _deleteEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Événement supprimé avec succès.')),
      );
      _fetchEvents(); // Rafraîchir la liste après la suppression
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePageBack(
      title: 'Gestion des événements',
            footerIndex: 3, // Set the correct footer index for the "Users" page

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEventForm(
                eventType: 'Friendly Match',
                groups: groups, 
              ),
            ),
          ).then((_) {
            _fetchEvents(); 
          });
        },
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Championnat'),
            _buildEventList('Championnat'),
            _buildSectionTitle('Tournoi'),
            _buildEventList('Tournoi'),
            _buildSectionTitle('Match Amical'),
            _buildEventList('Contre une académie'),
          ],
        ),
      ),
    );
  }

  // Section titre avec un bouton "+"
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEventForm(
                    eventType: title, // Pass the event type (e.g. Championnat)
                    groups: groups, // Pass the groups
                  ),
                ),
              ).then((_) {
                _fetchEvents(); // Rafraîchir la liste des événements après l'ajout
              });
            },
          ),
        ],
      ),
    );
  }

  // Liste des événements filtrée par type
  Widget _buildEventList(String eventType) {
    final filteredEvents = events.where((event) {
      final eventData = event.data() as Map<String, dynamic>?;
      return eventData != null && eventData['name'] == eventType; // Correction ici
    }).toList();

    if (filteredEvents.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('Aucun événement disponible.', textAlign: TextAlign.center),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) {
        final event = filteredEvents[index];
        final eventData = event.data() as Map<String, dynamic>;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text(eventData['matchName'] ?? 'Nom indisponible'),
            subtitle: Text(
              'Lieu : ${eventData['location'] ?? 'Indisponible'}\nDate : ${eventData['startTime'] ?? 'Indisponible'}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEventForm(
                          eventType: 'Friendly Match',
                          groups: groups, // Pass groups
                        ),
                      ),
                    ).then((_) {
                      _fetchEvents();
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteEvent(event.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
