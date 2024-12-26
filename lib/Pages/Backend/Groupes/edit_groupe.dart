import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/models/group.dart';

import '../Menu/footer.dart';

class EditGroupPage extends StatefulWidget {
  final Group group;

  const EditGroupPage({Key? key, required this.group}) : super(key: key);

  @override
  _EditGroupPageState createState() => _EditGroupPageState();
}

class _EditGroupPageState extends State<EditGroupPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _groupNameController = TextEditingController();
  final List<String> _selectedPlayers = [];
  List<DocumentSnapshot> _availablePlayers = [];

  @override
  void initState() {
    super.initState();
    _groupNameController.text = widget.group.name;
    _selectedPlayers.addAll(widget.group.players);
    _fetchAvailablePlayers();
  }

  void _fetchAvailablePlayers() async {
    try {
      QuerySnapshot playersSnapshot = await _firestore
          .collection('users')
          .where('role',
              isEqualTo: 'joueur') // Ensure we only fetch players (joueur role)
          .get();

      setState(() {
        _availablePlayers = playersSnapshot.docs.where((playerDoc) {
          final Map<String, dynamic> data =
              playerDoc.data() as Map<String, dynamic>;

          // Check if 'assignedGroups' field exists, if not assume it's an empty list
          final List<dynamic> assignedGroups =
              data.containsKey('assignedGroups')
                  ? data['assignedGroups'] as List<dynamic>
                  : [];

          // Ensure players already in _selectedPlayers (current group) are shown
          return assignedGroups.isEmpty ||
              _selectedPlayers.contains(playerDoc.id);
        }).toList();
      });
    } catch (e) {
      print('Error fetching players: $e');
    }
  }

void _saveGroup() async {
  try {
    // Obtenez les joueurs actuellement dans le groupe
    List<String> currentPlayers = widget.group.players;

    // Vérifiez quels joueurs ont été retirés
    List<String> removedPlayers = currentPlayers.where((playerId) => !_selectedPlayers.contains(playerId)).toList();
    
    // Vérifiez quels joueurs ont été ajoutés
    List<String> addedPlayers = _selectedPlayers.where((playerId) => !currentPlayers.contains(playerId)).toList();

    // Mettre à jour les joueurs retirés
    for (String playerId in removedPlayers) {
      await _firestore.collection('users').doc(playerId).update({
        'assignedGroups': FieldValue.arrayRemove([widget.group.id]),
      });
    }

    // Mettre à jour les joueurs ajoutés
    for (String playerId in addedPlayers) {
      await _firestore.collection('users').doc(playerId).update({
        'assignedGroups': FieldValue.arrayUnion([widget.group.id]),
      });
    }

    // Mettre à jour le groupe avec le nouveau nom et les nouveaux joueurs
    await _firestore.collection('groups').doc(widget.group.id).update({
      'name': _groupNameController.text,
      'players': _selectedPlayers,
    });

    Navigator.of(context).pop(); // Go back after saving
  } catch (e) {
    print('Error saving group: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Light background color
      appBar: AppBar(
        title: const Text('Edit Group'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple, // Add a color for the header
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveGroup,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Entête section
            Text(
              'Edit the Group:',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple, // Color for the entête
              ),
            ),
            const SizedBox(height: 20),

            // Group Name Input Field
            TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                labelText: 'Group Name',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Players list
            Text(
              'Select Players:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: _availablePlayers.length,
                itemBuilder: (context, index) {
                  final playerDoc = _availablePlayers[index];
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: CheckboxListTile(
                      title: Text(playerDoc['name']),
                      value: _selectedPlayers.contains(playerDoc.id),
                      activeColor: Colors.deepPurple, // Checkbox color
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
      bottomNavigationBar: Footer(currentIndex: 2),
    );
  }
}
