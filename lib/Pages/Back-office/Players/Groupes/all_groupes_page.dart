// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/Pages/Back-office/backend_template.dart';
import 'package:ifoot_academy/models/group.dart';

import 'add_groupe_page.dart';
import 'edit_groupe.dart';
import 'schedule_training_page.dart';

class ManageGroupsPage extends StatefulWidget {
  const ManageGroupsPage({Key? key}) : super(key: key);

  @override
  _ManageGroupsPageState createState() => _ManageGroupsPageState();
}

class _ManageGroupsPageState extends State<ManageGroupsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = "";
  String _selectedGroupType = 'Loisirs'; // Default group type
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return TemplatePageBack(
      title: 'Gestion des Groupes',
      footerIndex: 2, // Set the correct footer index for the "Users" page
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Group Type Filter Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedGroupType = 'Loisirs';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedGroupType == 'Loisirs'
                        ? Colors.blue
                        : Colors.grey,
                  ),
                  child: const Text('Loisirs'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedGroupType = 'Perfectionnement';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedGroupType == 'Perfectionnement'
                        ? Colors.blue
                        : Colors.grey,
                  ),
                  child: const Text('Perfectionnement'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildSearchBox(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('groups')
                    .where('type', isEqualTo: _selectedGroupType)
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                        child: Text('Une erreur s\'est produite.'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final List<DocumentSnapshot> documents = snapshot.data!.docs;

                  // Filter groups by search query
                  final filteredDocuments = documents.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name']?.toString().toLowerCase() ?? '';
                    return name.contains(_searchQuery.toLowerCase());
                  }).toList();

                  return ListView.builder(
                    itemCount: filteredDocuments.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocuments[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final group = Group.fromFirestore(doc);

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        elevation: 5,
                        margin: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 15),
                        child: ListTile(
                          title: Text(
                            data['name'] ?? 'Nom non disponible',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Type: ${data['type'] ?? 'Inconnu'}'),
                              StreamBuilder<QuerySnapshot>(
                                stream: _firestore
                                    .collection('trainings')
                                    .where('groupId', isEqualTo: group.id)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Text(
                                        'Chargement des entraînements...');
                                  }
                                  if (!snapshot.hasData ||
                                      snapshot.data!.docs.isEmpty) {
                                    return const Text(
                                        'Aucun entraînement assigné');
                                  }

                                  // Liste pour définir l'ordre des jours
                                  final List<String> daysOrder = [
                                    "Lundi",
                                    "Mardi",
                                    "Mercredi",
                                    "Jeudi",
                                    "Vendredi",
                                    "Samedi",
                                    "Dimanche"
                                  ];

                                  // Regrouper les entraînements par jour
                                  final Map<String, Set<String>>
                                      groupedTrainings = {};
                                  for (var doc in snapshot.data!.docs) {
                                    final day = doc['day'] ?? '';
                                    final startTime = doc['startTime'] ?? '';
                                    final endTime = doc['endTime'] ?? '';
                                    final timeRange = '$startTime - $endTime';

                                    // Regrouper par jour, sans doublons d'horaires
                                    if (!groupedTrainings.containsKey(day)) {
                                      groupedTrainings[day] = {};
                                    }
                                    groupedTrainings[day]!.add(timeRange);
                                  }

                                  // Trier les jours en fonction de l'ordre défini
                                  final sortedTrainingDetails = groupedTrainings
                                      .entries
                                      .toList()
                                    ..sort((a, b) {
                                      final indexA = daysOrder.indexOf(a.key);
                                      final indexB = daysOrder.indexOf(b.key);
                                      return indexA.compareTo(indexB);
                                    });

                                  // Construire une liste des jours avec horaires consolidés
                                  final trainingDetails =
                                      sortedTrainingDetails.map((entry) {
                                    final times = entry.value.join(', ');
                                    return '${entry.key} : $times';
                                  }).join('\n');

                                  return Text(
                                    trainingDetails,
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.grey),
                                  );
                                },
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.schedule,
                                    color: Colors.green),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => AssignTrainingPage(
                                        groupId: group.id,
                                        groupName: group.name,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          EditGroupPage(group: group),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteGroup(doc.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddGroupPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          labelText: 'Rechercher par nom',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteGroup(String groupId) async {
    await _firestore.collection('groups').doc(groupId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Groupe supprimé avec succès')),
    );
  }
}
