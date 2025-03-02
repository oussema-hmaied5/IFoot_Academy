// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../backend_template.dart';

class AddGroupPage extends StatefulWidget {
  const AddGroupPage({Key? key}) : super(key: key);

  @override
  _AddGroupPageState createState() => _AddGroupPageState();
}

class _AddGroupPageState extends State<AddGroupPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _groupNameController = TextEditingController();
  String _selectedGroupType = 'Loisirs';
  final List<String> _selectedChildren = [];
  List<Map<String, dynamic>> _availableChildren = [];

  @override
  void initState() {
    super.initState();
    _fetchAvailableChildren();
  }

  /// Fetch children with their parent names and ensure data is structured correctly
  Future<void> _fetchAvailableChildren() async {
    try {
      final QuerySnapshot childrenSnapshot = await _firestore.collection('children').get();

      final List<Map<String, dynamic>> childrenWithParentNames = [];

      for (var childDoc in childrenSnapshot.docs) {
        final Map<String, dynamic> childData = childDoc.data() as Map<String, dynamic>;
        final List<dynamic>? assignedGroups = childData['assignedGroups'] as List<dynamic>?;

        // Skip children already assigned to groups
        if (assignedGroups != null && assignedGroups.isNotEmpty) {
          continue;
        }

        final String? parentId = childData['parentId'];

        // Fetch parent's name from the `users` collection
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
        });
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

  /// Save the group and update the children assigned to it
  Future<void> _saveGroup() async {
    if (_groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un nom de groupe')),
      );
      return;
    }

    // Create a new group document
    final DocumentReference groupRef = _firestore.collection('groups').doc();

    // Save group data to Firestore
    await groupRef.set({
      'name': _groupNameController.text.trim(),
      'type': _selectedGroupType,
      'players': _selectedChildren,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update each child to include the group ID in their "assignedGroups"
    for (String childId in _selectedChildren) {
      await _firestore.collection('children').doc(childId).update({
        'assignedGroups': FieldValue.arrayUnion([groupRef.id]),
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Groupe enregistré avec succès')),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePageBack(
      title: 'Ajouter un Groupe',
      footerIndex: 2,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Type de groupe : ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.teal),
                ),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedGroupType,
                    items: ['Perfectionnement', 'Loisirs'].map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedGroupType = newValue!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                labelText: 'Nom du Groupe',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sélection des Enfants',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.teal),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _availableChildren.isEmpty
                  ? const Center(child: Text('Aucun enfant disponible'))
                  : ListView.builder(
                      itemCount: _availableChildren.length,
                      itemBuilder: (context, index) {
                        final child = _availableChildren[index];

                        final String childName = child['name'] ?? 'Nom non disponible';
                        final String parentName = child['parentName'];
                        final DateTime? childBirthDate = child['birthDate'] != null
                            ? (child['birthDate'] as Timestamp).toDate()
                            : null;
                        final String childBirthDateText = childBirthDate != null
                            ? '${childBirthDate.day}/${childBirthDate.month}/${childBirthDate.year}'
                            : 'Date de naissance non disponible';

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: CheckboxListTile(
                            title: Text(childName),
                            subtitle: Text('$parentName\nNé(e): $childBirthDateText'),
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
            ElevatedButton(
              onPressed: _saveGroup,
              child: const Text('Enregistrer le Groupe'),
            ),
          ],
        ),
      ),
    );
  }
}
