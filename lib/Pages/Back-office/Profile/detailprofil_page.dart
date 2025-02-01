// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../Style/Frontend_template.dart';


class ProfileDetailsPage extends StatefulWidget {
  final String userId;

  const ProfileDetailsPage({Key? key, required this.userId}) : super(key: key);

  @override
  _ProfileDetailsPageState createState() => _ProfileDetailsPageState();
}

class _ProfileDetailsPageState extends State<ProfileDetailsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController(); // For Coach
  final TextEditingController _childNameController = TextEditingController(); // For Joueur
  DateTime? _selectedDateOfBirth;
  String? _selectedRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
   
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _mobileController.text = data['mobile'] ?? '';
          _selectedRole = data['role'] ?? 'joueur';
          _selectedDateOfBirth = data['dateOfBirth'] != null
              ? (data['dateOfBirth'] as Timestamp).toDate()
              : null;

          if (_selectedRole == 'coach') {
            _specializationController.text = data['specialization'] ?? '';
          } else if (_selectedRole == 'joueur') {
            _childNameController.text = data['childName'] ?? '';
          }

          _isLoading = false;
        });
      }
    
  }

  Future<void> _saveProfile() async {
    try {
      setState(() => _isLoading = true);

      Map<String, dynamic> updatedData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'role': _selectedRole,
        'dateOfBirth': _selectedDateOfBirth != null
            ? Timestamp.fromDate(_selectedDateOfBirth!)
            : null,
      };

      if (_selectedRole == 'coach') {
        updatedData['specialization'] = _specializationController.text.trim();
      } else if (_selectedRole == 'joueur') {
        updatedData['childName'] = _childNameController.text.trim();
      }

      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update(updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDateOfBirth = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return FrontendTemplate(
      title: 'Profile Details',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a name'
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value == null || !value.contains('@') ? 'Invalid email' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(labelText: 'Mobile'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Date of Birth'),
                subtitle: Text(
                  _selectedDateOfBirth != null
                      ? DateFormat('yyyy-MM-dd').format(_selectedDateOfBirth!)
                      : 'No date selected',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ),
          
                TextFormField(
                  controller: _childNameController,
                  decoration: const InputDecoration(labelText: 'Child Name'),
                ),
              
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
