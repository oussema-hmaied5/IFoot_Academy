// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;

  // Getter for current user
  User? get currentUser => _currentUser;

  AuthProvider() {
    _initializeUser();
  }

  // Initialize user and listen to auth state changes
  void _initializeUser() {
    _firebaseAuth.authStateChanges().listen((User? user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  // Login method
  Future<String?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _currentUser = userCredential.user;
      notifyListeners();
      return null; // No error
    } on FirebaseAuthException catch (e) {
      return _getFriendlyErrorMessage(e.code); // Return a friendly error message
    } catch (e) {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  // Register method with additional information
  Future<String?> register(String email, String password, String name) async {
    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _currentUser = userCredential.user;

      // Save additional user info to Firestore
      await _firestore.collection('users').doc(_currentUser!.uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
      return null; // No error
    } on FirebaseAuthException catch (e) {
      return _getFriendlyErrorMessage(e.code); // Return a friendly error message
    } catch (e) {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  // Logout method
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  // Map FirebaseAuthException codes to friendly messages
  String _getFriendlyErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered. Please login instead.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'The password is too weak. Please choose a stronger password.';
      default:
        return 'An unknown error occurred. Please try again.';
    }
  }
}
