// ignore_for_file: library_private_types_in_public_api, unused_field, unused_element

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:ifoot_academy/actions/index.dart';
import 'package:ifoot_academy/models/app_state.dart';

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

  void _onResult(AppAction action) {
    setState(() => _isLoading = false);
    if (action is LoginSuccessful) {
  final String route = action.user.role == 'admin' ? '/admin' : '/main';
      Navigator.of(context).pushReplacementNamed(route);
            } else if (action is LoginError) {
      setState(() {
        _errorMessage = action.error.toString();
      });
      _errorMessage = action.error.toString().replaceFirst('Exception: ', '');

    }
  }

  void _showErrorMessage(String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.3,
        left: 30,
        right: 30,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    overlayEntry.remove();
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double _height = MediaQuery.of(context).size.height;
    final double _width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          Container(
            color: Color.fromARGB(255, 64, 230, 233),
            height: _height,
            width: _width,
            child: Padding(
              padding: const EdgeInsets.only(top: 130, left: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const <Widget>[
                  Text(
                    'Hello.',
                    style: TextStyle(
                      color: Color(0xff003542),
                      fontSize: 40,
                      fontFamily: 'FontB',
                    ),
                  ),
                  Text(
                    'Log in to continue',
                    style: TextStyle(
                      color: Color(0xff003542),
                      fontSize: 20,
                      fontFamily: 'FontB',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 150.0, top: 60.0),
            child: RotationTransition(
              turns: AlwaysStoppedAnimation(35 / 360),
              child: Icon(
                CupertinoIcons.sportscourt,
                color: Color(0x10003542),
                size: 250, // Increased the size of the icon
              ),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(top: _height * 0.35),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xffffffff),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                ),
                height: _height * 0.65,
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
        ],
      ),
    );
  }
}
