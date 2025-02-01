import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final PhoneNumber _phoneNumber =
      PhoneNumber(isoCode: 'TN'); // Tunisie par défaut
  String? _validatedPhoneNumber; // Numéro validé après validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final List<Map<String, dynamic>> _children = [{'name': '', 'birthDate': null}]; // Liste des enfants avec un enfant par défaut

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save(); // Sauvegarder les valeurs validées

    setState(() {
      _isLoading = true;
    });

    try {
      // Création de l'utilisateur dans Firebase Auth
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final String userId = userCredential.user!.uid;

      // Ajout des données utilisateur dans Firestore
      final Map<String, dynamic> userData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _validatedPhoneNumber,
        'role': 'parent',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set(userData);

      // Ajout des enfants à la collection "children"
      await _registerChildren(userId);

      // Redirection vers la page de connexion
      Navigator.of(context).pushReplacementNamed('/login');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Une erreur est survenue.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _registerChildren(String parentId) async {
    for (var i = 0; i < _children.length; i++) {
      var child = _children[i];
      if (child['birthDate'] != null) {
        // Utilisation d'un Timestamp uniquement pour la date sans l'heure
        final DateTime onlyDate = DateTime(
          child['birthDate'].year,
          child['birthDate'].month,
          child['birthDate'].day,
        );

        await FirebaseFirestore.instance.collection('children').add({
          'name': "Enfant N${i + 1} - ${child['name']}",
          'birthDate': Timestamp.fromDate(onlyDate),
          'parentId': parentId,
          'assignedGroups':
              [], // Liste des groupes auxquels l'enfant appartient
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Image.asset(
                    'assets/Logo/logo.png',
                    width: 120,
                    height: 120,
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'Créez votre compte iFoot',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField('Nom et Prénom ( Parent )', _nameController, icon: Icons.person),
                const SizedBox(height: 20),
                _buildPhoneNumberField(), // Champ de numéro de téléphone
                const SizedBox(height: 20),
                _buildTextField('Email', _emailController, icon: Icons.email),
                const SizedBox(height: 20),
                _buildTextField('Mot de passe', _passwordController,
                    obscureText: true, icon: Icons.lock),
                const SizedBox(height: 20),
                _buildChildFields(),
                const SizedBox(height: 30),
                _buildRegisterButton(),
                const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                           
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushNamed('/login');
                              },
                              child: const Text(
                                'Vous avez déjà un compte ?',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneNumberField() {
    return InternationalPhoneNumberInput(
      onInputChanged: (PhoneNumber number) {},
      onInputValidated: (bool isValid) {},
      onSaved: (PhoneNumber number) {
        _validatedPhoneNumber = number.phoneNumber;
      },
      selectorConfig: const SelectorConfig(
        selectorType: PhoneInputSelectorType.DROPDOWN,
      ),
      ignoreBlank: false,
      initialValue: _phoneNumber,
      textFieldController: TextEditingController(),
      inputDecoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Numéro de téléphone',
        prefixIcon: Icon(Icons.phone),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool obscureText = false, IconData? icon}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: icon != null ? Icon(icon) : null,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez entrer $label';
        }
        return null;
      },
    );
  }

  Widget _buildChildFields() {
    return Column(
      children: [
        ..._children.asMap().entries.map((entry) {
          final index = entry.key;
          final child = entry.value;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 10),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    initialValue: child['name'],
                    decoration: InputDecoration(
                      labelText: 'Nom et prénom de l\'enfant N${index + 1}',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.child_care),
                    ),
                    onChanged: (value) {
                      setState(() {
                        child['name'] = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: child['birthDate'] ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (BuildContext context, Widget? child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Colors.blue, // Couleur principale
                                onPrimary: Colors.white, // Couleur du texte
                                onSurface: Colors.black, // Couleur de la surface
                              ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.blue, // Couleur des boutons
                                ),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (pickedDate != null) {
                        setState(() {
                          child['birthDate'] = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                          ); // Enregistrer uniquement la date
                        });
                      }
                    },
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            child['birthDate'] == null
                                ? 'Date de naissance'
                                : DateFormat('dd/MM/yyyy')
                                    .format(child['birthDate']),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Icon(Icons.calendar_today, color: Colors.blue),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _children.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          ),
          onPressed: () {
            setState(() {
              _children.add({'name': '', 'birthDate': null});
            });
          },
          child: const Text('Autre un enfant'),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _register,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFF64E6E9), Color(0xFF64E6E9)],
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
    );
  }
}