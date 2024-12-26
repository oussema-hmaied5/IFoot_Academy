import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../Style/Frontend_template.dart';

class MyTeamPage extends StatefulWidget {
  const MyTeamPage({Key? key}) : super(key: key);

  @override
  _MyTeamPageState createState() => _MyTeamPageState();
}

class _MyTeamPageState extends State<MyTeamPage> {
  String groupName = 'Aucun';
  List<Map<String, dynamic>> players = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeamData();
  }

 Future<void> _loadTeamData() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) throw 'User document not found in Firestore.';

      final groupId = userDoc.data()?['groupId'];
      if (groupId == null || groupId.isEmpty) {
        throw 'User is not assigned to any group.';
      }

      final groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .get();

      if (!groupDoc.exists) throw 'Group document not found in Firestore.';

      setState(() {
        groupName = groupDoc.data()?['name'] ?? 'Aucun';
        players = List<Map<String, dynamic>>.from(groupDoc.data()?['players'] ?? []);
      });
    } else {
      throw 'No user is logged in.';
    }
  } catch (e) {
    print('Error loading team data: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur: $e')),
    );
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return FrontendTemplate(
      title: 'Mon Équipe',
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nom du Groupe: $groupName',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Joueurs:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: players.isEmpty
                        ? const Text('Aucun joueur trouvé.')
                        : ListView.builder(
                            itemCount: players.length,
                            itemBuilder: (context, index) {
                              final player = players[index];
                              return Card(
                                elevation: 5,
                                child: ListTile(
                                  leading: const Icon(Icons.person, color: Colors.teal),
                                  title: Text(player['name'] ?? 'Nom indisponible'),
                                  subtitle: Text(player['position'] ?? 'Position non spécifiée'),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      footerIndex: 1, // Highlight 'My Group' in the bottom navigation
    );
  }
}
