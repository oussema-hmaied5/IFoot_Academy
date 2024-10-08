// ignore_for_file: use_key_in_widget_constructors, file_names

import 'package:flutter/material.dart';

class Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.blueGrey[900], // Change the background color
      selectedItemColor: Colors.white, // Color of the selected item
      unselectedItemColor: Colors.white70, // Color of the unselected items
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Users & Coaches',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.group),
          label: 'Groups',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.event),
          label: 'Events',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.article),
          label: 'Regulations',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Training',
        ),
      ],
      onTap: (int index) {
        // Add your navigation logic here
        switch (index) {
          case 0:
            // Navigate to Users & Coaches page
            Navigator.pushNamed(context, '/manageUsers');
            break;
          case 1:
            // Navigate to Groups page
            Navigator.pushNamed(context, '/manageGroups');
            break;
          case 2:
            // Navigate to Events page
            Navigator.pushNamed(context, '/manageEvents');
            break;
          case 3:
            // Navigate to Regulations page
            Navigator.pushNamed(context, '/manageRegulations');
            break;
          case 4:
            // Navigate to Training page
            Navigator.pushNamed(context, '/manageTraining');
            break;
        }
      },
    );
  }
}
