// ignore_for_file: library_private_types_in_public_api

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/presantation/Admin/Users/edituserpage.dart';

class ManageUsersPage extends StatefulWidget {
  final String? filterRole;  // Optional parameter to filter users by role

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
    _selectedRole = widget.filterRole ?? 'Tous';  // Use filterRole if provided, otherwise default to 'Tous'
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gérer les Utilisateurs'),
      ),
      body: Column(
        children: [
          _buildRoleFilter(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Quelque chose s\'est mal passé'));
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
                    final Map<String, dynamic> user = filteredDocuments[index].data()! as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      child: ListTile(
                        title: Text(user['name']),
                        subtitle: Text('Rôle: ${user['role']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                    Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => EditUserPage(userId: filteredDocuments[index].id)),
                            );},
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
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
      padding: const EdgeInsets.all(8.0),
      child: DropdownButton<String>(
        value: _selectedRole,
        onChanged: (String? newValue) {
          setState(() {
            _selectedRole = newValue!;
          });
        },
        items: <String>['Tous', 'coach', 'user', 'joueur', 'pending']
            .map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(capitalize(value)),  // Use the custom capitalize function
          );
        }).toList(),
      ),
    );
  }

  void _deleteUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
    setState(() {});
  }
}

// Custom capitalize function to avoid conflicts
String capitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1).toLowerCase();
}
