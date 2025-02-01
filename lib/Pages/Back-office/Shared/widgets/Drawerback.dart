// ignore_for_file: file_names

import 'package:flutter/material.dart';

class DrawerBApp extends StatelessWidget {
  final String? userName;
  final Function onSignOut;

  const DrawerBApp({Key? key, required this.userName, required this.onSignOut})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.teal,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushNamed('/profile'),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xff003542),
                      child: Text(
                        userName != null && userName!.isNotEmpty
                            ? userName![0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () =>
                              Navigator.of(context).pushNamed('/profile'),
                          child: Text(
                            userName ?? 'Unknown User',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    child: const Icon(Icons.logout, color: Colors.white),
                    onTap: () => onSignOut(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  _buildDrawerItem(
                    icon: Icons.supervised_user_circle,
                    title: 'Teams',
                    onTap: () => Navigator.of(context).pushNamed('/teams'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.sports_soccer,
                    title: 'Stadiums',
                    onTap: () => Navigator.of(context).pushNamed('/stadiums'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.account_circle,
                    title: 'Players',
                    onTap: () => Navigator.of(context).pushNamed('/players'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.calendar_today,
                    title: 'Training',
                    onTap: () => Navigator.of(context).pushNamed('/manageTraining'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings,
                    title: 'Settings',
                    onTap: () => Navigator.of(context).pushNamed('/settings'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xff003542)),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'FontR',
          fontSize: 18,
          color: Color.fromARGB(255, 6, 8, 8),
        ),
      ),
      onTap: onTap,
    );
  }
}
