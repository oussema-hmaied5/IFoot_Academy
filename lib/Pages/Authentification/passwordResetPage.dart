import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PasswordResetPage extends StatefulWidget {
  @override
  _PasswordResetPageState createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _codeSent = false;
  bool _codeVerified = false;
  String? _message;

  Future<void> _sendResetCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final HttpsCallable sendResetCode =
          FirebaseFunctions.instance.httpsCallable('sendResetCode');
      await sendResetCode.call({'email': _emailController.text.trim()});

      setState(() {
        _codeSent = true;
        _message = "A reset code has been sent to your email. Enter it below.";
      });
    } catch (error) {
      setState(() {
        _message = "Error: Could not send reset code.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyCode() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final HttpsCallable verifyResetCode =
          FirebaseFunctions.instance.httpsCallable('verifyResetCode');
      final result = await verifyResetCode.call({
        'email': _emailController.text.trim(),
        'code': _codeController.text.trim()
      });

      if (result.data['success']) {
        setState(() {
          _codeVerified = true;
          _message = "Code verified! Enter a new password.";
        });
      } else {
        setState(() {
          _message = "Invalid code. Please try again.";
        });
      }
    } catch (error) {
      setState(() {
        _message = "Error verifying code.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: _emailController.text.trim(),
          password: _newPasswordController.text.trim(),
        );

        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(_newPasswordController.text.trim());

        setState(() {
          _message = "Password updated successfully!";
        });

        await Future.delayed(const Duration(seconds: 2));
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        _message = "User session expired. Please log in again.";
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _message = e.message ?? "Error updating password.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Please enter $label.';
          if (label == 'Email' && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
            return 'Enter a valid email.';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_reset, size: 80, color: Colors.blue),
                    const SizedBox(height: 20),
                    const Text(
                      'Reset Your Password',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    _buildTextField('Email', _emailController),

                    if (!_codeSent) ...[
                      const SizedBox(height: 20),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _sendResetCode,
                              child: const Text('Send Reset Code'),
                            ),
                    ],

                    if (_codeSent) ...[
                      const SizedBox(height: 20),
                      _buildTextField('Enter Verification Code', _codeController),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _verifyCode,
                        child: const Text('Verify Code'),
                      ),
                    ],

                    if (_codeVerified) ...[
                      const SizedBox(height: 20),
                      _buildTextField('New Password', _newPasswordController, obscureText: true),
                      const SizedBox(height: 10),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _resetPassword,
                              child: const Text('Update Password'),
                            ),
                    ],

                    if (_message != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _message!,
                        style: TextStyle(color: _message!.contains("success") ? Colors.green : Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
