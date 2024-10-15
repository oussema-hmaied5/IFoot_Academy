import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:ifoot_academy/actions/auth_actions.dart';
import 'package:ifoot_academy/models/app_state.dart';
import 'package:intl/intl.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); 
  final TextEditingController _email = TextEditingController();
  final TextEditingController _fullName = TextEditingController(); 
  final TextEditingController _phoneNumber = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _rePassword = TextEditingController();
  bool _isLoading = false;

  bool _isCoach = false;
  bool _isJoueur = false;
  DateTime? _selectedDate; 

 void _onResult(AppAction action) {
  setState(() {
    _isLoading = false;
    if (action is! RegisterError) {
      _email.clear();
      _fullName.clear();
      _phoneNumber.clear();
      _password.clear();
      _rePassword.clear();
      _selectedDate = null;

      // Call the function to increment the registration count
      _incrementRegistrationCount();

      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  });
}

void _incrementRegistrationCount() async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Increment the 'inscriptionCount' field in Firestore
  firestore.collection('stats').doc('academyStats').update({
    'inscriptionCount': FieldValue.increment(1),
  });
}


  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          // Background image
          Container(
            height: height,
            width: width,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/regis.jpg'), // Your background image
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: height * 0.2,
            child: Container(
              width: width,
              height: height * 0.8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85), 
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey, 
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        // Email field
                        TextFormField(
                          controller: _email,
                          decoration: const InputDecoration(
                            labelText: 'Adresse email',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer une adresse email';
                            } else if (!value.contains('@') || !value.contains('.')) {
                              return 'Veuillez entrer une adresse email valide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Phone Number field
                        TextFormField(
                          controller: _phoneNumber,
                          decoration: const InputDecoration(
                            labelText: 'Numéro de téléphone',
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre numéro de téléphone';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        const Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'Vous êtes :',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // Checkboxes for "Coach" and "Joueur"
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: CheckboxListTile(
                                title: const Text('Coach'),
                                value: _isCoach,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _isCoach = value ?? false;
                                    _isJoueur = !_isCoach;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: CheckboxListTile(
                                title: const Text('Joueur'),
                                value: _isJoueur,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _isJoueur = value ?? false;
                                    _isCoach = !_isJoueur;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),

                        if (_isCoach) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _fullName,
                            decoration: const InputDecoration(
                              labelText: 'Nom du Coach',
                            ),
                            validator: (String? value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer le nom du coach';
                              }
                              return null;
                            },
                          ),
                        ],

                        if (_isJoueur) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _fullName,
                            decoration: const InputDecoration(
                              labelText: 'Nom du Joueur',
                            ),
                            validator: (String? value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer le nom du joueur';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            readOnly: true,
                            onTap: () => _selectDate(context),
                            decoration: InputDecoration(
                              labelText: 'Date de naissance',
                              hintText: _selectedDate != null
                                  ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                                  : 'Choisir une date',
                              suffixIcon: const Icon(Icons.calendar_today),
                            ),
                            validator: (String? value) {
                              if (_selectedDate == null) {
                                return 'Veuillez sélectionner la date de naissance';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Password fields
                        TextFormField(
                          controller: _password,
                          decoration: const InputDecoration(
                            labelText: 'Mot de passe',
                          ),
                          obscureText: true,
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer un mot de passe';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _rePassword,
                          decoration: const InputDecoration(
                            labelText: 'Confirmez le mot de passe',
                          ),
                          obscureText: true,
                          validator: (String? value) {
                            if (value != _password.text) {
                              return "Les mots de passe ne correspondent pas";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        if (_isLoading)
                          const Center(
                            child: CircularProgressIndicator(),
                          )
                        else
                          ElevatedButton(
                            onPressed: () async {
                              if (!_formKey.currentState!.validate()) return;
                              setState(() => _isLoading = true);
                              StoreProvider.of<AppState>(context).dispatch(
                                RegisterStart(
                                  mobile: _phoneNumber.text,
                                  email: _email.text,
                                  name: _fullName.text,
                                  dateOfBirth: _isJoueur && _selectedDate != null
                                      ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                                      : '',
                                  password: _password.text,
                                  role: _isCoach ? 'coach' : 'joueur',
                                  result: _onResult,
                                ),
                              );
                            },
                            child: const Text('S\'inscrire'),
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
    );
  }
}
