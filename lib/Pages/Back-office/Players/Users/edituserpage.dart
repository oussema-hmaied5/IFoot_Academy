// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../Backend_template.dart';

class EditUserPage extends StatefulWidget {
  final String userId;

  const EditUserPage({Key? key, required this.userId}) : super(key: key);

  @override
  _EditUserPageState createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _emailController;
  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  DateTime? _selectedDateOfBirth;
  List<Map<String, dynamic>> _children = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _nameController = TextEditingController();
    _mobileController = TextEditingController();
    _fetchUserData();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userDoc =
          await _firestore.collection('users').doc(widget.userId).get();

      if (userDoc.data() == null) {
        throw Exception('User not found');
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      final childrenSnapshot = await _firestore
          .collection('children')
          .where('parentId', isEqualTo: widget.userId)
          .get();

      setState(() {
        _emailController.text = userData['email'] ?? '';
        _nameController.text = userData['name'] ?? '';
        _mobileController.text = userData['phone'] ?? '';
        _selectedDateOfBirth = userData['dateOfBirth'] != null
            ? (userData['dateOfBirth'] as Timestamp).toDate()
            : null;

        _children = childrenSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? '',
            'birthDate': data['birthDate'] != null
                ? (data['birthDate'] as Timestamp).toDate()
                : null,
          };
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des données: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _firestore.collection('users').doc(widget.userId).update({
          'email': _emailController.text,
          'name': _nameController.text,
          'mobile': _mobileController.text,
          'dateOfBirth': _selectedDateOfBirth != null
              ? Timestamp.fromDate(_selectedDateOfBirth!)
              : null,
        });

        for (var child in _children) {
          if (child['id'] == null) {
            await _firestore.collection('children').add({
              'name': child['name'],
              'birthDate': child['birthDate'] != null
                  ? Timestamp.fromDate(child['birthDate'])
                  : null,
              'parentId': widget.userId,
            });
          } else {
            await _firestore.collection('children').doc(child['id']).update({
              'name': child['name'],
              'birthDate': child['birthDate'] != null
                  ? Timestamp.fromDate(child['birthDate'])
                  : null,
            });
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur et enfants enregistrés.')),
        );
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _addChild() {
    setState(() {
      _children.add({'name': '', 'birthDate': null});
    });
  }

  Future<void> _removeChild(int index) async {
    try {
      final child = _children[index];
      final childId = child['id'];

      if (childId != null) {
        await _firestore.collection('children').doc(childId).delete();
      }

      setState(() {
        _children.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enfant supprimé avec succès.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePageBack(
      title: ('Modifier l\'utilisateur'),
      footerIndex: 1, // Set the correct footer index for the "Users" page
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations Utilisateur',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue),
                    ),
                    const Divider(),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email, color: Colors.blue),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Email requis' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom',
                        prefixIcon: Icon(Icons.person, color: Colors.blue),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Nom requis' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _mobileController,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone',
                        prefixIcon: Icon(Icons.phone, color: Colors.blue),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Liste des Enfants',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue),
                    ),
                    const Divider(),
                    ..._children.asMap().entries.map((entry) {
                      final index = entry.key;
                      final child = entry.value;

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                initialValue: child['name'],
                                decoration: InputDecoration(
                                  labelText: 'Nom de l\'enfant ${index + 1}',
                                  prefixIcon: const Icon(
                                    Icons.child_care,
                                    color: Colors.blue,
                                  ),
                                ),
                                onChanged: (value) {
                                  child['name'] = value;
                                },
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        child['birthDate'] ?? DateTime.now(),
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime.now(),
                                  );
                                  if (pickedDate != null) {
                                    setState(() {
                                      child['birthDate'] = pickedDate;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        child['birthDate'] == null
                                            ? 'Sélectionner une date de naissance'
                                            : DateFormat('dd/MM/yyyy')
                                                .format(child['birthDate']),
                                      ),
                                      const Icon(Icons.calendar_today,
                                          color: Colors.blue),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _removeChild(index),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    ElevatedButton.icon(
                      onPressed: _addChild,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Ajouter un enfant'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _saveUser,
                        icon: const Icon(Icons.save,
                            color: Color.fromARGB(255, 237, 55, 55)),
                        label: const Text('Enregistrer'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
