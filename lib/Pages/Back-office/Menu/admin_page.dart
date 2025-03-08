// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:ifoot_academy/Pages/Back-office/backend_template.dart';

import '../../Style/animation/switching_splash.dart';

class AdminMainPage extends StatefulWidget {
  const AdminMainPage({Key? key}) : super(key: key);

  @override
  _AdminMainPageState createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  late String currentView;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    currentView =
        (args != null && args['isCoach'] == true) ? 'coach' : 'player';
  }

  // ignore: unused_element
  void _switchView(String targetView) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SwitchingSplash(switchingTo: targetView),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePageBack(
      title: currentView == 'player'
          ? 'Gestion des Joueurs'
          : 'Gestion des Coachs',
      actions: [
        IconButton(
          icon: Icon(currentView == 'player' ? Icons.person : Icons.sports),
          onPressed: () {
            setState(() {
              currentView = currentView == 'player' ? 'coach' : 'player';
            });
          },
          tooltip: currentView == 'player'
              ? 'Basculer vers Coach'
              : 'Basculer vers Joueur',
        ),
      ],
      body: currentView == 'player'
          ? _buildPlayerContent()
          : _buildCoachContent(),
      footerIndex: 0,
      isCoach: currentView == 'coach',
    );
  }

  Widget _buildPlayerContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gestion des Joueurs',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent),
          ),
          const SizedBox(height: 20),
          _buildSectionCard(
            title: 'Liste des Joueurs',
            description: 'Consultez et gérez les informations des joueurs.',
            icon: Icons.list,
            onTap: () => Navigator.pushNamed(context, '/manageUsers'),
          ),
          const SizedBox(height: 10),
          _buildSectionCard(
            title: 'Groupes des Joueurs',
            description:
                'Organisez les joueurs par groupes et gérez leurs affectations.',
            icon: Icons.group,
            onTap: () => Navigator.pushNamed(context, '/manageGroups'),
          ),
          const SizedBox(height: 10),
          _buildSectionCard(
            title: 'Evaluation des Joueurs',
            description:
                'Consultez et gérez les évaluations des joueurs par les coachs.',
            icon: Icons.list,
            onTap: () => Navigator.pushNamed(context, '/evaluations'),
          ),
          const SizedBox(height: 10),
          _buildSectionCard(
            title: 'Calendrier des Entraînements',
            description:
                'Planifiez et consultez les entraînements pour les joueurs.',
            icon: Icons.calendar_today,
            onTap: () => Navigator.pushNamed(context, '/manageTraining'),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gestion des Coachs',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent),
          ),
          const SizedBox(height: 20),
          _buildSectionCard(
            title: 'Liste des Coachs',
            description: 'Consultez et gérez les informations des coachs.',
            icon: Icons.person,
            onTap: () => Navigator.pushNamed(context, '/AllCoaches'),
          ),
          const SizedBox(height: 10),
          _buildSectionCard(
            title: 'Plannings des Coachs',
            description: 'Planifiez les séances et matches pour les coachs.',
            icon: Icons.schedule,
            onTap: () => Navigator.pushNamed(context, '/PlanningOverview'),
          ),
          const SizedBox(height: 10),
          _buildSectionCard(
            title: 'Statistiques des Coachs',
            description:
                'Analysez les performances et les contributions des coachs.',
            icon: Icons.bar_chart,
            onTap: () => Navigator.pushNamed(context, '/coachStats'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Colors.blue),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
