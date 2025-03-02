// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import for date formatting

import '../../backend_template.dart';
import 'edituserpage.dart';

class ManageUsersPage extends StatefulWidget {
  final String? filterRole; // Optional parameter to filter users by role

  const ManageUsersPage({Key? key, this.filterRole}) : super(key: key);

  @override
  _ManageUsersPageState createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return TemplatePageBack(
      title: 'Gestion des Utilisateurs',
      footerIndex: 1,
      body: Column(
        children: [
          _buildSearchBox(), // Add search box
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .where('role', isEqualTo: 'Joueur') // Filter by role "Joueur"
                  .snapshots(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
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
                  return const Center(child: Text('Aucun utilisateur trouvé.'));
                }

                return ListView.builder(
                  itemCount: filteredDocuments.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Map<String, dynamic> user =
                        filteredDocuments[index].data() as Map<String, dynamic>;

                    return Card(
                      
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        
                        title: Text(user['name']),
                        subtitle: Text('Numéro: ${user['phone']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.people, color: Colors.green), // Fetch children icon
                              onPressed: () {
                                _fetchChildren(filteredDocuments[index].id);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => EditUserPage(
                                      userId: filteredDocuments[index].id,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red), // Red trash icon
                              onPressed: () {
                                _deleteUser(filteredDocuments[index].id);
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

  void _deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur supprimé avec succès.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression: $e')),
      );
    }
  }

  // Fetch and display children of a user
 void _fetchChildren(String userId) async {
  try {
    QuerySnapshot childrenSnapshot = await _firestore
        .collection('children') // Corrected: Directly querying the children collection
        .where('parentId', isEqualTo: userId) // Match children with the given parentId
        .get();

    List<Map<String, dynamic>> children = childrenSnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();

    _showChildrenDialog(children);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur lors de la récupération des enfants: $e')),
    );
  }
}

  // Show children in a dialog
 void _showChildrenDialog(List<Map<String, dynamic>> children) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enfants associés'),
          content: children.isNotEmpty
              ? SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: children.map((child) {
                      String birthDateText = "Non spécifié";
                      if (child['birthDate'] != null) {
                        try {
                          DateTime birthDate = (child['birthDate'] as Timestamp).toDate();
                          birthDateText = DateFormat('dd MMMM yyyy').format(birthDate);
                        } catch (e) {
                          birthDateText = "Erreur de format";
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            child['imageUrl'] != null
                                ? Image.network(
                                    child['imageUrl']!,
                                    height: 50,
                                    width: 50,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.person, size: 50, color: Colors.grey),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    child['name'] ?? 'Nom inconnu',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Date de naiss: $birthDateText',
                                    style: const TextStyle(color: Colors.grey),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                )
              : const Text('Aucun enfant trouvé.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }
}