import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/Pages/Backend/Calender/training_page.dart';
import 'package:ifoot_academy/Pages/Backend/Users/all_users_page.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../Style/Backend_template.dart';
import '../Groupes/add_groupe_page.dart';
import '../Users/edituserpage.dart';

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

  Stream<List<QueryDocumentSnapshot>> _getRecentUsers() {
    DateTime threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));

    return FirebaseFirestore.instance
        .collection('users')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(threeDaysAgo))
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Future<int> _getRecentRegistrationsCount() async {
    DateTime threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(threeDaysAgo))
        .get();

    return snapshot.docs.length;
  }

  @override
 Widget build(BuildContext context) {
    return TemplatePageBack(
      title: 'Page Acceuil Admin',
      footerIndex: 0,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
              _buildSectionTitle('Nouveaux Utilisateurs (3 derniers jours)'),
              _buildRecentUsersSection(),
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
    );
  }

 Future<int> _getTotalGroupsCount() async {
  try {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('groups').get();
    return snapshot.docs.length;
  } catch (e) {
    print('Erreur lors de la récupération des groupes : $e');
    return 0;
  }
}

Widget _buildStatisticsSection() {
  return FutureBuilder<List<int>>(
    future: Future.wait([
      _getTotalGroupsCount(), // Nombre total de groupes
      _getRecentRegistrationsCount(), // Nombre d'inscriptions récentes
    ]),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return const Text('Données non disponibles');
      }

      int totalGroups = snapshot.data![0];
      int recentRegistrations = snapshot.data![1];

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(child: _buildStatCard('Groupes', '$totalGroups', Icons.group)),
          Expanded(
            child: _buildStatCard(
              'Inscriptions',
              '$recentRegistrations (3 jours)',
              Icons.person_add,
            ),
          ),
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

 Widget _buildRecentUsersSection() {
  return StreamBuilder<List<QueryDocumentSnapshot>>(
    stream: _getRecentUsers(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return const Text(
          'Aucun utilisateur inscrit au cours des trois derniers jours.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        );
      }

      final users = snapshot.data!;
      return Column(
        children: users.map((doc) {
          final user = doc.data() as Map<String, dynamic>;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.person, color: Colors.indigo),
              title: Text(user['name'] ?? 'Nom inconnu'),
              subtitle: Text(
                'Inscrit le : ${DateFormat('yyyy-MM-dd').format((user['createdAt'] as Timestamp).toDate())}',
              ),
              onTap: () {
                // Naviguer vers EditUserPage avec l'ID utilisateur
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EditUserPage(userId: doc.id),
                  ),
                );
              },
            ),
          );
        }).toList(),
      );
    },
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
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AddGroupPage()));
              }),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildNavigationButton('Programmer un Entraînement', () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const TrainingCalendarPage()));
              }),
            ),
          ],
        ),
        const SizedBox(height: 10),
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
        backgroundColor: const Color.fromARGB(255, 234, 237, 239),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16),
      ),
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
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      
      const SizedBox(height: 10),
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('training_sessions').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Text('Aucun entraînement programmé.');
          }

          final trainingSessions = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            try {
              // Validez et parsez les dates
              final DateTime startTime = DateTime.parse(data['startTime']);
              final DateTime endTime = DateTime.parse(data['endTime']);
              final String groupName = data['groupName'] ?? 'Nom du Groupe';

              return TrainingSession(groupName, startTime, endTime);
            } catch (e) {
              // Log et ignorer les données invalides
              print('Erreur lors du parsing des dates : $e');
              return null;
            }
          }).where((session) => session != null).cast<TrainingSession>().toList();

          return SfCalendar(
            view: CalendarView.week,
            dataSource: TrainingDataSource(trainingSessions),
            timeSlotViewSettings: const TimeSlotViewSettings(
              startHour: 8,
              endHour: 22,
              timeIntervalHeight: 50,
            ),
            todayHighlightColor: Colors.orangeAccent,
            appointmentTextStyle: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          );
        },
      ),
    ],
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
