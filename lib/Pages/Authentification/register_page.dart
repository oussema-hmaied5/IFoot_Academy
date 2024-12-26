import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _childNameController = TextEditingController();
  DateTime? _childBirthDate;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isCoach = true;
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  String? _uploadedImageUrl;

  final String _defaultImageUrl = 'https://example.com/default-player-image.png'; // URL de l'image par défaut

  Future<void> _pickImage(bool isCoach) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create a new user in Firebase Auth
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Upload the image to Firebase Storage or use default image
      if (_imageFile != null) {
  // Upload the user-selected image
  final String fileName = '${userCredential.user!.uid}_${DateTime.now().millisecondsSinceEpoch}';
  final Reference storageRef = FirebaseStorage.instance.ref().child('user_images/$fileName');
  final UploadTask uploadTask = storageRef.putFile(File(_imageFile!.path));

  final TaskSnapshot taskSnapshot = await uploadTask;
  _uploadedImageUrl = await taskSnapshot.ref.getDownloadURL();
} else {
  // If no image is provided, use a default URL
  _uploadedImageUrl = _defaultImageUrl;
}


      // Build user data for Firestore
      Map<String, dynamic> userData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'role': _isCoach ? 'coach' : 'joueur',
        'imageUrl': _uploadedImageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (!_isCoach) {
        userData.addAll({
          'childName': _childNameController.text.trim(),
          'childBirthDate': _childBirthDate != null
              ? Timestamp.fromDate(_childBirthDate!)
              : null,
        });
      }

      // Add user data to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userData);

      // Navigate to the login page
      Navigator.of(context).pushReplacementNamed('/');
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? "Une erreur inconnue est survenue.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double _height = MediaQuery.of(context).size.height;
    final double _width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: _height * 0.1),
                child: Image.asset(
                  'assets/Logo/logo.png',
                  width: _width * 0.4,
                  height: _height * 0.2,
                ),
              ),
            ),
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(top: _height * 0.3),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xffffffff),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50),
                    ),
                  ),
                  width: _width,
                  child: Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: <Widget>[
                          const Text(
                            'Créez votre compte iFoot',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildTextField('Nom', _nameController, false),
                          const SizedBox(height: 20),
                          _buildTextField('Mobile', _mobileController, false),
                          const SizedBox(height: 20),
                          _buildTextField('Email', _emailController, false),
                          const SizedBox(height: 20),
                          _buildTextField('Mot de passe', _passwordController, true),
                          const SizedBox(height: 20),
                          _buildRoleCheckbox(),
                          const SizedBox(height: 10),
                          if (_isCoach) _buildImagePicker(isCoach: true),
                          if (!_isCoach) _buildChildFields(),
                          const SizedBox(height: 20), // Ensure proper spacing before the button
                          _buildRegisterButton(_height),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Déjà inscrit ? ",
                                style: TextStyle(fontSize: 16),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pushNamed('/');
                                },
                                child: const Text(
                                  'Se connecter',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildFields() {
    return Column(
      children: [
        _buildTextField('Nom du fils', _childNameController, false),
        const SizedBox(height: 20),
        _buildImagePicker(isCoach: false),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (pickedDate != null) {
              setState(() {
                _childBirthDate = pickedDate;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _childBirthDate == null
                      ? 'Date de naissance du fils'
                      : DateFormat('dd/MM/yyyy').format(_childBirthDate!),
                  style: const TextStyle(fontSize: 16),
                ),
                const Icon(Icons.calendar_today, color: Colors.blue),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker({required bool isCoach}) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _pickImage(isCoach),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: _imageFile != null
                ? FileImage(File(_imageFile!.path))
                : NetworkImage(_defaultImageUrl) as ImageProvider,
            child: _imageFile == null
                ? const Icon(Icons.camera_alt, color: Colors.blue, size: 40)
                : null,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          isCoach
              ? 'Téléchargez une photo (Coach)'
              : 'Téléchargez une photo (Joueur)',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isPassword) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.blue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue.shade400),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez entrer $label';
        }
        return null;
      },
    );
  }

  Widget _buildRoleCheckbox() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Coach'),
        Switch(
          value: !_isCoach,
          onChanged: (value) {
            setState(() {
              _isCoach = !value;
            });
          },
        ),
        const Text('Joueur'),
      ],
    );
  }

  Widget _buildRegisterButton(double height) {
    return GestureDetector(
      onTap: _isLoading ? null : _register,
      child: FractionallySizedBox(
        widthFactor: 0.8,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Container(
            height: height * 0.06,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF64E6E9),
                  Color(0xFF64E6E9),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'S\'inscrire',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
