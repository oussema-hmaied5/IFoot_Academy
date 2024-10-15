import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ifoot_academy/models/app_user.dart';
import 'package:redux_epics/redux_epics.dart';
import 'package:rxdart/rxdart.dart';

import '../actions/auth_actions.dart';
import '../models/app_state.dart';

class AuthApi {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<AppUser?> login(String emailOrMobile, String password) async {
    try {
      String email = emailOrMobile;

      // Check if the input is a mobile number
      if (_isMobileNumber(emailOrMobile)) {
        final querySnapshot = await _firestore.collection('users')
            .where('mobile', isEqualTo: emailOrMobile).get();

        if (querySnapshot.docs.isEmpty) {
          throw Exception('No user found with this mobile number');
        }

        final userData = querySnapshot.docs.first.data();
        email = userData['email'] as String;
      }

      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userDoc = await _firestore.collection('users').doc(userCredential.user?.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          return AppUser.fromJson(data);
        } else {
          throw Exception('User document data is null');
        }
      } else {
        throw Exception('User document does not exist');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<String> register(String mobile, String email, String name, String password, String role) async {
    try {
      final emailQuerySnapshot = await _firestore.collection('users')
          .where('email', isEqualTo: email).get();
      if (emailQuerySnapshot.docs.isNotEmpty) {
        throw Exception('Email already exists');
      }

      final phoneQuerySnapshot = await _firestore.collection('users')
          .where('mobile', isEqualTo: mobile).get();
      if (phoneQuerySnapshot.docs.isNotEmpty) {
        throw Exception('Phone number already exists');
      }

      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'name': name,
        'mobile': mobile,
        'role': role,
        'dateOfBirth': '', // Include the dateOfBirth if applicable
      });

      return 'Registration successful';
    } catch (e) {
      throw Exception('Registration failed: $e');
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

class AppEpics {
  const AppEpics({required AuthApi authApi}) : _authApi = authApi;

  final AuthApi _authApi;

  Epic<AppState> get epics {
    return combineEpics<AppState>(<Epic<AppState>>[
      TypedEpic<AppState, LoginStart>(_login),
      TypedEpic<AppState, RegisterStart>(_register),
    ]);
  }

  Stream<AppAction> _login(Stream<LoginStart> actions, EpicStore<AppState> store) {
    return actions.flatMap((LoginStart action) => Stream<void>.value(null)
        .asyncMap((_) => _authApi.login(action.email, action.password))
        .map<AppAction>((AppUser? user) {
          if (user == null) {
            return LoginError(Exception('User not found'));
          } else {
            return LoginSuccessful(user);
          }
        })
        .onErrorReturnWith((Object error, StackTrace stackTrace) => LoginError(error))
        .doOnData(action.result));
  }

  Stream<AppAction> _register(Stream<RegisterStart> actions, EpicStore<AppState> store) {
    return actions.flatMap((RegisterStart action) => Stream<void>.value(null)
        .asyncMap((_) => _authApi.register(action.mobile, action.email, action.name, action.password, action.role))
        .map<AppAction>((String output) => RegisterSuccessful(output))
        .onErrorReturnWith((Object error, StackTrace stackTrace) => RegisterError(error))
        .doOnData(action.result));
  }
}
