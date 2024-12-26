import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For storing login state

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  bool _stayConnected = false; // Checkbox for stay connected

  @override
  void initState() {
    super.initState();
    _loadLoginState(); // Load saved login state when the app starts
  }

  // Load stored login data
  Future<void> _loadLoginState() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailController.text = prefs.getString('email') ?? '';
      _passwordController.text = prefs.getString('password') ?? '';
      _stayConnected = prefs.getBool('stayConnected') ?? false;
    });
  }

  // Save login data to shared preferences
  Future<void> _saveLoginState() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_stayConnected) {
      await prefs.setString('email', _emailController.text);
      await prefs.setString('password', _passwordController.text);
      await prefs.setBool('stayConnected', true);
    } else {
      await prefs.remove('email');
      await prefs.remove('password');
      await prefs.setBool('stayConnected', false);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Connecter l'utilisateur
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Récupérer le rôle de l'utilisateur depuis Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        final String role = userDoc.data()?['role'] ?? 'user';

        // Sauvegarder l'état de connexion si nécessaire
        await _saveLoginState();

        // Rediriger selon le rôle
        final route = role == 'admin' ? '/admin' : '/main';
     Navigator.of(context).pushReplacementNamed(route, arguments: userCredential.user!.uid);
      } else {
        setState(() {
          _errorMessage = "Utilisateur non trouvé dans la base de données.";
        });
      }
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
                padding: EdgeInsets.only(top: _height * 0.2),
                child: Image.asset(
                  'assets/Logo/logo.png',
                  width: _width * 0.4,
                  height: _height * 0.2,
                ),
              ),
            ),
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(top: _height * 0.4),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xffffffff),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50),
                    ),
                  ),
                  height: _height * 0.6,
                  width: _width,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        const SizedBox(height: 20),
                        const Text(
                          'Connectez-vous à iFoot',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildTextField('Email', _emailController, false),
                        const SizedBox(height: 20),
                        _buildTextField('Mot de passe', _passwordController, true),
                        const SizedBox(height: 10),
                        _buildRememberMeCheckbox(),
                        const SizedBox(height: 20),
                        _buildLoginButton(_height),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Pas encore de compte ? ",
                              style: TextStyle(fontSize: 16),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushNamed('/register');
                              },
                              child: const Text(
                                'S\'inscrire',
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
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isPassword) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: TextFormField(
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
      ),
    );
  }

  Widget _buildRememberMeCheckbox() {
    return CheckboxListTile(
      title: const Text('Rester connecté'),
      value: _stayConnected,
      onChanged: (bool? value) {
        setState(() {
          _stayConnected = value ?? false;
        });
      },
    );
  }

  Widget _buildLoginButton(double height) {
    return GestureDetector(
      onTap: _isLoading ? null : _login,
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
                      'Connexion',
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
