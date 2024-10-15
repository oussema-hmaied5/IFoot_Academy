// ignore_for_file: library_private_types_in_public_api

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddGroupPage extends StatefulWidget {
  const AddGroupPage({Key? key}) : super(key: key);

  @override
  _AddGroupPageState createState() => _AddGroupPageState();
}

class _AddGroupPageState extends State<AddGroupPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _groupNameController = TextEditingController();
  final List<String> _selectedPlayers = []; // List of selected player IDs
  List<DocumentSnapshot> _availablePlayers = []; // List of available players
  int? _selectedYearFilter; // Year filter variable

  @override
  void initState() {
    super.initState();
    _fetchAvailablePlayers(); // Fetch players when the page loads
  }

  // Fetch players who are not assigned to any group and optionally filter by year of birth
void _fetchAvailablePlayers() async {
  try {
    QuerySnapshot playersSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'joueur')
        .get();

    setState(() {
      _availablePlayers = playersSnapshot.docs.where((playerDoc) {
        final Map<String, dynamic> data =
            playerDoc.data() as Map<String, dynamic>;

        // Vérifiez que le joueur n'est assigné à aucun groupe ou qu'il fait partie du groupe en cours d'édition
        final List<dynamic> assignedGroups =
            data.containsKey('assignedGroups')
                ? data['assignedGroups'] as List<dynamic>
                : [];

        // Le joueur doit être disponible s'il n'est assigné à aucun groupe
        return assignedGroups.isEmpty || _selectedPlayers.contains(playerDoc.id);
      }).toList();
    });
  } catch (e) {
    print('Error fetching players: $e');
  }
}


  // Save the group and assign players
  void _saveGroup() async {
    try {
      if (_groupNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez entrer un nom de groupe')),
        );
        return;
      }

      if (_selectedPlayers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner au moins un joueur')),
        );
        return;
      }

      final groupDoc = _firestore.collection('groups').doc();
      await groupDoc.set({
        'name': _groupNameController.text.trim(),
        'players': _selectedPlayers,
        'createdAt': FieldValue.serverTimestamp(),
      });

 // Met à jour le nombre total de groupes dans la collection 'stats'
  var groupCount = (await FirebaseFirestore.instance.collection('groups').get()).docs.length;
  await FirebaseFirestore.instance.collection('stats').doc('academyStats').update({
    'groupCount': groupCount,
  });
  
      WriteBatch batch = _firestore.batch();
      for (String playerId in _selectedPlayers) {
        DocumentReference playerRef = _firestore.collection('users').doc(playerId);
        batch.update(playerRef, {
          'assignedGroups': FieldValue.arrayUnion([groupDoc.id]),
        });
      }
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Groupe enregistré avec succès')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'enregistrement du groupe: $e')),
      );
    }
  }

  Future<void> _selectYear(BuildContext context) async {
    int currentYear = DateTime.now().year;
    List<int> years = List<int>.generate(50, (index) => currentYear - index);

    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Sélectionner une année',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: years.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      title: Text(years[index].toString()),
                      onTap: () {
                        setState(() {
                          _selectedYearFilter = years[index];
                        });
                        Navigator.of(context).pop();
                        _fetchAvailablePlayers();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un Groupe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveGroup,
            tooltip: 'Enregistrer le groupe',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                labelText: 'Nom du Groupe',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Filtrer par année :'),
                Expanded(
                  child: TextButton(
                    onPressed: () => _selectYear(context),
                    child: Text(
                      _selectedYearFilter == null ? 'Sélectionner une date' : _selectedYearFilter.toString(),
                    ),
                  ),
                ),
                if (_selectedYearFilter != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _selectedYearFilter = null;
                      });
                      _fetchAvailablePlayers();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _availablePlayers.isEmpty
                  ? const Center(child: Text('Aucun joueur disponible'))
                  : ListView.builder(
                      itemCount: _availablePlayers.length,
                      itemBuilder: (context, index) {
                        final playerDoc = _availablePlayers[index];
                        final playerData = playerDoc.data() as Map<String, dynamic>;

                        String dateOfBirthText = 'Date de naissance non disponible';
                        if (playerData['dateOfBirth'] != null) {
                          if (playerData['dateOfBirth'] is Timestamp) {
                            DateTime dob = (playerData['dateOfBirth'] as Timestamp).toDate();
                            dateOfBirthText = DateFormat.yMMMd().format(dob);
                          } else if (playerData['dateOfBirth'] is String) {
                            DateTime? parsedDate = DateTime.tryParse(playerData['dateOfBirth']);
                            if (parsedDate != null) {
                              dateOfBirthText = DateFormat.yMMMd().format(parsedDate);
                            }
                          }
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          child: CheckboxListTile(
                            title: Text(playerData['name'] ?? 'Nom non disponible'),
                            subtitle: Text(dateOfBirthText),
                            value: _selectedPlayers.contains(playerDoc.id),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedPlayers.add(playerDoc.id);
                                } else {
                                  _selectedPlayers.remove(playerDoc.id);
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
