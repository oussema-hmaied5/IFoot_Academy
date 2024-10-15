import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:ifoot_academy/actions/auth_actions.dart';
import 'package:ifoot_academy/models/app_state.dart';
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

  void _onResult(AppAction action) {
    setState(() => _isLoading = false);
    
    if (action is LoginSuccessful) {
      _saveLoginState(); // Save the login state when login is successful
      final String route = action.user.role == 'admin' ? '/admin' : '/main';
      Navigator.of(context).pushReplacementNamed(route);
    } else if (action is LoginError) {
      setState(() {
        _errorMessage = "Vous devez vérifier votre email ou votre mot de passe!";
      });

      // Show the SnackBar with error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _errorMessage ?? 'An error occurred!',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3), // Adjust the duration
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double _height = MediaQuery.of(context).size.height;
    final double _width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          // Background image without opacity
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: Image.asset(
              'assets/images/login.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),

          // Apply opacity to the whole form and text
          Opacity(
            opacity: 0.9, // Change this value to adjust the opacity level
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(top: _height * 0.50), // Adjusted top padding
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xffffffff),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50),
                    ),
                  ),
                  height: _height * 0.50, // Adjusted height to make it fit well
                  width: _width,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        Expanded(
                          child: Container(),
                          flex: 10,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: TextFormField(
                            style: const TextStyle(fontFamily: 'FontR'),
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            cursorColor: Colors.white,
                            validator: (String? value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              return null;
                            },
                          ),
                        ),
                        Expanded(
                          child: Container(),
                          flex: 2,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: TextFormField(
                            style: const TextStyle(fontFamily: 'FontR'),
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                            ),
                            keyboardType: TextInputType.visiblePassword,
                            obscureText: true,
                            cursorColor: Colors.white,
                            validator: (String? value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              } else if (value.length < 6 || value.length > 24) {
                                return 'Password has to be between 6 and 24 characters';
                              }
                              return null;
                            },
                          ),
                        ),
                        Expanded(
                          child: Container(),
                          flex: 2,
                        ),

                        // Stay Connected Checkbox
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: CheckboxListTile(
                            title: const Text('Stay Connected'),
                            value: _stayConnected,
                            onChanged: (bool? value) {
                              setState(() {
                                _stayConnected = value ?? false;
                              });
                            },
                          ),
                        ),
                        
                        Expanded(
                          child: Container(),
                          flex: 6,
                        ),
                        Builder(
                          builder: (BuildContext context) {
                            if (_isLoading) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xff7eed9d),
                                ),
                              );
                            }
                            return GestureDetector(
                              onTap: () {
                                if (!_formKey.currentState!.validate()) {
                                  return;
                                }
                                setState(() => _isLoading = true);
                                StoreProvider.of<AppState>(context).dispatch(
                                  LoginStart(
                                    email: _emailController.text,
                                    password: _passwordController.text,
                                    result: _onResult,
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(50),
                                ),
                                child: Container(
                                  height: MediaQuery.of(context).size.height * 0.06,
                                  width: MediaQuery.of(context).size.width * 0.8,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: <Color>[
                                        Color.fromARGB(255, 64, 230, 233),
                                        Color.fromARGB(255, 64, 230, 233),
                                      ],
                                    ),
                                  ),
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: MediaQuery.of(context).size.height *
                                            0.008,
                                      ),
                                      child: const FittedBox(
                                        child: Text(
                                          'LOGIN',
                                          style: TextStyle(
                                            fontFamily: 'FontB',
                                            color: Color(0xffffffff),
                                            fontSize: 28,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        Expanded(
                          child: Container(),
                          flex: 2,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                fontFamily: 'FontR',
                                color: Color(0xff003542),
                                fontSize: 18,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushNamed('/register');
                              },
                              child: const Text(
                                'Register',
                                style: TextStyle(
                                  fontFamily: 'FontB',
                                  color: Color(0xff7eed9d),
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: Container(),
                          flex: 10,
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
