// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
class BulkAddUsers extends StatefulWidget {
  @override
  _BulkAddUsersState createState() => _BulkAddUsersState();
}

class _BulkAddUsersState extends State<BulkAddUsers> {
  @override
  void initState() {
    super.initState();
    _bulkAddUsers();  // Automatically triggers the bulk add on app start
  }

  Future<void> _bulkAddUsers() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    List<Map<String, dynamic>> users = [
    {'email': 'user1@example.com', 'name': ' One', 'mobile': '1111111111', 'role': 'joueur'},
    {'email': 'user2@example.com', 'name': ' Two', 'mobile': '2222222222', 'role': 'joueur'},
    {'email': 'user3@example.com', 'name': ' Three', 'mobile': '3333333333', 'role': 'coach'},
    {'email': 'user4@example.com', 'name': ' Four', 'mobile': '4444444444', 'role': 'joueur'},
    {'email': 'user1@example.com', 'name': ' kamel', 'mobile': '1111111111', 'role': 'joueur'},
    {'email': 'user2@example.com', 'name': ' lased', 'mobile': '2222222222', 'role': 'joueur'},
    {'email': 'user3@example.com', 'name': ' morad', 'mobile': '3333333333', 'role': 'coach'},
    {'email': 'user4@example.com', 'name': ' melek', 'mobile': '4444444444', 'role': 'joueur'},
    {'email': 'user1@example.com', 'name': ' omar', 'mobile': '1111111111', 'role': 'joueur'},
    {'email': 'user2@example.com', 'name': ' mounir', 'mobile': '2222222222', 'role': 'joueur'},
    {'email': 'user3@example.com', 'name': ' moslem', 'mobile': '3333333333', 'role': 'coach'},
    {'email': 'user4@example.com', 'name': ' tarak', 'mobile': '4444444444', 'role': 'joueur'},

     // Add more users as needed
    ];

    for (var user in users) {
      await firestore.collection('users').add(user);
    }

    print("Users added successfully");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Adding users...')),
    );
  }
}
