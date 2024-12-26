import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? _currentUser;

  // Getter pour accéder à l'utilisateur actuel
  User? get currentUser => _currentUser;

  // Méthode pour initialiser l'utilisateur actuel
  Future<void> initializeUser() async {
    _currentUser = _firebaseAuth.currentUser; // Récupère l'utilisateur connecté (s'il existe)
    notifyListeners(); // Notifie les widgets écoutant les changements d'état
  }

  // Méthode pour se connecter
  Future<void> login(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _currentUser = userCredential.user; // Définit l'utilisateur connecté
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to login: $e');
    }
  }

  // Méthode pour s'inscrire
  Future<void> register(String email, String password, String name) async {
    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Ajoutez des champs personnalisés comme le `name` à votre base de données Firestore
      _currentUser = userCredential.user;
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to register: $e');
    }
  }

  // Méthode pour se déconnecter
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    _currentUser = null; // Réinitialise l'utilisateur
    notifyListeners();
  }
}
