import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _approveUser(String userId, String role) async {
    await _firestore.collection('users').doc(userId).update({'role': role});
    // Optionally send a notification to the user
    // await sendNotification(userEmail, 'Your account has been approved as $role.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Approval'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').where('role', isEqualTo: 'pending').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                title: Text(user['name']),
                subtitle: Text(user['email']),
                trailing: DropdownButton<String>(
                  value: user['role'],
                  onChanged: (String? newValue) {
                    if (newValue != null && newValue != 'pending') {
                      _approveUser(user.id, newValue);
                    }
                  },
                  items: <String>['JOUEUR', 'ENTRAINEUR', 'ADMIN', 'PARENT']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
