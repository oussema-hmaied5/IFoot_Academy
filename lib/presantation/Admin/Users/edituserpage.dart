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
  DateTime? _selectedDateOfBirth;
  String? _selectedRole;

  @override
  void initState() {
    super.initState();

    // Initialize all controllers with empty values to avoid late initialization error.
    _emailController = TextEditingController();
    _nameController = TextEditingController();
    _mobileController = TextEditingController();

    _fetchUserData();
  }

  @override
  void dispose() {
    // Dispose of controllers to avoid memory leaks
    _emailController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      final DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(widget.userId).get();
      final userData = userDoc.data() as Map<String, dynamic>;

      setState(() {
        _emailController.text = userData['email'] ?? '';
        _nameController.text = userData['name'] ?? '';
        _mobileController.text = userData['mobile'] ?? '';
        _selectedRole = userData['role'] ?? 'joueur';
        _selectedDateOfBirth = userData['dateOfBirth'] != null
            ? (userData['dateOfBirth'] as Timestamp).toDate()
            : null; // Load date of birth if available
      });
    } catch (e) {
      // Handle error if something goes wrong
      print('Error fetching user data: $e');
    }
  }

  Future<void> _saveUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _firestore.collection('users').doc(widget.userId).update({
          'email': _emailController.text,
          'name': _nameController.text,
          'mobile': _mobileController.text,
          'dateOfBirth': _selectedDateOfBirth != null
              ? Timestamp.fromDate(_selectedDateOfBirth!)
              : null, // Save date of birth
          'role': _selectedRole,
        });
        Navigator.of(context).pop(); // Go back after saving
      } catch (e) {
        print('Error saving user data: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving user: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier l\'utilisateur'),
      ),
      body: SingleChildScrollView(
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
                    return 'Veuillez entrer un email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Veuillez entrer un email valide';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(labelText: 'Téléphone'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un numéro de téléphone';
                  }
                  if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(value)) {
                    return 'Veuillez entrer un numéro valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Date de naissance'),
                subtitle: Text(_selectedDateOfBirth != null
                    ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
                    : 'Sélectionner une date de naissance'),
                onTap: _selectDateOfBirth, // Date picker
              ),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedRole = newValue!;
                  });
                },
                items: <String>['admin', 'coach', 'joueur']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                decoration: const InputDecoration(labelText: 'Rôle'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveUser,
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Footer(currentIndex: 1), // Pass the index for "Groups"
    );
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }
}
