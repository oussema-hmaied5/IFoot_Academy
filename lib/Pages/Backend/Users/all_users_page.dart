// ignore_for_file: library_private_types_in_public_api

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../Style/Backend_template.dart';
import 'edituserpage.dart';

class ManageUsersPage extends StatefulWidget {
  final String? filterRole; // Optional parameter to filter users by role

  const ManageUsersPage({Key? key, this.filterRole}) : super(key: key);

  @override
  _ManageUsersPageState createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.filterRole ?? 'Tous'; // Default to 'Tous' if no filter is provided
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePageBack(
      title: 'Gestion des Utilisateurs',
      footerIndex: 1, // Set the correct footer index for the "Users" page
      body: Column(
        children: [
          Center(child: _buildRoleFilter()), // Center the role filter
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Une erreur est survenue.'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final List<DocumentSnapshot> documents = snapshot.data!.docs;

                // Apply role filter
                final filteredDocuments = _selectedRole == 'Tous'
                    ? documents
                    : documents.where((doc) => doc['role'] == _selectedRole).toList();

                return ListView.builder(
                  itemCount: filteredDocuments.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Map<String, dynamic> user =
                        filteredDocuments[index].data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text(user['name']),
                        subtitle: Text('Rôle: ${user['role']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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

  Widget _buildRoleFilter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: 250, // Adjust the width as needed for centering
        child: DropdownButtonFormField<String>(
          value: _selectedRole,
          onChanged: (String? newValue) {
            setState(() {
              _selectedRole = newValue!;
            });
          },
          items: <String>['Tous', 'coach', 'joueur']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(capitalize(value)), // Custom capitalize function
            );
          }).toList(),
          decoration: const InputDecoration(
            labelText: 'Filtrer par rôle',
            border: OutlineInputBorder(),
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
}

// Custom capitalize function
String capitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1).toLowerCase();
}
