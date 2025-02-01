import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../Backend_template.dart';
import 'add_coach_page.dart';
import 'coach_details_page.dart';
import 'edit_coach_page.dart';

class ManageCoachesPage extends StatefulWidget {
  const ManageCoachesPage({Key? key}) : super(key: key);

  @override
  _ManageCoachesPageState createState() => _ManageCoachesPageState();
}

class _ManageCoachesPageState extends State<ManageCoachesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return TemplatePageBack(
      title: 'Gestion des Coachs',
      footerIndex: 1, // Adjust to match the correct footer index for "Coaches"
      isCoach: true, // Ensure this is true to show the coach footer
      body: Column(
        children: [
          _buildSearchBox(), // Add search box
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('coaches').snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Une erreur est survenue.'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final List<DocumentSnapshot> documents = snapshot.data!.docs;

                // Apply search filter
                final filteredDocuments = documents.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final matchesSearch = data['name']
                      .toString()
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase());
                  return matchesSearch;
                }).toList();

                if (filteredDocuments.isEmpty) {
                  return const Center(child: Text('Aucun coach trouvé.'));
                }

                return ListView.builder(
                  itemCount: filteredDocuments.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Map<String, dynamic> coach =
                        filteredDocuments[index].data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text(coach['name'] ?? 'Nom indisponible'),
                        subtitle: Text('Email: ${coach['email']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.info,
                                  color: Colors.green), // Bouton d'info
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => CoachDetailsPage(
                                        coachId: filteredDocuments[index].id),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => EditCoachPage(
                                      coachId: filteredDocuments[index].id,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red), // Red trash icon
                              onPressed: () {
                                _deleteCoach(filteredDocuments[index].id);
                              },
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddCoachPage()),
          );
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
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

  void _deleteCoach(String coachId) async {
    try {
      await _firestore.collection('coaches').doc(coachId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coach supprimé avec succès.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression: $e')),
      );
    }
  }
}
