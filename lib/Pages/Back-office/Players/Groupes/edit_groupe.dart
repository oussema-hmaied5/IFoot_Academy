// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

  /// Fetch available children with parent names
  Future<void> _fetchAvailableChildren() async {
    try {
      final QuerySnapshot childrenSnapshot = await _firestore.collection('children').get();

      final List<Map<String, dynamic>> childrenWithParentNames = [];

      for (var childDoc in childrenSnapshot.docs) {
        final Map<String, dynamic> childData = childDoc.data() as Map<String, dynamic>;
        final List<dynamic>? assignedGroups = childData['assignedGroups'] as List<dynamic>?;

        // Include children already in the current group or without assigned groups
        if (assignedGroups == null ||
            assignedGroups.isEmpty ||
            assignedGroups.contains(widget.group.id)) {
          final String? parentId = childData['parentId'];
          String parentName = 'Parent inconnu';

          // Fetch parent's name from the `users` collection
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

  /// Save the updated group and synchronize child assignments
  Future<void> _saveGroup() async {
    final List<String> currentChildren = widget.group.players;

    // Determine children that were removed
    final List<String> removedChildren =
        currentChildren.where((id) => !_selectedChildren.contains(id)).toList();

    // Determine children that were added
    final List<String> addedChildren =
        _selectedChildren.where((id) => !currentChildren.contains(id)).toList();

    // Update removed children
    for (final childId in removedChildren) {
      await _firestore.collection('children').doc(childId).update({
        'assignedGroups': FieldValue.arrayRemove([widget.group.id]),
      });
    }

    // Update added children
    for (final childId in addedChildren) {
      await _firestore.collection('children').doc(childId).update({
        'assignedGroups': FieldValue.arrayUnion([widget.group.id]),
      });
    }

    // Update the group in Firestore
    await _firestore.collection('groups').doc(widget.group.id).update({
      'name': _groupNameController.text.trim(),
      'players': _selectedChildren,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Groupe mis à jour avec succès.')),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Modifier le Groupe'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
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
            const Text(
              'Modifier le Groupe:',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 20),
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
            const Text(
              'Sélectionner les Enfants:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 10),
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
          ],
        ),
      ),
    );
  }
}
