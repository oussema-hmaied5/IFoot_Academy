// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/Pages/Back-office/backend_template.dart';
import 'package:ifoot_academy/models/group.dart';

class EditGroupPage extends StatefulWidget {
  final Group group;

  const EditGroupPage({Key? key, required this.group}) : super(key: key);

  @override
  _EditGroupPageState createState() => _EditGroupPageState();
}

class _EditGroupPageState extends State<EditGroupPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _groupNameController = TextEditingController();
  final List<String> _selectedChildren = [];
  List<Map<String, dynamic>> _availableChildren = [];

  @override
  void initState() {
    super.initState();
    _groupNameController.text = widget.group.name;
    _selectedChildren.addAll(widget.group.players);
    _fetchAvailableChildren();
  }

  Future<void> _fetchAvailableChildren() async {
    try {
      final QuerySnapshot childrenSnapshot =
          await _firestore.collection('children').get();
      List<Map<String, dynamic>> childrenWithParentNames = [];

      for (var childDoc in childrenSnapshot.docs) {
        final Map<String, dynamic> childData =
            childDoc.data() as Map<String, dynamic>;
        final List<dynamic>? assignedGroups =
            childData['assignedGroups'] as List<dynamic>?;

        if (assignedGroups == null ||
            assignedGroups.isEmpty ||
            assignedGroups.contains(widget.group.id)) {
          final String? parentId = childData['parentId'];
          String parentName = 'Parent inconnu';

          if (parentId != null) {
            final DocumentSnapshot parentSnapshot =
                await _firestore.collection('users').doc(parentId).get();
            if (parentSnapshot.exists) {
              final Map<String, dynamic>? parentData =
                  parentSnapshot.data() as Map<String, dynamic>?;
              parentName = parentData?['name'] ?? 'Parent inconnu';
            }
          }

          childrenWithParentNames.add({
            'id': childDoc.id,
            'name': childData['name'] ?? 'Nom non disponible',
            'birthDate': childData['birthDate'],
            'parentName': parentName,
            'imageUrl': childData['imageUrl'], // Add imageUrl field
          });
        }
      }

      setState(() {
        _availableChildren = childrenWithParentNames;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des enfants: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePageBack(
      title: ('Modifier le Groupe'),
      footerIndex: 2,
      actions: [
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: () {},
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                labelText: 'Nom du Groupe',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Liste des Enfants',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue)),
            const Divider(),
            Expanded(
              child: _availableChildren.isEmpty
                  ? const Center(child: Text('Aucun enfant disponible'))
                  : ListView.builder(
                      itemCount: _availableChildren.length,
                      itemBuilder: (context, index) {
                        final child = _availableChildren[index];
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: CheckboxListTile(
                            title: Row(
                              children: [
                                child['imageUrl'] != null
                                    ? Image.network(
                                        child['imageUrl']!,
                                        height: 40,
                                        width: 40,
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(Icons.person,
                                        size: 40, color: Colors.grey),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          child['name'] ?? 'Nom non disponible',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      Text(child['parentName']),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            value: _selectedChildren.contains(child['id']),
                            activeColor: Colors.teal,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedChildren.add(child['id']);
                                } else {
                                  _selectedChildren.remove(child['id']);
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
