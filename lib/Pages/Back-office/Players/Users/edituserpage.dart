// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
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
    setState(() => _isLoading = true);
    try {
      final userDoc =
          await _firestore.collection('users').doc(widget.userId).get();
      if (!userDoc.exists) throw Exception('User not found');

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
            'imageUrl': data['imageUrl'],
          };
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des données: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadChildImage(int index) async {
    final pickedFile =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    File file = File(pickedFile.path);
    String fileName =
        'children/${widget.userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

    try {
      UploadTask uploadTask = _storage.ref(fileName).putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String imageUrl = await snapshot.ref.getDownloadURL();

      setState(() => _children[index]['imageUrl'] = imageUrl);

      if (_children[index]['id'] != null) {
        await _firestore
            .collection('children')
            .doc(_children[index]['id'])
            .update({'imageUrl': imageUrl});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du téléversement: $e')),
      );
    }
  }

  Future<void> _selectChildBirthDate(int index) async {
    DateTime initialDate = _children[index]['birthDate'] ?? DateTime.now();
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _children[index]['birthDate'] = pickedDate;
      });
    }
  }

  void _addChild() {
    setState(() {
      _children.add({'name': '', 'birthDate': null, 'imageUrl': null});
    });
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePageBack(
      title: 'Modifier l\'utilisateur',
      footerIndex: 1,
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
                      'Informations utilisateur :',
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
                    const Text('Liste des Enfants :',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    const Divider(),
                    ..._children.asMap().entries.map((entry) {
                      final index = entry.key;
                      final child = entry.value;

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => _uploadChildImage(index),
                                child: child['imageUrl'] != null
                                    ? Image.network(child['imageUrl']!,
                                        height: 80,
                                        width: 80,
                                        fit: BoxFit.cover)
                                    : const Icon(Icons.camera_alt,
                                        size: 50, color: Colors.blue),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextFormField(
                                      initialValue: child['name'],
                                      decoration: InputDecoration(
                                          labelText:
                                              'Nom de l\'enfant ${index + 1}'),
                                      onChanged: (value) =>
                                          child['name'] = value,
                                    ),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () => _selectChildBirthDate(index),
                                      child: Text(
                                        child['birthDate'] != null
                                            ? 'Date de naissance: ${DateFormat('dd/MM/yyyy').format(child['birthDate'])}'
                                            : 'Date de naissance: Non spécifiée',
                                        style: const TextStyle(
                                            color: Colors.blue,
                                            decoration:
                                                TextDecoration.underline),
                                      ),
                                    ),
                                  ],
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
                          backgroundColor: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
