// ignore_for_file: library_private_types_in_public_api, empty_catches, use_build_context_synchronously, prefer_collection_literals

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/presantation/Admin/Menu/footer.dart'; // Import your Footer

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
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(widget.userId)
          .get();
      final userData = userDoc.data() as Map<String, dynamic>;

      setState(() {
        _emailController = TextEditingController(text: userData['email'] ?? '');
        _nameController = TextEditingController(text: userData['name'] ?? '');
        _mobileController = TextEditingController(text: userData['mobile'] ?? '');
        _selectedRole = userData['role'] ?? 'pending';
      });
    } catch (e) {
    }
  }

  Future<void> _saveUser() async {
    if (_formKey.currentState!.validate()) {
      await _firestore.collection('users').doc(widget.userId).update({
        'email': _emailController.text,
        'name': _nameController.text,
        'mobile': _mobileController.text,
        'role': _selectedRole,
      });
      Navigator.of(context).pop(); // Go back to the previous page after saving
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit User'),
      ),
      body: Column(
        children: [
          Expanded( // Ensure content is scrollable
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an email';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _mobileController,
                        decoration: const InputDecoration(labelText: 'Mobile'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a mobile number';
                          }
                          if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(value)) {
                            return 'Please enter a valid mobile number';
                          }
                          return null;
                        },
                      ),
                      DropdownButtonFormField<String>(
                        value: _selectedRole ?? 'default_value',
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedRole = newValue!;
                          });
                        },
                        items: <String>['admin', 'coach', 'user', 'joueur', 'pending']
                            .toSet()
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: const InputDecoration(labelText: 'Role'),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _saveUser,
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Footer(), // Add Footer here at the bottom
        ],
      ),
    );
  }
}
