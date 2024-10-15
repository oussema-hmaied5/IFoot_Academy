import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/presantation/Admin/Groupes/all_groupes_page.dart';
import 'package:ifoot_academy/presantation/Admin/Users/all_users_page.dart';
import 'package:ifoot_academy/presantation/Calender/training_page.dart';
import 'package:ifoot_academy/presantation/Drawer/Drawerback.dart';

import 'footer.dart';

class AdminMainPage extends StatefulWidget {
  const AdminMainPage({Key? key}) : super(key: key);

  @override
  _AdminMainPageState createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final double _width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Page Acceuil Admin',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.indigo[900],
      ),
      drawer: const DrawerBApp(),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(_width * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Statistiques de l\'Académie'),
              const SizedBox(height: 10),
              _buildStatisticsSection(),
              const SizedBox(height: 20),
              _buildSectionTitle('Notifications Importantes'),
              _buildNotificationsSection(),
              const SizedBox(height: 20),
              _buildSectionTitle('Actions Rapides'),
              _buildQuickActionsSection(),
              const SizedBox(height: 20),
              _buildSectionTitle('Activités Récentes'),
              _buildRecentActivitiesSection(),
              const SizedBox(height: 20),
              _buildSectionTitle('Calendrier des Entraînements'),
              _buildCalendarSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Footer(currentIndex: 0),
    );
  }

  Widget _buildStatisticsSection() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('stats').doc('academyStats').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
          return Text('Aucune donnée disponible');
        }

        var data = snapshot.data!.data() as Map<String, dynamic>?;

        var groupCount = data?['groupCount']?.toString() ?? '0';
        var newRegistrations = data?['newRegistrations']?.toString() ?? '0';

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(child: _buildStatCard('Groupes', groupCount, Icons.group)),
            Expanded(child: _buildStatCard('Inscriptions', newRegistrations, Icons.person_add)),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Colors.indigo[900]),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700]),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('notifications').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('Pas de notifications importantes.');
        }
        var notifications = snapshot.data!.docs;
        return Column(
          children: notifications.map((doc) {
            return _buildNotificationItem(doc['message']);
          }).toList(),
        );
      },
    );
  }

  Widget _buildNotificationItem(String message) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: const Icon(Icons.warning, color: Colors.red),
        title: Text(message, style: TextStyle(fontSize: 16, color: Colors.grey[800])),
      ),
    );
  }

 Widget _buildQuickActionsSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _buildNavigationButton('Ajouter un Groupe', () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ManageGroupsPage()));
            }),
          ),
          const SizedBox(width: 10),  // Add spacing between buttons
          Expanded(
            child: _buildNavigationButton('Programmer un Entraînement', () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const TrainingCalendarPage()));
            }),
          ),
        ],
      ),
      const SizedBox(height: 10),  // Add vertical spacing
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _buildNavigationButton('Consulter les nouvelles inscriptions', () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ManageUsersPage()));
            }),
          ),
        ],
      ),
    ],
  );
}
Widget _buildNavigationButton(String title, VoidCallback onPressed) {
  return ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      backgroundColor: Color.fromARGB(255, 234, 237, 239), // Adjust color as per preference
    ),
    child: Text(
      title,
      textAlign: TextAlign.center,  // Center the text for button
      style: const TextStyle(fontSize: 16),
    ),
  );
}
  Widget _buildQuickActionButton(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
    backgroundColor: Colors.indigo[900], // Use backgroundColor instead of primary
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      onPressed: onPressed,
    );
  }

  Widget _buildRecentActivitiesSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('activities').orderBy('timestamp', descending: true).limit(5).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('Aucune activité récente.');
        }
        var activities = snapshot.data!.docs;
        return Column(
          children: activities.map((doc) {
            return _buildRecentActivityItem(doc['description']);
          }).toList(),
        );
      },
    );
  }

  Widget _buildRecentActivityItem(String activity) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: const Icon(Icons.history, color: Colors.blue),
        title: Text(activity, style: TextStyle(fontSize: 16, color: Colors.grey[800])),
      ),
    );
  }

  Widget _buildCalendarSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('trainings').orderBy('date', descending: false).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('Pas d\'entraînements programmés.');
        }
        var trainings = snapshot.data!.docs;
        return Column(
          children: trainings.map((doc) {
            return _buildCalendarItem(doc['group'], doc['time']);
          }).toList(),
        );
      },
    );
  }

  Widget _buildCalendarItem(String group, String time) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: const Icon(Icons.calendar_today, color: Colors.green),
        title: Text('$group - $time', style: TextStyle(fontSize: 16, color: Colors.grey[800])),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.indigo,
        ),
      ),
    );
  }
}
