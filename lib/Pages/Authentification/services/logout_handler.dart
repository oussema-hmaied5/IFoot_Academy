import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogoutHandler {
  /// Déconnexion de l'utilisateur
  static Future<void> logout(BuildContext context) async {
    try {
      // 1. Supprimer les données stockées localement
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Supprime toutes les données stockées
      
      // 2. Déconnecter de Firebase
      await FirebaseAuth.instance.signOut();

      // 3. Rediriger vers l'écran de connexion
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login', // Route de l'écran de connexion
        (Route<dynamic> route) => false, // Supprime toutes les routes précédentes
      );

      // Message de confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous avez été déconnecté.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Gestion des erreurs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la déconnexion : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
