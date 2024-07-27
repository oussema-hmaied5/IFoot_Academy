import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ifoot_academy/models/app_user.dart';

class AuthApi {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<AppUser?> login(String emailOrMobile, String password) async {
    try {
      String email = emailOrMobile;

      // Check if the input is a mobile number
      if (_isMobileNumber(emailOrMobile)) {
        // Fetch email from Firestore using mobile number
        final querySnapshot = await _firestore.collection('users')
            .where('mobile', isEqualTo: emailOrMobile).get();

        if (querySnapshot.docs.isEmpty) {
          throw Exception('No user found with this mobile number');
        }

        final userData = querySnapshot.docs.first.data();
        email = userData['email'] as String;
      }

      // Perform sign in using email and password
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Fetch user data from Firestore
      final userDoc = await _firestore.collection('users').doc(userCredential.user?.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          print("User data fetched successfully");
          return AppUser.fromJson(data);
        } else {
          throw Exception('User document data is null');
        }
      } else {
        throw Exception('User document does not exist');
      }
    } catch (e) {
      print('Login failed: $e');
      throw Exception('Login failed: $e');
    }
  }

  Future<String> register(String mobile, String email, String name, String password, String role) async {
    try {
      // Check for existing email
      final emailQuerySnapshot = await _firestore.collection('users')
          .where('email', isEqualTo: email).get();
      if (emailQuerySnapshot.docs.isNotEmpty) {
        throw Exception('Email already exists');
      }

      // Check for existing phone number
      final phoneQuerySnapshot = await _firestore.collection('users')
          .where('mobile', isEqualTo: mobile).get();
      if (phoneQuerySnapshot.docs.isNotEmpty) {
        throw Exception('Phone number already exists');
      }

      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user data in Firestore with 'pending' role
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'mobile': mobile,
        'email': email,
        'name': name,
        'role': role,
      });

      return 'Registration successful';
    } catch (e) {
      print('Registration failed: $e');
      throw Exception('Registration failed: $e');
    }
  }

  Future<String> approveUser(String userId, String role) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': role,
      });
      return 'User approved successfully';
    } catch (e) {
      print('User approval failed: $e');
      throw Exception('User approval failed: $e');
    }
  }

   Future<AppUser> getUserById(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      return AppUser.fromJson(userDoc.data()!);
    } else {
      throw Exception('User not found');
    }
  }

  bool _isMobileNumber(String input) {
    final RegExp mobileRegex = RegExp(r'^[0-9]{10}$');
    return mobileRegex.hasMatch(input);
  }
}
