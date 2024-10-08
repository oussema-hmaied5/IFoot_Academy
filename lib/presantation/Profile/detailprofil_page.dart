import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:ifoot_academy/models/app_state.dart';
import 'package:ifoot_academy/models/app_user.dart';
import 'package:redux/redux.dart';

class ProfileDetailsPage extends StatefulWidget {
  const ProfileDetailsPage({Key? key}) : super(key: key);

  @override
  _ProfileDetailsPageState createState() => _ProfileDetailsPageState();
}

class _ProfileDetailsPageState extends State<ProfileDetailsPage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;
  late String _selectedRole;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Store<AppState> store = StoreProvider.of<AppState>(context);
    final AppUser? user = store.state.user;

    if (user != null) {
      _nameController = TextEditingController(text: user.name);
      _emailController = TextEditingController(text: user.email);
      _mobileController = TextEditingController(text: user.mobile);
      _selectedRole = user.role;

      // Ensure _selectedRole is in the dropdown items
      if (!_roles().contains(_selectedRole)) {
        _selectedRole = _roles().first; // Default to the first role if not in the list
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Store<AppState> store = StoreProvider.of<AppState>(context);
    final AppUser? user = store.state.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile Details')),
        body: const Center(child: Text('No user data available')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(labelText: 'Mobile'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: _roles().map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(capitalize(value)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedRole = newValue!;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _saveProfile(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _roles() {
    return ['admin', 'coach', 'user', 'joueur', 'pending'];
  }

  void _saveProfile(BuildContext context) {
    final Store<AppState> store = StoreProvider.of<AppState>(context);
    final AppUser updatedUser = AppUser(
      id: store.state.user!.id,
      name: _nameController.text,
      email: _emailController.text,
      mobile: _mobileController.text,
      role: _selectedRole,
    );

    // Dispatch an action to update the user in the store
    store.dispatch(UpdateUserAction(updatedUser));

    // Optionally show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully')),
    );
  }
}

// Assuming you have an action like this defined in your Redux setup
class UpdateUserAction {
  final AppUser updatedUser;

  UpdateUserAction(this.updatedUser);
}

// Custom capitalize function
String capitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1).toLowerCase();
}
