// ignore_for_file: unnecessary_type_check, library_private_types_in_public_api, unused_field, sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:ifoot_academy/actions/index.dart';
import 'package:ifoot_academy/models/app_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _fullName = TextEditingController();
  final TextEditingController _phoneNumber = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _rePassword = TextEditingController();
  bool _isLoading = false;

  late OverlayEntry _overlayEntry;

void _onResult(AppAction action) {
  setState(() {
    _isLoading = false;
    if (action is! RegisterError) {
      _email.clear();
      _fullName.clear();
      _phoneNumber.clear();
      _password.clear();
      _rePassword.clear();
      _showSuccessDialog();
    } else if (action is RegisterError) {
      // Modify the error message to remove the word "Exception"
    }
  });
}

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Registration Successful'),
          content: const Text('Thank you for registering. Please wait for admin approval.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/');
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          Container(
            color: const Color.fromARGB(255, 101, 200, 240),
            height: height,
            width: width,
            child: const Padding(
              padding: EdgeInsets.only(top: 100, left: 30),
              child: Text(
                'Register.',
                style: TextStyle(color: Color(0xff003542), fontSize: 30, fontFamily: 'FontB'),
              ),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(top: height * 0.2),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xffffffff),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(50), topRight: Radius.circular(50)),
                ),
                height: height * 0.8,
                width: width,
                child: Form(
                  child: Column(
                    children: <Widget>[
                      Expanded(
                        child: Container(),
                        flex: 8,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: TextFormField(
                          style: const TextStyle(fontFamily: 'FontR'),
                          controller: _email,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (String value) {},
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an email address';
                            } else if (!value.contains('@') || !value.contains('.')) {
                              return 'Please enter a valid email address';
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
                          controller: _fullName,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                          ),
                          keyboardType: TextInputType.name,
                          onChanged: (String value) {},
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            } else if (value.length < 4 || value.length > 24) {
                              return 'Name must be between 4 and 24 characters';
                            }

                            if (value.contains(RegExp(r'[!-&]')) ||
                                value.contains(RegExp(r'[(-@]')) ||
                                value.contains(RegExp(r'[[-`]'))) {
                              return 'Name must contain only letters';
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
                          controller: _phoneNumber,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (String value) {},
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            } else if (
                                value.contains(RegExp(r'[!-/]')) ||
                                value.contains(RegExp(r'[:-~]'))) {
                              return 'Invalid phone number';
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
                          controller: _password,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                          ),
                          keyboardType: TextInputType.visiblePassword,
                          onChanged: (String value) {},
                          obscureText: true,
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            } else if (value.length < 6 || value.length > 24) {
                              return 'Password has to be between 6 and 24 characters';
                            }

                            if (!value.contains(RegExp(r'[!-`]'))) {
                              return 'Password must contain a capital letter, a number or a symbol';
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
                          controller: _rePassword,
                          decoration: const InputDecoration(
                            labelText: 're-Password',
                          ),
                          keyboardType: TextInputType.visiblePassword,
                          onChanged: (String value) {},
                          obscureText: true,
                          validator: (String? value) {
                            if (value != _password.text) {
                              return "Password doesn't match";
                            }

                            return null;
                          },
                        ),
                      ),
                      Expanded(
                        child: Container(),
                        flex: 2,
                      ),
                      Expanded(
                        child: Container(),
                        flex: 6,
                      ),
                      Builder(
                        builder: (BuildContext context) {
                          if (_isLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          return GestureDetector(
                            onTap: () async {
                              if (!Form.of(context).validate()) {
                                return;
                              }
                              setState(() => _isLoading = true);
                              StoreProvider.of<AppState>(context).dispatch(
                                RegisterStart(
                                  mobile: _phoneNumber.text,
                                  email: _email.text,
                                  name: _fullName.text,
                                  password: _password.text,
                                  role: 'pending', // Set role as pending
                                  result: _onResult,
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: const BorderRadius.all(Radius.circular(50)),
                              child: Container(
                                height: MediaQuery.of(context).size.height * 0.06,
                                width: MediaQuery.of(context).size.width * 0.8,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: <Color>[
                                      Color(0xff7eed9d),
                                      Color(0xdd7eed9d),
                                    ],
                                  ),
                                ),
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: MediaQuery.of(context).size.height * 0.008,
                                    ),
                                    child: const FittedBox(
                                      child: Text(
                                        'SIGN UP',
                                        style: TextStyle(
                                          fontFamily: 'FontB',
                                          color: Colors.white,
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
                            'Do you have an account? ',
                            style: TextStyle(
                              fontFamily: 'FontR',
                              color: Color(0xff003542),
                              fontSize: 18,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pushNamed('/');
                            },
                            child: const Text(
                              'Login',
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
                        flex: 6,
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
