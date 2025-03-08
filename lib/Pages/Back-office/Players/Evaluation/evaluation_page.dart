// ignore_for_file: library_private_types_in_public_api

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/Pages/Back-office/backend_template.dart';

import 'player_liste_page.dart';

class PlayerEvaluationPage extends StatefulWidget {
  const PlayerEvaluationPage({Key? key}) : super(key: key);

  @override
  _PlayerEvaluationPageState createState() => _PlayerEvaluationPageState();
}

class _PlayerEvaluationPageState extends State<PlayerEvaluationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _groups = [];
  String _selectedGroupType = 'Tous';

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot snapshot;
      
      if (_selectedGroupType == 'Tous') {
        snapshot = await _firestore.collection('groups').get();
      } else {
        snapshot = await _firestore
            .collection('groups')
            .where('type', isEqualTo: _selectedGroupType)
            .get();
      }

      List<Map<String, dynamic>> groupsWithPlayersCount = [];

      for (var doc in snapshot.docs) {
        final groupData = doc.data() as Map<String, dynamic>;
        final String groupId = doc.id;
        final String groupName = groupData['name'] ?? 'Groupe sans nom';
        final String groupType = groupData['type'] ?? 'Non défini';
        
        // Compter les joueurs dans ce groupe
        List<dynamic> players = groupData['players'] ?? [];
        int playersCount = players.length;

        groupsWithPlayersCount.add({
          'id': groupId,
          'name': groupName,
          'type': groupType,
          'playersCount': playersCount
        });
      }

      setState(() {
        _groups = groupsWithPlayersCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePageBack(
      title: 'Évaluation des Joueurs',
      footerIndex: 2,
      body: Column(
        children: [
          // Filtres par type de groupe
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFilterButton('Tous'),
                const SizedBox(width: 8),
                _buildFilterButton('Loisirs'),
                const SizedBox(width: 8),
                _buildFilterButton('Perfectionnement'),
              ],
            ),
          ),
          
          // Liste des groupes
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _groups.isEmpty
                    ? const Center(child: Text('Aucun groupe trouvé'))
                    : ListView.builder(
                        itemCount: _groups.length,
                        itemBuilder: (context, index) {
                          final group = _groups[index];
                          return _buildGroupCard(group);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String type) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedGroupType = type;
        });
        _fetchGroups();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedGroupType == type
            ? Colors.blue
            : Colors.grey,
      ),
      child: Text(type),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          // Navigation vers la liste des joueurs du groupe
          Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (context) => PlayerListPage(
                groupId: group['id'],
                groupName: group['name'],
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Type de groupe (icône)
              CircleAvatar(
                backgroundColor: group['type'] == 'Perfectionnement' 
                    ? Colors.blue 
                    : Colors.green,
                child: const Icon(
                  Icons.group,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              // Informations du groupe
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group['name'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Type: ${group['type']}',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Nombre de joueurs
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${group['playersCount']} joueurs',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
