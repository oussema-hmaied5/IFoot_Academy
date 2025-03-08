// Page de liste des joueurs d'un groupe spécifique
// ignore_for_file: library_private_types_in_public_api

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../backend_template.dart';
import 'player_evaluation_detail_page.dart';

class PlayerListPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const PlayerListPage({
    Key? key,
    required this.groupId,
    required this.groupName,
  }) : super(key: key);

  @override
  _PlayerListPageState createState() => _PlayerListPageState();
}

class _PlayerListPageState extends State<PlayerListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _players = [];

  @override
  void initState() {
    super.initState();
    _fetchPlayers();
  }

  Future<void> _fetchPlayers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Récupérer les données du groupe
      DocumentSnapshot groupDoc = await _firestore
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (!groupDoc.exists) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final groupData = groupDoc.data() as Map<String, dynamic>;
      List<dynamic> playerIds = groupData['players'] ?? [];

      List<Map<String, dynamic>> playersData = [];

      for (var playerId in playerIds) {
        // Obtenez l'ID du joueur selon la structure des données
        String id = playerId is Map ? playerId['id'] : playerId;

        DocumentSnapshot playerDoc = await _firestore
            .collection('children')
            .doc(id)
            .get();

        if (playerDoc.exists) {
          Map<String, dynamic> player = playerDoc.data() as Map<String, dynamic>;
          playersData.add({
            'id': playerDoc.id,
            'name': player['name'] ?? 'Nom non disponible',
            'imageUrl': player['imageUrl'], // Peut être null si pas d'image
            'birthDate': player['birthDate'],
          });
        }
      }

      setState(() {
        _players = playersData;
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
      title: 'Joueurs - ${widget.groupName}',
      footerIndex: 2,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _players.isEmpty
              ? const Center(child: Text('Aucun joueur dans ce groupe'))
              : ListView.builder(
                  itemCount: _players.length,
                  itemBuilder: (context, index) {
                    final player = _players[index];
                    return _buildPlayerCard(player);
                  },
                ),
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> player) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          // Naviguer vers la page d'évaluation détaillée
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlayerEvaluationDetailPage(
                playerId: player['id'],
                playerName: player['name'],
                groupName: widget.groupName,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Photo du joueur
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: player['imageUrl'] != null
                    ? NetworkImage(player['imageUrl'])
                    : null,
                child: player['imageUrl'] == null
                    ? const Icon(Icons.person, size: 30, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 16),
              // Informations du joueur
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (player['birthDate'] != null)
                      Text(
                        'Date de naissance: ${_formatDate(player['birthDate'])}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              // Icône d'évaluation
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.assessment,
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Non spécifiée';
    
    if (timestamp is Timestamp) {
      DateTime date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    
    return 'Non spécifiée';
  }
}
